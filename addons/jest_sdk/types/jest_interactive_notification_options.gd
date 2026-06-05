class_name JestInteractiveNotificationOptions
extends Resource

const BODY_CHAR_LIMIT := 2000
const CTA_CHAR_LIMIT := 50
const OPTION_KEY_MAX := 32
const OPTION_LABEL_MAX := 25
const MAX_MESSAGES := 15
const MAX_OPTIONS_PER_MESSAGE := 6

## Ordered messages (required, 1–15 entries). Each entry is a Dictionary.
## Step message: {"key": String, "body": String, "options": [{"key": String, "label": String}, ...]}
## Terminal message: {"key": String, "body": String, "ctaText": String}
@export var messages: Array = []
## Stable identifier for replacing or unscheduling. Optional.
@export var identifier: String = ""
## Delivery weight. Defaults to "medium".
@export_enum("low", "medium", "high", "critical") var priority: String = "medium"
## Pre-approved asset reference for the first message. Optional.
@export var asset_reference: String = ""
## Metadata embedded into the game link. Optional.
@export var entry_payload: Dictionary = {}
## ISO 8601 date string (e.g., "2024-01-15T10:00:00Z"). Mutually exclusive with scheduled_in_days.
@export var date: String = ""
## Days from now, 1–7. Mutually exclusive with date.
@export_range(0, 7) var scheduled_in_days: int = 0


static func _validate_key(key: String) -> String:
	if key.is_empty():
		return "key cannot be empty"
	if key.length() > OPTION_KEY_MAX:
		return "key must be %d characters or fewer" % OPTION_KEY_MAX
	var re := RegEx.new()
	re.compile("^[A-Za-z0-9_-]+$")
	if not re.search(key):
		return "keys may only contain letters, digits, - and _"
	return ""


## Validates this options object. Returns empty string if valid, error message otherwise.
func validate() -> String:
	if messages.is_empty():
		return "at least one message is required"
	if messages.size() > MAX_MESSAGES:
		return "messages must have at most %d entries" % MAX_MESSAGES
	for i in messages.size():
		var msg = messages[i]
		if not msg is Dictionary:
			return "message %d must be a Dictionary" % i
		var key_err := _validate_key(str(msg.get("key", "")))
		if not key_err.is_empty():
			return "message %d key: %s" % [i, key_err]
		var body: String = msg.get("body", "")
		if body.is_empty():
			return "message %d body cannot be empty" % i
		if body.length() > BODY_CHAR_LIMIT:
			return "message %d body must be %d characters or fewer" % [i, BODY_CHAR_LIMIT]
		if msg.has("options"):
			var opts = msg["options"]
			if not opts is Array:
				return "message %d options must be an Array" % i
			if opts.is_empty():
				return "message %d needs at least one option" % i
			if opts.size() > MAX_OPTIONS_PER_MESSAGE:
				return "message %d options must have at most %d entries" % [i, MAX_OPTIONS_PER_MESSAGE]
			for j in opts.size():
				var opt = opts[j]
				if not opt is Dictionary:
					return "message %d option %d must be a Dictionary" % [i, j]
				var opt_key_err := _validate_key(str(opt.get("key", "")))
				if not opt_key_err.is_empty():
					return "message %d option %d key: %s" % [i, j, opt_key_err]
				var label: String = opt.get("label", "")
				if label.is_empty():
					return "message %d option %d label cannot be empty" % [i, j]
				if label.length() > OPTION_LABEL_MAX:
					return "message %d option %d label must be %d characters or fewer" % [i, j, OPTION_LABEL_MAX]
		elif msg.has("ctaText"):
			var cta: String = str(msg.get("ctaText", ""))
			if cta.is_empty():
				return "message %d ctaText cannot be empty" % i
			if cta.length() > CTA_CHAR_LIMIT:
				return "message %d ctaText must be %d characters or fewer" % [i, CTA_CHAR_LIMIT]
		else:
			return "message %d must have either options (step) or ctaText (terminal)" % i
	var has_date := not date.is_empty()
	var has_days := scheduled_in_days > 0
	if not has_date and not has_days:
		return "Either date or scheduled_in_days must be provided"
	if has_date and has_days:
		return "date and scheduled_in_days are mutually exclusive"
	if has_days and (scheduled_in_days < 1 or scheduled_in_days > 7):
		return "scheduled_in_days must be between 1 and 7"
	if has_date:
		var date_dict := Time.get_datetime_dict_from_datetime_string(date, false)
		if date_dict.is_empty():
			return "Invalid date format. Expected ISO 8601"
		var now_unix := Time.get_unix_time_from_system()
		var date_unix := Time.get_unix_time_from_datetime_dict(date_dict)
		if date_unix < now_unix:
			return "Notification date must be in the future"
		if date_unix > now_unix + 7 * 86400:
			return "Notification date must be within the next 7 days"
	return ""
