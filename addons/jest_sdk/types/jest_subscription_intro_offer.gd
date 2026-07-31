class_name JestSubscriptionIntroOffer
extends RefCounted

## Discounted price in the currency specified on the parent subscription, in decimal.
var price: float = 0.0
## Number of billing periods the discounted price applies, measured from signup.
var duration_periods: int = 0


static func from_dict(d: Dictionary) -> JestSubscriptionIntroOffer:
	var o := JestSubscriptionIntroOffer.new()
	o.price = float(d.get("price", 0.0))
	o.duration_periods = int(d.get("durationPeriods", 0))
	return o
