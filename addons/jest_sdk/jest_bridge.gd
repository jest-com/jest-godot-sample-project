class_name JestBridge
extends RefCounted

## Timeout constants matching the JS SDK
const TIMEOUT_DEFAULT := 10_000    # 10 seconds
const TIMEOUT_INIT := 60_000       # 60 seconds
const TIMEOUT_PURCHASE := 300_000  # 5 minutes (user interaction)
const TIMEOUT_NONE := -1           # No timeout (flush, share dialog)

var _is_web: bool = false
var _mock: JestBridgeMock
var _js_initialized: bool = false
var _mock_initialized: bool = false
var _verbose: bool = false
var _scene_tree: SceneTree

## Whether the SDK has been initialized successfully.
var is_initialized: bool:
	get: return _js_initialized if _is_web else _mock_initialized

var _pending_callbacks: Dictionary = {}
var _next_callback_id: int = 0

# Live JS registration-overlay handles keyed by conversationId.
var _overlay_handles: Dictionary = {}

# Cached references to JS objects
var _sdk: JavaScriptObject         # window.JestSDK
var _sdk_data: JavaScriptObject    # window.JestSDK.data
var _sdk_payments: JavaScriptObject
var _sdk_notifications: JavaScriptObject
var _sdk_referrals: JavaScriptObject
var _sdk_internal: JavaScriptObject
var _json: JavaScriptObject        # window.JSON
var _data_helper: JavaScriptObject # Wrapper to avoid set/get name collision with Object

# Prevent GC of active callbacks (keyed by callback ID, cleaned up after use)
var _active_callbacks: Dictionary = {}

signal _callback_received(callback_id: String)


func _init() -> void:
	_is_web = OS.has_feature("web")
	if not _is_web:
		_mock = JestBridgeMock.new()


## Called from the singleton's _ready() to provide SceneTree for timers.
func setup(scene_tree: SceneTree) -> void:
	_scene_tree = scene_tree


# --- Initialization ---

## Returns true on success, false on failure.
func init_sdk(options: Dictionary = {}) -> bool:
	if not _is_web:
		_mock_initialized = true
		_mock.verbose = _verbose
		if _verbose:
			print("[JestSDK] Mock mode - SDK initialized")
		return true

	_json = JavaScriptBridge.get_interface("JSON")
	_sdk = JavaScriptBridge.get_interface("JestSDK")

	if _sdk == null:
		push_error("[JestSDK] window.JestSDK not found. Make sure jestsdk.js is loaded via the HTML shell.")
		return false

	var init_opts = JavaScriptBridge.create_object("Object")
	for key in options:
		init_opts[key] = options[key]
	var init_promise = _sdk.init(init_opts)
	var cb_id := _generate_callback_id()
	_setup_promise_callback(init_promise, cb_id)
	var cb_result := await _wait_for_callback(cb_id, TIMEOUT_INIT)

	if cb_result["timed_out"]:
		push_error("[JestSDK] SDK initialization timed out")
		return false
	if not cb_result["error"].is_empty():
		push_error("[JestSDK] SDK initialization failed: %s" % cb_result["error"])
		return false

	# Cache sub-module references
	_sdk_data = _sdk.data
	_sdk_payments = _sdk.payments
	_sdk_notifications = _sdk.notifications
	_sdk_referrals = _sdk.referrals
	_sdk_internal = _sdk.internal

	# Get the data helper bridge injected by the export plugin.
	# Direct calls like _sdk_data.set(k,v) invoke GDScript's Object.set() instead of JS data.set().
	_data_helper = JavaScriptBridge.get_interface("__jestDataHelper")
	if _data_helper == null:
		push_error("[JestSDK] __jestDataHelper not found. Make sure the export plugin injected jestsdk.js.")

	_js_initialized = true
	if _verbose:
		print("[JestSDK] SDK initialized successfully")
	return true


# --- Sync bridge methods ---

func get_entry_payload() -> String:
	if not _is_web:
		return _mock.get_entry_payload()
	var result = _json.stringify(_sdk.getEntryPayload())
	return result if result is String else "{}"


func get_player_id() -> String:
	if not _is_web:
		return _mock.player_id
	var player = _sdk.getPlayer()
	if player == null:
		return ""
	var pid = player.playerId
	return pid if pid is String else ""


func get_player_data() -> String:
	if not _is_web:
		return _mock.player_data
	var result = _json.stringify(_sdk.getPlayer())
	return result if result is String else "{}"


