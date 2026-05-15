class_name JestProduct
extends RefCounted

## Product SKU identifier.
var sku: String = ""
## Display name.
var name: String = ""
## Product description.
var description: String = ""
## Price in the specified currency, in decimal (e.g. 9.99 for $9.99).
var price: float = 0.0
## ISO currency code for the price, e.g. "USD", "EUR".
var currency: String = ""


static func from_dict(d: Dictionary) -> JestProduct:
	var p := JestProduct.new()
	p.sku = str(d.get("sku", ""))
	p.name = str(d.get("name", ""))
	p.description = str(d.get("description", ""))
	p.price = float(d.get("price", 0.0))
	p.currency = str(d.get("currency", ""))
	return p


static func from_array(arr: Array) -> Array[JestProduct]:
	var result: Array[JestProduct] = []
	for d in arr:
		if d is Dictionary:
			result.append(JestProduct.from_dict(d))
	return result
