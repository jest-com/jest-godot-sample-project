class_name JestShareResult
extends JestResult

## Whether the user canceled the share dialog.
var canceled: bool = false


static func make_success(was_canceled: bool) -> JestShareResult:
	var r := JestShareResult.new()
	r.ok = true
	r.canceled = was_canceled
	return r


static func make_error(err: String) -> JestShareResult:
	var r := JestShareResult.new()
	r.ok = false
	r.error = err
	return r