func get_is_registered() -> bool:
	if not _is_web:
		return _mock.is_registered
	var player = _sdk.getPlayer()
	if player == null:
		return false
	return bool(player.registered)


func get_player_username() -> String:
	if not _is_web:
		return _mock.username
	var player = _sdk.getPlayer()
	if player == null:
		return ""
	var val = player.username
	return val if val is String else ""


func get_player_avatar_url() -> String:
	if not _is_web:
		return _mock.avatar_url
	var player = _sdk.getPlayer()
	if player == null:
		return ""
	var val = player.avatarUrl
	return val if val is String else ""


func get_player_value(key: String) -> String:
	if not _is_web:
		return _mock.get_player_value(key)
	var val = _data_helper.getValue(key)
	if val == null:
		return ""
	return str(val)


func set_player_value(key: String, value: String) -> void:
	if not _is_web:
		_mock.set_player_value(key, value)
		return
	_data_helper.setValue(key, value)


func delete_player_value(key: String) -> void:
	if not _is_web:
		_mock.delete_player_value(key)
		return
	_data_helper.deleteValue(key)


func get_all_player_data() -> String:
	if not _is_web:
		return JSON.stringify(_mock._player_values)
	var result = _json.stringify(_data_helper.getAll())
	return result if result is String else "{}"


func set_player_data_bulk(data_json: String) -> void:
	if not _is_web:
		var d = JSON.parse_string(data_json)
		if d is Dictionary:
			for key in d:
				_mock._player_values[key] = str(d[key])
		return
	var d = JSON.parse_string(data_json)
	if d is Dictionary:
		for key in d:
			_data_helper.setValue(key, d[key])


func login(payload: String) -> void:
	if not _is_web:
		_mock.login(payload)
		return
	if payload.is_empty():
		_sdk.login()
	else:
		var parsed = _parse_json_to_js(payload)
		if parsed == null:
			return
		var opts = JavaScriptBridge.create_object("Object")
		opts.entryPayload = parsed
		_sdk.login(opts)


func open_legal_page(page: String) -> void:
	if not _is_web:
		_mock.open_legal_page(page)
		return
	match page:
		"privacy":
			_sdk_internal.openPrivacyPolicy()
		"terms":
			_sdk_internal.openTermsOfService()
		"copyright":
			_sdk_internal.openCopyright()


func debug_register() -> void:
	if not OS.is_debug_build():
		push_warning("[JestSDK] debug_register() is only available in debug builds")
		return
	if not _is_web:
		_mock.login("")
		if _verbose:
			print("[JestSDK] Debug register triggered (mock)")
		return
	var window = JavaScriptBridge.get_interface("window")
	var math = JavaScriptBridge.get_interface("Math")
	var random_num = int(math.floor(math.random() * 10000000.0))
	var phone_number := "+1555%07d" % random_num
	var msg = JavaScriptBridge.create_object("Object")
	msg.type = "debug-register"
	msg.phoneNumber = phone_number
	window.parent.postMessage(msg, "*")


func redirect_to_game(options_json: String) -> void:
	if not _is_web:
		_mock.redirect_to_game(options_json)
		return
	var opts = _parse_json_to_js(options_json)
	if opts != null:
		_sdk_internal.redirectToGame(opts)


func redirect_to_explore_page() -> void:
	if not _is_web:
		_mock.redirect_to_explore_page()
		return
	_sdk_internal.redirectToExplorePage()


func schedule_notification_v2(options_json: String) -> void:
	if not _is_web:
		_mock.schedule_notification_v2(options_json)
		return
	var opts = _parse_json_to_js(options_json)
	if opts == null:
		return
	# Convert scheduledAt string to Date object if present
	if opts.scheduledAt:
		opts.scheduledAt = JavaScriptBridge.create_object("Date", opts.scheduledAt)
	_sdk_notifications.scheduleNotification(opts)


func unschedule_notification_v2(identifier: String) -> void:
	if not _is_web:
		_mock.unschedule_notification_v2(identifier)
		return
	var opts = JavaScriptBridge.create_object("Object")
	opts.identifier = identifier
	_sdk_notifications.unscheduleNotification(opts)


func set_loading_progress(progress: float) -> void:
	var clamped := int(clampf(roundf(progress), 0.0, 100.0))
	if not _is_web:
		if _verbose:
			print("[JestSDK] SetLoadingProgress: %d%%" % clamped)
		return
	_sdk.setLoadingProgress(clamped)


