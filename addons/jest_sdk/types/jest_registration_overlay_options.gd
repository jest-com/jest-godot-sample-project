class_name JestRegistrationOverlayOptions
extends Resource

const REGISTRATION_CODE_PLACEHOLDER := "{{registrationCode}}"
const REGISTRATION_CODE_LENGTH := 6
const REGISTRATION_MESSAGE_CHAR_LIMIT := 140

## Overlay theme: "light" or "dark". Defaults to "dark".
@export_enum("dark", "light") var theme: String = "dark"

## Custom data accessible via JestSDK.get_entry_payload() after registration.
@export var entry_payload: Dictionary = {}

## Optional text the player's messaging app is pre-filled with, in place of the
## platform's default wording. Must contain REGISTRATION_CODE_PLACEHOLDER exactly
## once, with a space or punctuation around it, and stay under
## REGISTRATION_MESSAGE_CHAR_LIMIT characters once the code is filled in.
@export var message: String = ""

## Optional callback invoked when the platform reports the popup has closed.
var on_close: Callable = Callable()


## Validates this options object. Returns empty string if valid, error message otherwise.
func validate() -> String:
	if message.is_empty():
		return ""
	var trimmed := message.strip_edges()
	if trimmed.is_empty():
		return "message must not be empty"
	var at := trimmed.find(REGISTRATION_CODE_PLACEHOLDER)
	if at == -1:
		return "message must contain %s" % REGISTRATION_CODE_PLACEHOLDER
	var before := trimmed.substr(0, at)
	var after := trimmed.substr(at + REGISTRATION_CODE_PLACEHOLDER.length())
	if (before + after).find("{") != -1 or (before + after).find("}") != -1:
		return "message must contain %s once and no other placeholder" % REGISTRATION_CODE_PLACEHOLDER
	var boundary_re := RegEx.create_from_string("[\\w+]")
	var no_space_before := not before.is_empty() and boundary_re.search(before.substr(before.length() - 1)) != null
	var no_space_after := not after.is_empty() and boundary_re.search(after.substr(0, 1)) != null
	if no_space_before or no_space_after:
		return "message must leave a space around %s" % REGISTRATION_CODE_PLACEHOLDER
	var sent_length := trimmed.length() - REGISTRATION_CODE_PLACEHOLDER.length() + REGISTRATION_CODE_LENGTH
	if sent_length > REGISTRATION_MESSAGE_CHAR_LIMIT:
		return "message must be at most %d characters once the code is filled in" % REGISTRATION_MESSAGE_CHAR_LIMIT
	return ""
