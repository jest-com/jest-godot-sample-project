class_name JestInternal
extends RefCounted

## Valid onboarding events (must match JS SDK's validOnboardingEvents).
const VALID_ONBOARDING_EVENTS: PackedStringArray = [
	"sms_modal_show", "exit_popup_show", "continue_exit_click",
	"abandon_exit_click", "game_instance_create", "game_load_start",
	"game_load_complete", "game_scene_initialize", "game_scene_enter",
	"unique_text_start", "unique_text_submit",
	"onboarding_complete", "onboarding_fail",
]

var _bridge: JestBridge


func _init(bridge: JestBridge) -> void:
	_bridge = bridge


## Reserves a login message for SMS registration flow.
## Must be awaited: var result = await JestSDK.internal_api.reserve_login_message(options)
func reserve_login_message(options: JestLoginMessageOptions) -> JestLoginReservation:
	var err := options.validate()
	if not err.is_empty():
		push_error("[JestSDK] %s" % err)
		return JestLoginReservation.make_error(err)

	var json_obj := {"message": options.message}
	if not options.keywords.is_empty():
		json_obj["keywords"] = Array(options.keywords)
	if not options.reply_message.is_empty():
		json_obj["replyMessage"] = options.reply_message
	if not options.reminder_message.is_empty():
		json_obj["reminderMessage"] = options.reminder_message
	if not options.entry_payload.is_empty():
		json_obj["entryPayload"] = options.entry_payload

	var cb_result: Dictionary = await _bridge.reserve_login_message(JSON.stringify(json_obj))
	if cb_result.get("timed_out", false):
		return JestLoginReservation.make_error("timeout")
	if not cb_result.get("error", "").is_empty():
		return JestLoginReservation.make_error(cb_result["error"])
	var d := JestUtils.parse_json_dict(cb_result.get("result", ""))
	return JestLoginReservation.from_dict(d)


## Sends a previously reserved login message.
func send_reserved_login_message(reservation: Dictionary) -> void:
	if reservation.is_empty():
		push_error("[JestSDK] reservation cannot be empty")
		return
	_bridge.send_reserved_login_message(JSON.stringify(reservation))


## Captures an onboarding analytics event.
func capture_onboarding_event(event: String, properties: Dictionary = {}) -> void:
	if not event in VALID_ONBOARDING_EVENTS:
		push_error("[JestSDK] Unknown onboarding event: %s" % event)
		return
	var props_json := JSON.stringify(properties) if not properties.is_empty() else ""
	_bridge.capture_onboarding_event(event, props_json)
