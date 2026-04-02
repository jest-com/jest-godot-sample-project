class_name JestIncompletePurchasesResult
extends JestResult

## Whether there are more incomplete purchases beyond this batch.
var has_more: bool = false
## The list of incomplete purchases.
var purchases: Array[JestPurchase] = []
## Signed token for server-side verification.
var purchases_signed: String = ""


static func from_dict(d: Dictionary) -> JestIncompletePurchasesResult:
	var r := JestIncompletePurchasesResult.new()
	r.ok = true
	r.has_more = bool(d.get("hasMore", false))
	r.purchases_signed = str(d.get("purchasesSigned", ""))
	r.purchases = []
	var arr = d.get("purchases", [])
	if arr is Array:
		for item in arr:
			if item is Dictionary:
				r.purchases.append(JestPurchase.from_dict(item))
	return r


static func make_error(err: String) -> JestIncompletePurchasesResult:
	var r := JestIncompletePurchasesResult.new()
	r.ok = false
	r.error = err
	return r
