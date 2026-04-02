class_name JestPurchaseResult
extends JestResult

enum Status { SUCCESS, CANCELED, ERROR }

## The outcome of the purchase attempt.
var status: Status = Status.ERROR
## The purchase data. Only populated on success.
var purchase: JestPurchase = null
## Signed purchase token for server-side verification.
var purchase_signed: String = ""


static func from_dict(d: Dictionary) -> JestPurchaseResult:
	var r := JestPurchaseResult.new()
	var result_str: String = str(d.get("result", "error"))
	match result_str:
		"success":
			r.ok = true
			r.status = Status.SUCCESS
		"cancel":
			r.ok = false
			r.status = Status.CANCELED
			r.error = "purchase_canceled"
		_:
			r.ok = false
			r.status = Status.ERROR
			r.error = str(d.get("error", "unknown_error"))
	if d.has("purchase") and d["purchase"] is Dictionary:
		r.purchase = JestPurchase.from_dict(d["purchase"])
	r.purchase_signed = str(d.get("purchaseSigned", ""))
	return r


static func make_error(err: String) -> JestPurchaseResult:
	var r := JestPurchaseResult.new()
	r.ok = false
	r.status = Status.ERROR
	r.error = err
	return r
