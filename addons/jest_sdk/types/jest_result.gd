class_name JestResult
extends RefCounted

## Whether the operation succeeded.
var ok: bool = false
## Human-readable error message. Empty when ok is true.
var error: String = ""


func _init(p_ok: bool = false, p_error: String = "") -> void:
	ok = p_ok
	error = p_error


static func success() -> JestResult:
	return JestResult.new(true)


static func failure(err: String) -> JestResult:
	return JestResult.new(false, err)