func send_reserved_login_message(reservation_json: String) -> void:
	if not _is_web:
		if _verbose:
			print("[JestSDK] Send reserved login message (mock)")
		return
	var opts = _parse_json_to_js(reservation_json)
	if opts != null:
		_sdk_internal.sendReservedLoginMessage(opts)


func capture_onboarding_event(event: String, properties_json: String) -> void:
	if not _is_web:
		if _verbose:
			print("[JestSDK] CaptureOnboardingEvent: %s" % event)
		return
	if properties_json.is_empty():
		_sdk_internal.captureOnboardingEvent(event)
	else:
		var props = _parse_json_to_js(properties_json)
		if props != null:
			_sdk_internal.captureOnboardingEvent(event, props)


# --- Async bridge methods ---
# All return Dictionary: {result: String, error: String, timed_out: bool}

func flush() -> Dictionary:
	if not _is_web:
		return {"result": "", "error": "", "timed_out": false}
	var promise = _data_helper.flush()
	var cb_id := _generate_callback_id()
	_setup_promise_callback(promise, cb_id)
	return await _wait_for_callback(cb_id, TIMEOUT_NONE)


func get_products() -> Dictionary:
	if not _is_web:
		return {"result": _mock.get_products(), "error": "", "timed_out": false}
	var promise = _sdk_payments.getProducts()
	var cb_id := _generate_callback_id()
	_setup_promise_callback(promise, cb_id, true)
	return await _wait_for_callback(cb_id, TIMEOUT_DEFAULT)


func begin_purchase(sku: String) -> Dictionary:
	if not _is_web:
		return {"result": _mock.get_purchase_response(), "error": "", "timed_out": false}
	var opts = JavaScriptBridge.create_object("Object")
	opts.productSku = sku
	var promise = _sdk_payments.beginPurchase(opts)
	var cb_id := _generate_callback_id()
	_setup_promise_callback(promise, cb_id, true)
	return await _wait_for_callback(cb_id, TIMEOUT_PURCHASE)


func complete_purchase(purchase_token: String) -> Dictionary:
	if not _is_web:
		return {"result": _mock.get_purchase_complete_response(), "error": "", "timed_out": false}
	var opts = JavaScriptBridge.create_object("Object")
	opts.purchaseToken = purchase_token
	var promise = _sdk_payments.completePurchase(opts)
	var cb_id := _generate_callback_id()
	_setup_promise_callback(promise, cb_id, true)
	return await _wait_for_callback(cb_id, TIMEOUT_DEFAULT)


func get_incomplete_purchases() -> Dictionary:
	if not _is_web:
		return {"result": _mock.get_incomplete_purchase_response(), "error": "", "timed_out": false}
	var promise = _sdk_payments.getIncompletePurchases()
	var cb_id := _generate_callback_id()
	_setup_promise_callback(promise, cb_id, true)
	return await _wait_for_callback(cb_id, TIMEOUT_DEFAULT)


func open_referral_dialog(options_json: String) -> Dictionary:
	if not _is_web:
		_mock.open_referral_dialog(options_json)
		return {"result": '{"canceled":false}', "error": "", "timed_out": false}
	var opts = _parse_json_to_js(options_json)
	if opts == null:
		return {"result": "", "error": "invalid_json", "timed_out": false}
	var promise = _sdk_referrals.shareReferralLink(opts)
	var cb_id := _generate_callback_id()
	_setup_promise_callback(promise, cb_id, true)
	return await _wait_for_callback(cb_id, TIMEOUT_NONE)


func list_referrals() -> Dictionary:
	if not _is_web:
		return {"result": _mock.get_list_referrals_response(), "error": "", "timed_out": false}
	var promise = _sdk_referrals.listReferrals()
	var cb_id := _generate_callback_id()
	_setup_promise_callback(promise, cb_id, true)
	var cb_result := await _wait_for_callback(cb_id, TIMEOUT_DEFAULT)
	if cb_result["timed_out"] or not cb_result["error"].is_empty():
		return cb_result
	# Transform referrals from {reference: [{playerId, joinedAt}, ...]} to [{reference, registrations: [{playerId, joinedAt}]}]
	var parsed = JSON.parse_string(cb_result["result"])
	if parsed and parsed is Dictionary and parsed.has("referrals") and parsed["referrals"] is Dictionary:
		var referrals_array: Array = []
		for ref_key in parsed["referrals"]:
			referrals_array.append({"reference": ref_key, "registrations": parsed["referrals"][ref_key]})
		parsed["referrals"] = referrals_array
		cb_result["result"] = JSON.stringify(parsed)
	return cb_result


