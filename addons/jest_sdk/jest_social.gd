class_name JestSocial
extends RefCounted

var _player: JestPlayer
var _bridge: JestBridge


func _init(player: JestPlayer, bridge: JestBridge) -> void:
	_player = player
	_bridge = bridge


## Returns the current player's profile data.
## The returned Dictionary has:
##   username: String — empty when the player has no username.
##   avatar_url: String — empty when the player has no avatar.
func get_profile(avatar_size: int = 1000) -> Dictionary:
	return {
		"username": _player.username,
		"avatar_url": get_player_avatar(avatar_size),
	}


## Returns a CDN URL for a bot avatar, deterministically seeded by [param username].
## Use the smallest [param size] that fits your UI. Supported sizes: 64, 128, 256,
## 512, 1000 (default). Other values are bucketed down to the next supported size.
func get_bot_avatar(username: String, size: int = 1000) -> String:
	return JestUtils.get_bot_avatar(username, size)


## Returns a CDN URL for the current player's avatar at the requested [param size],
## routed through Cloudflare Image Resizing so Godot can decode it reliably.
## Returns an empty string when the player has no avatar.
## Supported sizes: 64, 128, 256, 512, 1000 (default). Intermediate values bucket
## down to the next supported size.
func get_player_avatar(size: int = 1000) -> String:
	return JestUtils.get_player_avatar(_player.avatar_url, size)


## Opens the platform's share sheet for an image — the same sheet the platform's
## own screenshot button shows, offering chat, the native share sheet and download.
## The player picks where it goes and writes the caption, so this never shares on
## the player's behalf without a tap.
## [param image] is a base64 PNG/JPEG/WebP/GIF data URL. Omit it to have the
## platform capture the game's canvas, or its registered screenshot provider.
## [param entry_payload] is handed back to the game when a player opens the
## shared message, so a code or coupon travels with it.
## Returns JestShareResult with [code]canceled[/code] true when the sheet closed
## without sharing; this does not guarantee nothing was posted.
## Must be awaited: var result = await JestSDK.social.share_image()
func share_image(image: String = "", entry_payload: Dictionary = {}) -> JestShareResult:
	var json_obj := {}
	if not image.is_empty():
		json_obj["image"] = image
	if not entry_payload.is_empty():
		json_obj["entryPayload"] = entry_payload

	var cb_result: Dictionary = await _bridge.share_image(JSON.stringify(json_obj))
	if cb_result.get("timed_out", false):
		return JestShareResult.make_error("timeout")
	if not cb_result.get("error", "").is_empty():
		return JestShareResult.make_error(cb_result["error"])
	var d := JestUtils.parse_json_dict(cb_result.get("result", ""))
	return JestShareResult.make_success(d.get("canceled", false))
