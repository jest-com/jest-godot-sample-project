class_name JestNameValidationResult
extends JestResult

## "valid" or "invalid"
var status: String = ""
## Non-empty when status is "invalid".
var validation_error: String = ""

## Whether the name passed validation.
var is_valid: bool:
	get: return status == "valid"


static func from_dict(d: Dictionary) -> JestNameValidationResult:
	var r := JestNameValidationResult.new()
	r.ok = true
	r.status = str(d.get("status", "invalid"))
	r.validation_error = str(d.get("validationError", ""))
	return r


static func make_error(err: String) -> JestNameValidationResult:
	var r := JestNameValidationResult.new()
	r.ok = false
	r.error = err
	return r
