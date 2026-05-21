class_name JestSocial
extends RefCounted

var _player: JestPlayer
static var _warned_get_player_avatar: bool = false


func _init(player: JestPlayer) -> void:
	_player = player


## Returns the current player's profile (username and sized avatar URL).
## [param avatar_size] supported values: 64, 128, 256, 512, 1000 (default).
## Other values are bucketed down to the next supported size.
func get_profile(avatar_size: int = 1000) -> JestPlayerProfile:
	var sized_avatar := JestUtils.get_player_avatar(_player.avatar_url, avatar_size)
	return JestPlayerProfile.from_player(_player, sized_avatar)


## Returns a CDN URL for a bot avatar, deterministically seeded by [param username].
## Use the smallest [param size] that fits your UI. Supported sizes: 64, 128, 256,
## 512, 1000 (default). Other values are bucketed down to the next supported size.
func get_bot_avatar(username: String, size: int = 1000) -> String:
	return JestUtils.get_bot_avatar(username, size)


## [b]Deprecated.[/b] Use [code]get_profile(size).avatar_url[/code] instead.
## Returns a CDN URL for the current player's avatar at the requested [param size],
## routed through Cloudflare Image Resizing so Godot can decode it reliably.
## Returns an empty string when the player has no avatar.
## Supported sizes: 64, 128, 256, 512, 1000 (default). Intermediate values bucket
## down to the next supported size.
func get_player_avatar(size: int = 1000) -> String:
	if not _warned_get_player_avatar:
		_warned_get_player_avatar = true
		push_warning("JestSocial.get_player_avatar is deprecated; use get_profile(size).avatar_url instead.")
	return JestUtils.get_player_avatar(_player.avatar_url, size)
