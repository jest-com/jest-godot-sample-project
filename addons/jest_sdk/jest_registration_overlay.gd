class_name JestRegistrationOverlay
extends RefCounted

var _bridge: JestBridge


func _init(bridge: JestBridge) -> void:
	_bridge = bridge


## Presents the platform registration overlay. The game renders its own UI for
## the login / close buttons and drives the flow via the returned handle.
##
## The returned handle fires `closed` when the platform reports the overlay
## has closed (either in response to `close_button_action()` or because the
## platform dismissed the overlay itself).
func show(options: JestRegistrationOverlayOptions = null) -> JestRegistrationOverlayHandle:
	return _bridge.show_registration_overlay(options)
