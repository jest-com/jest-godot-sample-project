class_name JestSubscription
extends RefCounted

## SKU identifier for this subscription.
var sku: String = ""
## Display name of the subscription.
var name: String = ""
## Optional description. Empty string when null.
var description: String = ""
## Whether the subscription is currently active.
var is_active: bool = false
## Price in the specified currency, in decimal.
var price: float = 0.0
## ISO currency code, e.g. "USD".
var currency: String = ""
## Billing period: "monthly", "yearly", or "weekly".
var billing_period: String = ""


static func from_dict(d: Dictionary) -> JestSubscription:
	var s := JestSubscription.new()
	s.sku = str(d.get("sku", ""))
	s.name = str(d.get("name", ""))
	var desc = d.get("description", null)
	s.description = str(desc) if desc != null else ""
	s.is_active = bool(d.get("isActive", false))
	s.price = float(d.get("price", 0.0))
	s.currency = str(d.get("currency", ""))
	s.billing_period = str(d.get("billingPeriod", ""))
	return s
