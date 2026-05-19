class_name JestPlayerProfile
extends RefCounted

## The player's display username, or empty string if not set.
var username: String = ""
## The player's avatar URL, or empty string if not set.
var avatar_url: String = ""


static func from_player(player: JestPlayer, sized_avatar_url: String) -> JestPlayerProfile:
	var p := JestPlayerProfile.new()
	p.username = player.username
	p.avatar_url = sized_avatar_url
	return p
