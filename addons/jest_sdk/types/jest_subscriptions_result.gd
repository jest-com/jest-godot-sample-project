class_name JestSubscriptionsResult
extends JestResult

## List of subscription offers with the player's current entitlement on each.
var subscriptions: Array[JestSubscription] = []
## Signed token for server-side verification (HS256 JWS).
var signed: String = ""


static func from_dict(d: Dictionary) -> JestSubscriptionsResult:
	var r := JestSubscriptionsResult.new()
	r.ok = true
	r.signed = str(d.get("signed", ""))
	r.subscriptions = []
	var arr = d.get("subscriptions", [])
	if arr is Array:
		for item in arr:
			if item is Dictionary:
				r.subscriptions.append(JestSubscription.from_dict(item))
	return r


static func make_error(err: String) -> JestSubscriptionsResult:
	var r := JestSubscriptionsResult.new()
	r.ok = false
	r.error = err
	return r
