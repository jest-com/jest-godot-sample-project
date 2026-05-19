class_name JestSubscriptionResult
extends JestResult

enum Status { SUCCESS, CANCELED, ERROR }

## The outcome of the subscription attempt.
var status: Status = Status.ERROR
## The subscription data. Only populated on success.
var subscription: JestSubscription = null
## Signed subscription token for server-side verification.
var subscription_signed: String = ""


static func from_dict(d: Dictionary) -> JestSubscriptionResult:
	var r := JestSubscriptionResult.new()
	var result_str: String = str(d.get("result", "error"))
	match result_str:
		"success":
			r.ok = true
			r.status = Status.SUCCESS
		"cancel":
			r.ok = false
			r.status = Status.CANCELED
			r.error = "subscription_canceled"
		_:
			r.ok = false
			r.status = Status.ERROR
			r.error = str(d.get("error", "unknown_error"))
	if d.has("subscription") and d["subscription"] is Dictionary:
		r.subscription = JestSubscription.from_dict(d["subscription"])
	r.subscription_signed = str(d.get("subscriptionSigned", ""))
	return r


static func make_error(err: String) -> JestSubscriptionResult:
	var r := JestSubscriptionResult.new()
	r.ok = false
	r.status = Status.ERROR
	r.error = err
	return r
