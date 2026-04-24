class_name JestSDKSingleton
extends Node

## Emitted when the SDK initialization completes. Check success parameter.
signal sdk_initialized(success: bool)

## Emitted when player data is changed locally via set_value/set_int/etc.
signal player_data_changed(key: String, value: String)

## Whether the SDK has been initialized successfully.
var is_initialized: bool:
	get: return _bridge.is_initialized

## Whether the SDK is running in a web browser (true) or mock/editor mode (false).
var is_web: bool:
	get: return _bridge._is_web

## Provides access to player-related functionality and data.
var player: JestPlayer

## Provides access to purchase related functionality and data.
var payment: JestPayment

## Provides access to notification management functionality.
var notifications: JestNotifications

## Provides access to referral functionality and statistics.
var referrals: JestReferrals

## Provides access to navigation functionality for redirecting between games.
var navigation: JestNavigation

## Provides access to internal/experimental SDK functionality.
## These methods may change without notice.
var internal_api: JestInternal

## Provides access to the platform registration overlay flow.
var registration_overlay: JestRegistrationOverlay

## Access to mock configuration. Only available in non-web mode (returns null otherwise).
var mock: JestBridgeMock:
	get: return _bridge._mock if not _bridge._is_web else null

var _bridge: JestBridge


func _ready() -> void:
	_bridge = JestBridge.new()
	_bridge.setup(get_tree())
	player = JestPlayer.new(_bridge, func(k: String, v: String):
		player_data_changed.emit(k, v)
	)
	payment = JestPayment.new(_bridge)
	notifications = JestNotifications.new(_bridge)
	referrals = JestReferrals.new(_bridge)
	navigation = JestNavigation.new(_bridge)
	internal_api = JestInternal.new(_bridge)
	registration_overlay = JestRegistrationOverlay.new(_bridge)


## Initializes the Jest SDK and ensures it's ready for use.
## Returns true on success, false on failure.
## options Dictionary keys:
##   auto_login_reminders: bool (optional, default true) — when false, disables
##     automatic login reminder popups for unregistered users.
##     Manual login via login() is unaffected.
## Must be awaited: var success = await JestSDK.init_sdk()
func init_sdk(options: Dictionary = {}) -> bool:
	var init_options := {}
	if options.has("auto_login_reminders"):
		init_options["autoLoginReminders"] = options["auto_login_reminders"]
	var success := await _bridge.init_sdk(init_options)
	sdk_initialized.emit(success)
	return success


## Retrieves the entry payload data associated with the current session entry.
func get_entry_payload() -> Dictionary:
	return JestUtils.parse_json_dict(_bridge.get_entry_payload())


## Triggers the platform login flow. This is asynchronous and managed by
## the Jest platform. The player's registered state will be updated when
## login completes. Use player.is_registered to check status.
func login(payload: Dictionary = {}) -> void:
	if player.is_registered:
		push_warning("[JestSDK] Player is already logged in")
		return
	var payload_string := ""
	if not payload.is_empty():
		payload_string = JSON.stringify(payload)
	_bridge.login(payload_string)
	player.invalidate_cache()


## Opens the privacy policy page.
func open_privacy_policy() -> void:
	_bridge.open_legal_page("privacy")


## Opens the terms of service page.
func open_terms_of_service() -> void:
	_bridge.open_legal_page("terms")


## Opens the copyright page.
func open_copyright() -> void:
	_bridge.open_legal_page("copyright")


## Triggers debug registration flow (debug builds only).
func debug_register() -> void:
	_bridge.debug_register()


## Gets the value of a feature flag by key.
## Returns JestFeatureFlagResult with typed accessors for string/bool/int/float.
## Must be awaited: var flag = await JestSDK.get_feature_flag("my_flag")
func get_feature_flag(key: String) -> JestFeatureFlagResult:
	if key.strip_edges().is_empty():
		return JestFeatureFlagResult.make_error("key cannot be empty")
	var cb_result: Dictionary = await _bridge.get_feature_flag(key)
	if cb_result["timed_out"]:
		return JestFeatureFlagResult.make_error("timeout")
	if not cb_result["error"].is_empty():
		return JestFeatureFlagResult.make_error(cb_result["error"])
	var raw: String = cb_result["result"]
	var parsed = JSON.parse_string(raw)
	return JestFeatureFlagResult.make_success(parsed if parsed != null else raw)


## Validates a player name against platform rules.
## Must be awaited: var result = await JestSDK.validate_name("player1")
func validate_name(name_value: String) -> JestNameValidationResult:
	if name_value.strip_edges().is_empty():
		return JestNameValidationResult.make_error("name cannot be empty")
	var cb_result: Dictionary = await _bridge.validate_name(name_value)
	if cb_result["timed_out"]:
		return JestNameValidationResult.make_error("timeout")
	if not cb_result["error"].is_empty():
		return JestNameValidationResult.make_error(cb_result["error"])
	return JestNameValidationResult.from_dict(JestUtils.parse_json_dict(cb_result["result"]))


## Reports loading progress to the platform loading screen overlay.
## Only works when the game's loading screen mode is set to "manual".
## progress: Loading progress from 0 to 100. Setting to 100 dismisses the overlay.
func set_loading_progress(progress: float) -> void:
	_bridge.set_loading_progress(progress)
