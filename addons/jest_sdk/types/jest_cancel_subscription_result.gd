class_name JestCancelSubscriptionResult
extends JestResult

enum Status { SUCCESS, CANCELED, ERROR }

## The outcome of the cancellation attempt.
var status: Status = Status.ERROR


static func from_dict(d: Dictionary) -> JestCancelSubscriptionResult:
	var r := JestCancelSubscriptionResult.new()
	var result_str: String = str(d.get("result", "error"))
	match result_str:
		"success":
			r.ok = true
			r.status = Status.SUCCESS
		"cancel":
			r.ok = false
			r.status = Status.CANCELED
			r.error = "cancellation_dismissed"
		_:
			r.ok = false
			r.status = Status.ERROR
			r.error = str(d.get("error", "unknown_error"))
	return r


static func make_error(err: String) -> JestCancelSubscriptionResult:
	var r := JestCancelSubscriptionResult.new()
	r.ok = false
	r.status = Status.ERROR
	r.error = err
	return r
