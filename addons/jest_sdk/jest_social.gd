class_name JestSocial
extends RefCounted

var _player: JestPlayer
var _bridge: JestBridge


func _init(player: JestPlayer, bridge: JestBridge = null) -> void:
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


## Registers [param provider] as the screenshot source used when the platform
## asks the game for a screenshot, replacing the SDK's automatic canvas capture.
## [param provider] takes no arguments and must return a base64-encoded PNG
## String (raw or data URL), e.g. [code]JestUtils.texture_to_data_url(get_viewport().get_texture())[/code],
## or an empty string when no screenshot is available right now (e.g. mid-load).
## Pass an invalid Callable (e.g. [code]Callable()[/code]) to unregister and
## restore automatic capture.
## Mirrors the HTML5 SDK's [code]social.setScreenshotProvider(...)[/code].
func set_screenshot_provider(provider: Callable) -> void:
	if _bridge != null:
		_bridge.set_screenshot_provider(provider)