func get_player_signed() -> Dictionary:
	if not _is_web:
		return {"result": _mock.get_player_signed_response(), "error": "", "timed_out": false}
	var promise = _sdk.getPlayerSigned()
	var cb_id := _generate_callback_id()
	_setup_promise_callback(promise, cb_id, true)
	return await _wait_for_callback(cb_id, TIMEOUT_DEFAULT)


func get_feature_flag(key: String) -> Dictionary:
	if not _is_web:
		return {"result": "", "error": "", "timed_out": false}
	var promise = _sdk_internal.getFeatureFlag(key)
	var cb_id := _generate_callback_id()
	_setup_promise_callback(promise, cb_id, true)
	return await _wait_for_callback(cb_id, TIMEOUT_DEFAULT)


func reserve_login_message(options_json: String) -> Dictionary:
	if not _is_web:
		return {"result": '{"reservation":{"id":"mock-reservation-id","message":"mock-message"}}', "error": "", "timed_out": false}
	var opts = _parse_json_to_js(options_json)
	if opts == null:
		return {"result": "", "error": "invalid_json", "timed_out": false}
	var promise = _sdk_internal.reserveLoginMessageAsync(opts)
	var cb_id := _generate_callback_id()
	_setup_promise_callback(promise, cb_id, true)
	return await _wait_for_callback(cb_id, TIMEOUT_DEFAULT)


func validate_name(name_value: String) -> Dictionary:
	if not _is_web:
		return {"result": '{"status":"valid"}', "error": "", "timed_out": false}
	var promise = _sdk_internal.validateName(name_value)
	var cb_id := _generate_callback_id()
	_setup_promise_callback(promise, cb_id, true)
	return await _wait_for_callback(cb_id, TIMEOUT_DEFAULT)


# --- Registration overlay bridge ---

func show_registration_overlay(options: JestRegistrationOverlayOptions) -> JestRegistrationOverlayHandle:
	var conversation_id := _generate_conversation_id()
	var handle := JestRegistrationOverlayHandle.new(self, conversation_id)

	if not _is_web:
		if _verbose:
			print("[JestSDK] show_registration_overlay (mock) conversation=%s" % conversation_id)
		# Mock mode: immediately report closed so games can exercise their flow.
		if _scene_tree:
			_scene_tree.create_timer(0.0).timeout.connect(func(): handle._on_closed())
		else:
			handle._on_closed()
		return handle

	var opts_js = JavaScriptBridge.create_object("Object")
	opts_js.conversationId = conversation_id
	if options != null:
		opts_js.theme = options.theme
		if not options.entry_payload.is_empty():
			opts_js.entryPayload = _parse_json_to_js(JSON.stringify(options.entry_payload))

	var close_cb = JavaScriptBridge.create_callback(func(_args: Array):
		_overlay_handles.erase(conversation_id)
		_active_callbacks.erase(conversation_id + "_close")
		handle._on_closed()
	)
	opts_js.onClose = close_cb
	_active_callbacks[conversation_id + "_close"] = [close_cb]

	var overlay_handle = _sdk.showRegistrationOverlay(opts_js)
	if overlay_handle == null:
		push_error("[JestSDK] showRegistrationOverlay returned null")
		handle._on_error("no_handle")
		return handle

	# Keep the live JS handle around so login/dismiss actions can invoke it.
	_overlay_handles[conversation_id] = overlay_handle
	return handle


func registration_overlay_login(conversation_id: String) -> void:
	if not _is_web:
		if _verbose:
			print("[JestSDK] registration_overlay_login (mock) conversation=%s" % conversation_id)
		return
	var overlay_handle = _overlay_handles.get(conversation_id)
	if overlay_handle == null:
		push_warning("[JestSDK] No active registration overlay for conversation %s" % conversation_id)
		return
	overlay_handle.loginButtonAction()


func registration_overlay_dismiss() -> void:
	if not _is_web:
		if _verbose:
			print("[JestSDK] registration_overlay_dismiss (mock)")
		return
	# Envelope carries no conversationId; dismiss the most-recently opened overlay.
	if _overlay_handles.is_empty():
		push_warning("[JestSDK] No active registration overlay to dismiss")
		return
	var keys := _overlay_handles.keys()
	var overlay_handle = _overlay_handles[keys[keys.size() - 1]]
	if overlay_handle != null:
		overlay_handle.closeButtonAction()


