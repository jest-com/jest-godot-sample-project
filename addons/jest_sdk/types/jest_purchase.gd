class_name JestPurchase
extends RefCounted

## Token used to complete the purchase.
var purchase_token: String = ""
## SKU of the purchased product.
var product_sku: String = ""
## Total value in Jest Tokens.
var credits: float = 0.0
## Unix timestamp when purchase was created.
var created_at: int = 0
## Unix timestamp when purchase was completed. 0 if not yet completed.
var completed_at: int = 0
## Approximate revenue in USD for the game publisher.
var estimated_revenue: float = 0.0
## Price paid for this purchase in the specified currency, in decimal.
var price: float = 0.0
## ISO currency code for the price, e.g. "USD", "EUR".
var currency: String = ""


static func from_dict(d: Dictionary) -> JestPurchase:
	var p := JestPurchase.new()
	p.purchase_token = str(d.get("purchaseToken", ""))
	p.product_sku = str(d.get("productSku", ""))
	p.credits = float(d.get("credits", 0.0))
	p.created_at = int(d.get("createdAt", 0))
	var completed = d.get("completedAt", null)
	p.completed_at = int(completed) if completed != null else 0
	p.estimated_revenue = float(d.get("estimatedRevenue", 0.0))
	p.price = float(d.get("price", 0.0))
	p.currency = str(d.get("currency", ""))
	return p
