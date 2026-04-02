class_name JestNavigation
extends RefCounted

var _bridge: JestBridge


func _init(bridge: JestBridge) -> void:
	_bridge = bridge


## Redirects the player from an onboarding game to the linked flagship game.
## entry_payload: optional data to pass to the flagship game.
func redirect_to_flagship_game(entry_payload: Dictionary = {}) -> void:
	var message := {"redirectToFlagship": true, "skipGameExitConfirm": false}
	if not entry_payload.is_empty():
		message["entryPayload"] = JSON.stringify(entry_payload)
	_bridge.redirect_to_game(JSON.stringify(message))


## Redirects the player to a specific game by its slug.
## game_slug: slug identifier of the target game (required).
## entry_payload: custom data to pass to the target game.
## skip_exit_confirm: if true, skips the exit confirmation dialog.
func redirect_to_game(game_slug: String, entry_payload: Dictionary = {}, skip_exit_confirm: bool = false) -> void:
	if game_slug.strip_edges().is_empty():
		push_error("[JestSDK] game_slug cannot be empty")
		return

	var message := {
		"gameSlug": game_slug,
		"skipGameExitConfirm": skip_exit_confirm
	}
	if not entry_payload.is_empty():
		message["entryPayload"] = JSON.stringify(entry_payload)
	_bridge.redirect_to_game(JSON.stringify(message))


## Redirects the player to the explore page of the Jest platform.
func redirect_to_explore_page() -> void:
	_bridge.redirect_to_explore_page()
