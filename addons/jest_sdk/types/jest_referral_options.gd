class_name JestReferralOptions
extends Resource

## Referral code/reference identifier (required).
@export var reference: String = ""
## Custom data payload passed to the referred player.
@export var entry_payload: Dictionary = {}
## Share dialog title.
@export var share_title: String = ""
## Share message text.
@export var share_text: String = ""
## Custom onboarding flow slug.
@export var onboarding_slug: String = ""


## Validates this options object. Returns empty string if valid, error message otherwise.
func validate() -> String:
	if reference.is_empty(): return "reference cannot be empty"
	return ""
