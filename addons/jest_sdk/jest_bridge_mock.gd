class_name JestBridgeMock
extends RefCounted

## Set to true to enable console logging of all operations.
var verbose: bool = false

## Configure mock player state.
var player_id: String = "mock-player-id"
var is_registered: bool = true

## Mock player data as a computed JSON string.
var player_data: String:
	get: return '{"playerId":"%s","registered":%s}' % [player_id, str(is_registered).to_lower()]

## Configure mock purchase behavior.
var mock_purchase_succeeds: bool = true
## Configure mock products JSON.
var mock_products_json: String = '[{"sku":"gems_100","name":"100 Gems","description":"Get 100 gems","price":99.0},{"sku":"gems_500","name":"500 Gems","description":"Get 500 gems","price":499.0}]'

var _player_values: Dictionary = {}
var _notifications: Array[Dictionary] = []
var _entry_payload: String = "{}"


func _log(message: String) -> void:
	if verbose:
		print("[JestSDK Mock] %s" % message)


func get_player_value(key: String) -> String:
	var val: String = _player_values.get(key, "")
	_log("get(%s) -> %s" % [key, val])
	return val


func set_player_value(key: String, value: String) -> void:
	_log("set(%s, %s)" % [key, value])
	_player_values[key] = value


func delete_player_value(key: String) -> void:
	_log("delete(%s)" % key)
	_player_values.erase(key)


func get_entry_payload() -> String:
	return _entry_payload


func login(payload: String) -> void:
	is_registered = true
	_log("login (registered = true)")


func open_legal_page(page: String) -> void:
	_log("open_legal_page(%s)" % page)


func schedule_notification_v2(options: String) -> void:
	_log("schedule_notification: %s" % options)
	var parsed = JSON.parse_string(options)
	if parsed is Dictionary:
		_notifications.append(parsed)


func unschedule_notification_v2(key: String) -> void:
	_log("unschedule_notification(%s)" % key)


func get_products() -> String:
	_log("get_products")
	return mock_products_json


func get_purchase_response() -> String:
	_log("begin_purchase")
	if mock_purchase_succeeds:
		return '{"result":"success","purchase":{"purchaseToken":"mock_token","productSku":"gems_100","credits":99,"createdAt":1761729039,"completedAt":null},"purchaseSigned":"mock_jws"}'
	else:
		return '{"result":"cancel"}'


func get_incomplete_purchase_response() -> String:
	_log("get_incomplete_purchases")
	return '{"hasMore":false,"purchasesSigned":"mock_jws","purchases":[]}'


func get_purchase_complete_response() -> String:
	_log("complete_purchase")
	return '{"result":"success"}'


func open_referral_dialog(options_json: String) -> void:
	_log("open_referral_dialog: %s" % options_json)


func get_list_referrals_response() -> String:
	_log("list_referrals")
	return '{"referrals":[],"referralsSigned":""}'


func redirect_to_game(options_json: String) -> void:
	_log("redirect_to_game: %s" % options_json)


func redirect_to_explore_page() -> void:
	_log("redirect_to_explore_page")


func get_player_signed_response() -> String:
	_log("get_player_signed")
	return '{"player":{"playerId":"%s","registered":%s},"playerSigned":"mock_signed_data"}' % [player_id, str(is_registered).to_lower()]
