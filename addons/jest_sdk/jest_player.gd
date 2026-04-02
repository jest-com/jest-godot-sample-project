class_name JestPlayer
extends RefCounted

var _bridge: JestBridge
var _on_data_changed: Callable

# Cache for frequently-accessed properties
var _cached_id: String = ""
var _cached_is_registered: bool = false
var _cache_valid: bool = false


func _init(bridge: JestBridge, on_data_changed: Callable = Callable()) -> void:
	_bridge = bridge
	_on_data_changed = on_data_changed


## Gets the unique identifier for the current player.
var id: String:
	get:
		if not _cache_valid:
			_refresh_cache()
		return _cached_id

## Gets whether the current player is registered in the system.
var is_registered: bool:
	get:
		if not _cache_valid:
			_refresh_cache()
		return _cached_is_registered


## Retrieves a string value associated with the specified key.
func get_value(key: String) -> String:
	if key.strip_edges().is_empty():
		push_error("[JestSDK] Key cannot be empty")
		return ""
	return _bridge.get_player_value(key)


## Retrieves all player data as a Dictionary.
func get_all() -> Dictionary:
	return JestUtils.parse_json_dict(_bridge.get_all_player_data())


## Retrieves all player data as a JSON string.
func get_player_data() -> String:
	return _bridge.get_player_data()


## Retrieves a value and parses it as int. Returns 0 if not found.
func get_int(key: String) -> int:
	var val := get_value(key)
	return int(val) if not val.is_empty() else 0


## Retrieves a value and parses it as float. Returns 0.0 if not found.
func get_float(key: String) -> float:
	var val := get_value(key)
	return float(val) if not val.is_empty() else 0.0


## Retrieves a value and parses it as bool. Returns false if not found.
func get_bool(key: String) -> bool:
	return get_value(key).to_lower() == "true"


## Retrieves a JSON value and parses it into a Variant (Dictionary or Array).
func get_json(key: String) -> Variant:
	return JestUtils.parse_json(get_value(key))


## Returns true if the key exists and has a non-empty value.
func has_value(key: String) -> bool:
	if key.strip_edges().is_empty():
		push_error("[JestSDK] Key cannot be empty")
		return false
	return not _bridge.get_player_value(key).is_empty()


## Retrieves a string value, returning the provided default if the key doesn't exist or is empty.
func get_value_or_default(key: String, default: String = "") -> String:
	if key.strip_edges().is_empty():
		push_error("[JestSDK] Key cannot be empty")
		return default
	var val := _bridge.get_player_value(key)
	return val if not val.is_empty() else default


## Sets a string value for the specified key.
func set_value(key: String, value: String) -> void:
	if key.strip_edges().is_empty():
		push_error("[JestSDK] Key cannot be empty")
		return
	_bridge.set_player_value(key, value)
	_emit_changed(key, value)


## Sets an int value for the specified key.
func set_int(key: String, value: int) -> void:
	set_value(key, str(value))


## Sets a float value for the specified key.
func set_float(key: String, value: float) -> void:
	set_value(key, str(value))


## Sets a bool value for the specified key.
func set_bool(key: String, value: bool) -> void:
	set_value(key, str(value).to_lower())


## Sets a JSON-serializable value (Dictionary or Array) for the specified key.
func set_json(key: String, value: Variant) -> void:
	set_value(key, JSON.stringify(value))


## Sets multiple values at once (merge into existing data).
func set_bulk(data: Dictionary) -> void:
	if data.is_empty():
		return
	_bridge.set_player_data_bulk(JSON.stringify(data))
	for key in data:
		_emit_changed(key, str(data[key]))


## Deletes the value associated with the specified key.
func delete_value(key: String) -> void:
	if key.strip_edges().is_empty():
		push_error("[JestSDK] Key cannot be empty")
		return
	_bridge.delete_player_value(key)
	_emit_changed(key, "")


## Ensures all pending player data updates are synchronized to the server.
## Must be awaited: var result = await JestSDK.player.flush()
func flush() -> JestResult:
	var cb_result: Dictionary = await _bridge.flush()
	if cb_result.get("timed_out", false):
		return JestResult.failure("timeout")
	if not cb_result.get("error", "").is_empty():
		return JestResult.failure(cb_result["error"])
	invalidate_cache()
	return JestResult.success()


## Gets signed player data for server-side verification.
## Must be awaited: var signed = await JestSDK.player.get_signed()
func get_signed() -> JestSignedPlayer:
	var cb_result: Dictionary = await _bridge.get_player_signed()
	if cb_result.get("timed_out", false):
		return JestSignedPlayer.make_error("timeout")
	if not cb_result.get("error", "").is_empty():
		return JestSignedPlayer.make_error(cb_result["error"])
	var d := JestUtils.parse_json_dict(cb_result["result"])
	if d.is_empty():
		return JestSignedPlayer.make_error("empty_response")
	return JestSignedPlayer.from_dict(d)


## Invalidates the cached id and is_registered properties.
func invalidate_cache() -> void:
	_cache_valid = false


func _refresh_cache() -> void:
	_cached_id = _bridge.get_player_id()
	_cached_is_registered = _bridge.get_is_registered()
	_cache_valid = true


func _emit_changed(key: String, value: String) -> void:
	if _on_data_changed.is_valid():
		_on_data_changed.call(key, value)
