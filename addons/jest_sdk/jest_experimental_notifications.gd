class_name JestExperimentalNotifications
extends RefCounted

var _bridge: JestBridge


func _init(bridge: JestBridge) -> void:
	_bridge = bridge


## Schedules an interactive (multi-message) notification: a sequence of messages with reply
## chips that advance in the thread as the player taps. Provide either scheduled_in_days or
## date, not both. The gathered picks are delivered via entry_payload["interactivePicks"].
func schedule_interactive(options: JestInteractiveNotificationOptions) -> void:
	var err := options.validate()
	if not err.is_empty():
		push_error("[JestSDK] %s" % err)
		return

	var payload := {}
	payload["priority"] = options.priority
	payload["messages"] = options.messages
	if not options.identifier.is_empty():
		payload["identifier"] = options.identifier
	if not options.asset_reference.is_empty():
		payload["assetReference"] = options.asset_reference
	if not options.entry_payload.is_empty():
		payload["entryPayload"] = options.entry_payload
	if options.scheduled_in_days > 0:
		payload["scheduledInDays"] = options.scheduled_in_days
	elif not options.date.is_empty():
		payload["scheduledAt"] = options.date

	_bridge.schedule_interactive_notification(JSON.stringify(payload))