func _generate_conversation_id() -> String:
	# UUID v4 from 16 random bytes, with RFC 4122 version/variant bits set.
	var bytes := Crypto.new().generate_random_bytes(16)
	bytes[6] = (bytes[6] & 0x0f) | 0x40
	bytes[8] = (bytes[8] & 0x3f) | 0x80
	var hex := bytes.hex_encode()
	return "%s-%s-%s-%s-%s" % [hex.substr(0, 8), hex.substr(8, 4), hex.substr(12, 4), hex.substr(16, 4), hex.substr(20, 12)]


# --- Internal helpers ---

func _generate_callback_id() -> String:
	_next_callback_id += 1
	return "cb_%d_%d" % [Time.get_ticks_msec(), _next_callback_id]


## Parses a JSON string for passing to JavaScript. Returns null on failure.
func _parse_json_to_js(json_string: String) -> Variant:
	if json_string.is_empty():
		push_error("[JestSDK] Cannot parse empty JSON string")
		return null
	var result = _json.parse(json_string)
	if result == null:
		push_error("[JestSDK] Failed to parse JSON: %s" % json_string.left(200))
	return result


## Waits for a callback to complete, with timeout.
## Returns: {result: String, error: String, timed_out: bool}
func _wait_for_callback(cb_id: String, timeout_ms: int = TIMEOUT_DEFAULT) -> Dictionary:
	if not _pending_callbacks.has(cb_id):
		_pending_callbacks[cb_id] = {"result": "", "error": "", "completed": false}

	# Set up timeout timer if we have a scene tree and a finite timeout
	if timeout_ms != TIMEOUT_NONE and _scene_tree:
		var timer := _scene_tree.create_timer(timeout_ms / 1000.0)
		timer.timeout.connect(func():
			if _pending_callbacks.has(cb_id) and not _pending_callbacks[cb_id]["completed"]:
				_pending_callbacks[cb_id]["error"] = "timeout"
				_pending_callbacks[cb_id]["completed"] = true
				_callback_received.emit(cb_id)
		)

	while not _pending_callbacks[cb_id]["completed"]:
		await _callback_received
		if _pending_callbacks.has(cb_id) and _pending_callbacks[cb_id]["completed"]:
			break

	var data: Dictionary = _pending_callbacks.get(cb_id, {"result": "", "error": "callback_lost"})
	var timed_out: bool = data.get("error", "") == "timeout"
	_pending_callbacks.erase(cb_id)
	_active_callbacks.erase(cb_id)

	if not timed_out and not data.get("error", "").is_empty():
		push_error("[JestSDK] Async error: %s" % data["error"])

	return {"result": data.get("result", ""), "error": data.get("error", ""), "timed_out": timed_out}


func _setup_promise_callback(promise: JavaScriptObject, cb_id: String, stringify_result: bool = false) -> void:
	_pending_callbacks[cb_id] = {"completed": false, "result": "", "error": ""}

	var success_cb = JavaScriptBridge.create_callback(func(args: Array):
		var value := ""
		if args.size() > 0 and args[0] != null:
			if stringify_result:
				value = _json.stringify(args[0])
				if not (value is String):
					value = str(args[0])
			else:
				value = str(args[0]) if args[0] != null else ""
		_pending_callbacks[cb_id]["result"] = value
		_pending_callbacks[cb_id]["completed"] = true
		_callback_received.emit(cb_id)
	)

	var error_cb = JavaScriptBridge.create_callback(func(args: Array):
		var err_msg := "unknown_error"
		if args.size() > 0 and args[0] != null:
			var err_obj = args[0]
			var raw := str(err_obj)
			# Godot represents JS null/undefined as "<null>" — treat as unknown
			if raw == "<null>" or raw.is_empty():
				err_msg = "unknown_error"
			elif err_obj is JavaScriptObject:
				# Try to extract .message from JS Error objects
				var msg = err_obj.message
				if msg != null and msg is String and not msg.is_empty():
					err_msg = msg
				else:
					err_msg = raw
			else:
				err_msg = raw
		_pending_callbacks[cb_id]["error"] = err_msg
		_pending_callbacks[cb_id]["completed"] = true
		_callback_received.emit(cb_id)
	)

	promise.then(success_cb).catch(error_cb)

	# Keep references alive to prevent GC (cleaned up in _wait_for_callback)
	_active_callbacks[cb_id] = [success_cb, error_cb]
