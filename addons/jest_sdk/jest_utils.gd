class_name JestUtils
extends RefCounted

## Parses a JSON string and returns the result, or the provided default if parsing fails.
static func parse_json(json_str: String, default: Variant = null) -> Variant:
	if json_str.is_empty():
		return default
	var result = JSON.parse_string(json_str)
	if result == null:
		return default
	return result


## Parses a JSON string and returns it as Dictionary, or the provided default.
static func parse_json_dict(json_str: String, default: Dictionary = {}) -> Dictionary:
	var result = parse_json(json_str)
	if result is Dictionary:
		return result
	return default


## Parses a JSON string and returns it as Array, or the provided default.
static func parse_json_array(json_str: String, default: Array = []) -> Array:
	var result = parse_json(json_str)
	if result is Array:
		return result
	return default
