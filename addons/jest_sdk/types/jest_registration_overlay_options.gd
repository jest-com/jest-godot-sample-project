class_name JestRegistrationOverlayOptions
extends Resource

## Overlay theme: "light" or "dark". Defaults to "dark".
@export_enum("dark", "light") var theme: String = "dark"

## Custom data accessible via JestSDK.get_entry_payload() after registration.
@export var entry_payload: Dictionary = {}
