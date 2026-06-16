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
## Optional notification templates used to alert the referrer when invited players convert.
## Each entry is a Dictionary with "minConversionCount" (int) and "variants" (Array of
## Dictionaries with "body", "ctaText", and optional "title" and "imageReference").
@export var notification_templates: Array = []
## Optional base64 data URL image (e.g. from canvas.toDataURL) to use as the OG image on the
## referral landing page. Accepted MIME: image/png, image/jpeg, image/webp, image/gif. At most 2 MB.
## Animated GIFs are hosted unmodified, so they stay animated in link previews.
@export var share_image: String = ""


## Validates this options object. Returns empty string if valid, error message otherwise.
func validate() -> String:
	if reference.is_empty(): return "reference cannot be empty"
	return ""
