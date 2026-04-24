class_name JestRegistrationOverlayHandle
extends RefCounted

## Fired once when the platform reports the registration overlay has closed.
signal closed()

## Fired if the bridge reports an error while driving the overlay.
signal errored(message: String)

var _bridge: JestBridge
var _conversation_id: String
var _is_closed: bool = false


func _init(bridge: JestBridge, conversation_id: String) -> void:
	_bridge = bridge
	_conversation_id = conversation_id


## Whether the overlay has been closed (after which button actions are no-ops).
var is_closed: bool:
	get: return _is_closed


## Unique conversation id for this overlay session.
var conversation_id: String:
	get: return _conversation_id


## Signals to the platform that the user tapped the game-rendered login button.
func login_button_action() -> void:
	if _is_closed:
		return
	_bridge.registration_overlay_login(_conversation_id)


## Signals to the platform that the user tapped the game-rendered close button.
func close_button_action() -> void:
	if _is_closed:
		return
	_bridge.registration_overlay_dismiss()


## Internal: fires the closed signal once when the platform reports closure.
func _on_closed() -> void:
	if _is_closed:
		return
	_is_closed = true
	closed.emit()


## Internal: fires the error signal.
func _on_error(message: String) -> void:
	errored.emit(message)
