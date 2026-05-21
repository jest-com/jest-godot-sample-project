class_name JestPayment
extends RefCounted

var _bridge: JestBridge


func _init(bridge: JestBridge) -> void:
	_bridge = bridge


## Retrieves a list of available in-app purchase products.
## Must be awaited: var products = await JestSDK.payment.get_products()
func get_products() -> Array[JestProduct]:
	var cb_result: Dictionary = await _bridge.get_products()
	if cb_result["timed_out"] or not cb_result["error"].is_empty():
		push_error("[JestSDK] get_products failed: %s" % cb_result["error"])
		return []
	return JestProduct.from_array(JestUtils.parse_json_array(cb_result["result"]))


## Initiates an in-app purchase for the specified product SKU.
## Must be awaited: var result = await JestSDK.payment.begin_purchase("gems_100")
## [br][b]Sandbox testing:[/b] sandbox users see real product prices in the game UI,
## but the platform checkout modal makes clear that no charge will be made and the
## resulting purchase records 0 credits.
func begin_purchase(sku: String) -> JestPurchaseResult:
	if sku.strip_edges().is_empty():
		return JestPurchaseResult.make_error("invalid_sku")
	var cb_result: Dictionary = await _bridge.begin_purchase(sku)
	if cb_result["timed_out"]:
		return JestPurchaseResult.make_error("timeout")
	if not cb_result["error"].is_empty():
		return JestPurchaseResult.make_error(cb_result["error"])
	var json_str: String = cb_result["result"]
	if json_str.is_empty():
		return JestPurchaseResult.make_error("empty_response")
	var d := JestUtils.parse_json_dict(json_str)
	if d.is_empty():
		return JestPurchaseResult.make_error("parse_error")
	return JestPurchaseResult.from_dict(d)


## Completes a pending purchase using the provided purchase token.
## Must be awaited: var result = await JestSDK.payment.complete_purchase("token")
func complete_purchase(purchase_token: String) -> JestResult:
	if purchase_token.strip_edges().is_empty():
		return JestResult.failure("invalid_token")
	var cb_result: Dictionary = await _bridge.complete_purchase(purchase_token)
	if cb_result["timed_out"]:
		return JestResult.failure("timeout")
	if not cb_result["error"].is_empty():
		return JestResult.failure(cb_result["error"])
	var d := JestUtils.parse_json_dict(cb_result["result"])
	if d.get("result", "") == "error":
		return JestResult.failure(str(d.get("error", "unknown")))
	return JestResult.success()


## Initiates a subscription checkout for the specified subscription SKU.
## Must be awaited: var result = await JestSDK.payment.begin_subscription("premium_monthly")
func begin_subscription(sku: String) -> JestSubscriptionResult:
	if sku.strip_edges().is_empty():
		return JestSubscriptionResult.make_error("invalid_sku")
	var cb_result: Dictionary = await _bridge.begin_subscription(sku)
	if cb_result["timed_out"]:
		return JestSubscriptionResult.make_error("timeout")
	if not cb_result["error"].is_empty():
		return JestSubscriptionResult.make_error(cb_result["error"])
	var json_str: String = cb_result["result"]
	if json_str.is_empty():
		return JestSubscriptionResult.make_error("empty_response")
	var d := JestUtils.parse_json_dict(json_str)
	if d.is_empty():
		return JestSubscriptionResult.make_error("parse_error")
	return JestSubscriptionResult.from_dict(d)


## Retrieves subscription offers and the player's current entitlement on each.
## Must be awaited: var result = await JestSDK.payment.get_subscriptions()
## [br]For guest players, result.subscriptions is empty.
## [br]Verify result.signed server-side for any entitlement grant.
func get_subscriptions() -> JestSubscriptionsResult:
	var cb_result: Dictionary = await _bridge.get_subscriptions()
	if cb_result["timed_out"]:
		return JestSubscriptionsResult.make_error("timeout")
	if not cb_result["error"].is_empty():
		return JestSubscriptionsResult.make_error(cb_result["error"])
	var d := JestUtils.parse_json_dict(cb_result["result"])
	return JestSubscriptionsResult.from_dict(d)


## Opens a cancellation confirmation dialog for the specified subscription.
## Must be awaited: var result = await JestSDK.payment.cancel_subscription("premium_monthly")
## [br]If the user confirms, the subscription is cancelled at the end of the current billing period.
func cancel_subscription(sku: String) -> JestCancelSubscriptionResult:
	if sku.strip_edges().is_empty():
		return JestCancelSubscriptionResult.make_error("invalid_sku")
	var cb_result: Dictionary = await _bridge.cancel_subscription(sku)
	if cb_result["timed_out"]:
		return JestCancelSubscriptionResult.make_error("timeout")
	if not cb_result["error"].is_empty():
		return JestCancelSubscriptionResult.make_error(cb_result["error"])
	var json_str: String = cb_result["result"]
	if json_str.is_empty():
		return JestCancelSubscriptionResult.make_error("empty_response")
	var d := JestUtils.parse_json_dict(json_str)
	if d.is_empty():
		return JestCancelSubscriptionResult.make_error("parse_error")
	return JestCancelSubscriptionResult.from_dict(d)


## Retrieves incomplete purchases that have not yet been completed.
## Must be awaited: var result = await JestSDK.payment.get_incomplete_purchases()
func get_incomplete_purchases() -> JestIncompletePurchasesResult:
	var cb_result: Dictionary = await _bridge.get_incomplete_purchases()
	if cb_result["timed_out"]:
		return JestIncompletePurchasesResult.make_error("timeout")
	if not cb_result["error"].is_empty():
		return JestIncompletePurchasesResult.make_error(cb_result["error"])
	var d := JestUtils.parse_json_dict(cb_result["result"])
	return JestIncompletePurchasesResult.from_dict(d)
