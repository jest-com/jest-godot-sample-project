class_name JestLoginMessageOptions
extends Resource

## The SMS message content (required).
@export var message: String = ""
## SMS keywords that trigger registration.
@export var keywords: PackedStringArray = []
## Message shown after user replies: {body: String, cta_text: String}
@export var reply_message: Dictionary = {}
## Reminder message: {body: String, cta_text: String}
@export var reminder_message: Dictionary = {}
## Custom data payload.
@export var entry_payload: Dictionary = {}
## Slug of a public game the login link should log the user into, instead of the onboarding's flagship game.
@export var target_game_slug: String = ""


## Validates this options object. Returns empty string if valid, error message otherwise.
func validate() -> String:
	if message.is_empty(): return "message is required"
	return ""
