class_name JestNotifications
extends RefCounted

var _bridge: JestBridge


func _init(bridge: JestBridge) -> void:
	_bridge = bridge


## Schedules a notification using a JestNotificationOptions resource.
## Provides autocomplete, type safety, and validation.
func schedule(options: JestNotificationOptions) -> void:
	var err := options.validate()
	if not err.is_empty():
		push_error("[JestSDK] %s" % err)
		return

	var payload := {}
	payload["body"] = options.body
	payload["ctaText"] = options.cta_text
	payload["priority"] = options.priority
	payload["identifier"] = options.identifier

	if not options.image_reference.is_empty():
		payload["imageReference"] = options.image_reference
	if not options.entry_payload.is_empty():
		payload["entryPayload"] = options.entry_payload
	if options.scheduled_in_days > 0:
		payload["scheduledInDays"] = options.scheduled_in_days
	elif not options.date.is_empty():
		payload["scheduledAt"] = options.date

	_bridge.schedule_notification_v2(JSON.stringify(payload))


## Unschedules a previously scheduled notification by its unique identifier.
func unschedule(identifier: String) -> void:
	if identifier.strip_edges().is_empty():
		push_error("[JestSDK] identifier cannot be empty")
		return
	_bridge.unschedule_notification_v2(identifier)
