class_name JestFeatureFlagResult
extends JestResult

## The raw value from the platform. Could be bool, number, string, or object.
var raw_value: Variant = null

## Value as String.
var as_string: String:
	get: return str(raw_value) if raw_value != null else ""

## Value as bool. Parses "true"/"false" strings.
var as_bool: bool:
	get:
		if raw_value is bool: return raw_value
		if raw_value is String: return raw_value.to_lower() == "true"
		return bool(raw_value) if raw_value != null else false

## Value as int.
var as_int: int:
	get: return int(raw_value) if raw_value != null else 0

## Value as float.
var as_float: float:
	get: return float(raw_value) if raw_value != null else 0.0


static func make_success(value: Variant) -> JestFeatureFlagResult:
	var r := JestFeatureFlagResult.new()
	r.ok = true
	r.raw_value = value
	return r


static func make_error(err: String) -> JestFeatureFlagResult:
	var r := JestFeatureFlagResult.new()
	r.ok = false
	r.error = err
	return r
