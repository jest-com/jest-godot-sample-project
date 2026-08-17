class_name JestLifecycle
extends RefCounted

## Emitted when the game document changes from visible to hidden.
signal hidden()

## Emitted when the game document changes from hidden to visible.
signal shown()

## Emitted when the platform begins an exit flow for the game.
signal exit_requested()


func _init(bridge: JestBridge) -> void:
	bridge._lifecycle_hidden.connect(func(): hidden.emit())
	bridge._lifecycle_shown.connect(func(): shown.emit())
	bridge._lifecycle_exit_requested.connect(func(): exit_requested.emit())
