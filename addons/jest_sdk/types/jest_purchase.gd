class_name JestPurchase
extends RefCounted

## Token used to complete the purchase.
var purchase_token: String = ""
## SKU of the purchased product.
var product_sku: String = ""
## Credit amount.
var credits: int = 0
## Unix timestamp when purchase was created.
var created_at: int = 0
## Unix timestamp when purchase was completed. 0 if not yet completed.
var completed_at: int = 0


static func from_dict(d: Dictionary) -> JestPurchase:
	var p := JestPurchase.new()
	p.purchase_token = str(d.get("purchaseToken", ""))
	p.product_sku = str(d.get("productSku", ""))
	p.credits = int(d.get("credits", 0))
	p.created_at = int(d.get("createdAt", 0))
	var completed = d.get("completedAt", null)
	p.completed_at = int(completed) if completed != null else 0
	return p
