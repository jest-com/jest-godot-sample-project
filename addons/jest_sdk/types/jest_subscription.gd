class_name JestSubscription
extends RefCounted

## SKU identifier for this subscription.
var sku: String = ""
## Display name of the subscription.
var display_name: String = ""
## Optional description. Empty string when null.
var display_description: String = ""
## Entitlement status: "active" or "inactive".
var status: String = ""
## Price in the specified currency, in decimal.
var price: float = 0.0
## ISO currency code, e.g. "USD".
var currency: String = ""
## Billing period: "monthly", "yearly", or "weekly".
var billing_period: String = ""


static func from_dict(d: Dictionary) -> JestSubscription:
	var s := JestSubscription.new()
	s.sku = str(d.get("sku", ""))
	s.display_name = str(d.get("displayName", ""))
	var desc = d.get("displayDescription", null)
	s.display_description = str(desc) if desc != null else ""
	s.status = str(d.get("status", "inactive"))
	s.price = float(d.get("price", 0.0))
	s.currency = str(d.get("currency", ""))
	s.billing_period = str(d.get("billingPeriod", ""))
	return s
