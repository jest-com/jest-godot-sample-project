class_name JestSignedPlayer
extends JestResult

## The player's unique ID.
var player_id: String = ""
## Whether the player is registered.
var registered: bool = false
## The player's display username, or empty string if not set.
var username: String = ""
## The player's avatar URL, or empty string if not set.
var avatar_url: String = ""
## Signed token for server-side verification.
var player_signed: String = ""


static func from_dict(d: Dictionary) -> JestSignedPlayer:
	var r := JestSignedPlayer.new()
	r.ok = true
	var player_data = d.get("player", {})
	if player_data is Dictionary:
		r.player_id = str(player_data.get("playerId", ""))
		r.registered = bool(player_data.get("registered", false))
		var uname = player_data.get("username", "")
		r.username = str(uname) if uname != null else ""
		var av = player_data.get("avatarUrl", "")
		r.avatar_url = str(av) if av != null else ""
	r.player_signed = str(d.get("playerSigned", ""))
	return r


static func make_error(err: String) -> JestSignedPlayer:
	var r := JestSignedPlayer.new()
	r.ok = false
	r.error = err
	return r
