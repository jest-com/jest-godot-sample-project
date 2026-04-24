class_name JestNotificationOptions
extends Resource

## Notification body text (required).
@export var body: String = ""
## Optional title shown above the body.
@export var title: String = ""
## Call-to-action button text, max 25 chars (required).
@export var cta_text: String = ""
## Unique identifier for rescheduling/unscheduling (required).
@export var identifier: String = ""
## Notification importance level.
@export_enum("low", "medium", "high", "critical") var priority: String = "low"
## Pre-approved asset reference (image or video). Preferred over image_reference.
@export var asset_reference: String = ""
## Deprecated. Use asset_reference instead.
@export var image_reference: String = ""
## Custom data payload passed when the notification is opened.
@export var entry_payload: Dictionary = {}
## ISO 8601 date string (e.g., "2024-01-15T10:00:00Z"). Mutually exclusive with scheduled_in_days.
@export var date: String = ""
## Days from now, 1-7. Mutually exclusive with date.
@export_range(0, 7) var scheduled_in_days: int = 0


## Validates this options object. Returns empty string if valid, error message otherwise.
func validate() -> String:
	if body.is_empty(): return "body is required"
	if cta_text.is_empty(): return "cta_text is required"
	if cta_text.length() > 25: return "cta_text must be 25 characters or fewer"
	if identifier.is_empty(): return "identifier is required"
	var has_date := not date.is_empty()
	var has_days := scheduled_in_days > 0
	if not has_date and not has_days: return "Either date or scheduled_in_days must be provided"
	if has_date and has_days: return "date and scheduled_in_days are mutually exclusive"
	if has_days and (scheduled_in_days < 1 or scheduled_in_days > 7):
		return "scheduled_in_days must be between 1 and 7"
	if has_date:
		var date_dict := Time.get_datetime_dict_from_datetime_string(date, false)
		if date_dict.is_empty():
			return "Invalid date format. Expected ISO 8601"
		var now_unix := Time.get_unix_time_from_system()
		var date_unix := Time.get_unix_time_from_datetime_dict(date_dict)
		if date_unix < now_unix: return "Notification date must be in the future"
		if date_unix > now_unix + 7 * 86400: return "Notification date must be within the next 7 days"
	return ""
