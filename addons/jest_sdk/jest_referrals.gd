class_name JestReferrals
extends RefCounted

var _bridge: JestBridge


func _init(bridge: JestBridge) -> void:
	_bridge = bridge


## Opens a native share dialog with a referral link.
## Returns JestShareResult indicating whether the user canceled or shared.
## Must be awaited: var result = await JestSDK.referrals.open_referral_dialog(options)
func open_referral_dialog(options: JestReferralOptions) -> JestShareResult:
	var err := options.validate()
	if not err.is_empty():
		push_error("[JestSDK] %s" % err)
		return JestShareResult.make_error(err)

	var json_obj := {"reference": options.reference}
	if not options.entry_payload.is_empty():
		json_obj["entryPayload"] = options.entry_payload
	if not options.share_title.is_empty():
		json_obj["shareTitle"] = options.share_title
	if not options.share_text.is_empty():
		json_obj["shareText"] = options.share_text
	if not options.onboarding_slug.is_empty():
		json_obj["onboardingSlug"] = options.onboarding_slug

	var cb_result: Dictionary = await _bridge.open_referral_dialog(JSON.stringify(json_obj))
	if cb_result.get("timed_out", false):
		return JestShareResult.make_error("timeout")
	if not cb_result.get("error", "").is_empty():
		return JestShareResult.make_error(cb_result["error"])
	var d := JestUtils.parse_json_dict(cb_result.get("result", ""))
	return JestShareResult.make_success(d.get("canceled", false))


## Retrieves the player's referral statistics.
## Must be awaited: var result = await JestSDK.referrals.list_referrals()
func list_referrals() -> JestReferralResult:
	var cb_result: Dictionary = await _bridge.list_referrals()
	if cb_result.get("timed_out", false):
		return JestReferralResult.make_error("timeout")
	if not cb_result.get("error", "").is_empty():
		return JestReferralResult.make_error(cb_result["error"])
	var d := JestUtils.parse_json_dict(cb_result.get("result", ""))
	return JestReferralResult.from_dict(d)
