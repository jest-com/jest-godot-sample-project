extends Control

# --- Node References ---

# Login
@onready var login_payload_input: LineEdit = %LoginPayloadInput
@onready var login_button: Button = %LoginButton

# Player State Management
@onready var key_input: LineEdit = %KeyInput
@onready var value_input: LineEdit = %ValueInput
@onready var add_button: Button = %AddButton
@onready var delete_key_input: LineEdit = %DeleteKeyInput
@onready var delete_button: Button = %DeleteButton
@onready var flush_button: Button = %FlushButton
@onready var get_signed_button: Button = %GetSignedButton

# Player State View
@onready var player_data_label: TextEdit = %PlayerDataLabel
@onready var copy_button: Button = %CopyButton

# Payments
@onready var load_products_button: Button = %LoadProductsButton
@onready var products_container: VBoxContainer = %ProductsContainer
@onready var load_incomplete_button: Button = %LoadIncompleteButton
@onready var incomplete_container: VBoxContainer = %IncompleteContainer

# Notifications
@onready var notif_body_input: LineEdit = %NotifBodyInput
@onready var notif_cta_input: LineEdit = %NotifCtaInput
@onready var notif_image_input: LineEdit = %NotifImageInput
@onready var notif_identifier_input: LineEdit = %NotifIdentifierInput
@onready var notif_entry_payload_input: LineEdit = %NotifEntryPayloadInput
@onready var priority_option: OptionButton = %PriorityOption
@onready var schedule_mode_option: OptionButton = %ScheduleModeOption
@onready var minutes_row: HBoxContainer = %MinutesRow
@onready var minutes_input: LineEdit = %MinutesInput
@onready var days_row: HBoxContainer = %DaysRow
@onready var days_input: LineEdit = %DaysInput
@onready var schedule_button: Button = %ScheduleButton
@onready var unschedule_id_input: LineEdit = %UnscheduleIdInput
@onready var unschedule_button: Button = %UnscheduleButton

# Debug
@onready var debug_register_button: Button = %DebugRegisterButton
@onready var show_registration_overlay_button: Button = %ShowRegistrationOverlayButton
@onready var custom_registration_overlay: ColorRect = %CustomRegistrationOverlay
@onready var custom_registration_login_button: Button = %CustomRegistrationLoginButton
@onready var custom_registration_close_button: Button = %CustomRegistrationCloseButton

# Referrals
@onready var ref_reference_input: LineEdit = %RefReferenceInput
@onready var ref_entry_payload_input: LineEdit = %RefEntryPayloadInput
@onready var ref_onboarding_slug_input: LineEdit = %RefOnboardingSlugInput
@onready var open_dialog_button: Button = %OpenDialogButton
@onready var list_referrals_button: Button = %ListReferralsButton
@onready var referrals_output_label: RichTextLabel = %ReferralsOutputLabel

# Loading & Toast
@onready var loading_overlay: ColorRect = %LoadingOverlay
@onready var toast_container: PanelContainer = %ToastContainer
@onready var toast_label: Label = %ToastLabel

# --- State ---
var _toast_tween: Tween
var _registration_overlay_handle: JestRegistrationOverlayHandle
var _bots_username_input: LineEdit
var _bots_avatar_texture: TextureRect
var _bots_url_label: Label
var _bots_http_request: HTTPRequest
var _player_avatar_texture: TextureRect
var _player_avatar_url_label: Label
var _player_avatar_http_request: HTTPRequest
var _subscription_sku_input: LineEdit


# Keeps Cloudflare's resized avatar response on a WebP CORS-enabled variant.
const AVATAR_REQUEST_HEADERS: PackedStringArray = [
	"Accept: image/webp,image/png,image/jpeg,*/*",
]

# --- Lifecycle ---

func _ready():
	_connect_signals()
	_setup_dropdowns()
	_setup_bots_section()
	_setup_player_avatar_section()
	_setup_subscription_section()
	_init_sdk()


func _init_sdk():
	_show_loading()
	var success := await JestSDK.init_sdk()
	_hide_loading()
	if not success:
		_show_toast("SDK initialization failed")
		return
	_refresh_player_state()
	_show_toast("SDK initialized")


func _setup_dropdowns():
	priority_option.add_item("Low", 0)
	priority_option.add_item("Medium", 1)
	priority_option.add_item("High", 2)
	priority_option.selected = 0

	schedule_mode_option.add_item("Exact (minutes)", 0)
	schedule_mode_option.add_item("Fuzzy (days)", 1)
	schedule_mode_option.selected = 0
	_on_schedule_mode_changed(0)


func _connect_signals():
	# Login
	login_button.pressed.connect(_on_login_pressed)

	# Player State
	add_button.pressed.connect(_on_add_pressed)
	delete_button.pressed.connect(_on_delete_pressed)
	flush_button.pressed.connect(_on_flush_pressed)
	get_signed_button.pressed.connect(_on_get_signed_pressed)
	copy_button.pressed.connect(_on_copy_pressed)

	# Payments
	load_products_button.pressed.connect(_on_load_products_pressed)
	load_incomplete_button.pressed.connect(_on_load_incomplete_pressed)

	# Notifications
	schedule_mode_option.item_selected.connect(_on_schedule_mode_changed)
	schedule_button.pressed.connect(_on_schedule_pressed)
	unschedule_button.pressed.connect(_on_unschedule_pressed)

	# Debug
	debug_register_button.pressed.connect(_on_debug_register_pressed)
	show_registration_overlay_button.pressed.connect(_on_show_registration_overlay_pressed)
	custom_registration_login_button.pressed.connect(_on_custom_registration_login_pressed)
	custom_registration_close_button.pressed.connect(_on_custom_registration_close_pressed)

	# Referrals
	open_dialog_button.pressed.connect(_on_open_dialog_pressed)
	list_referrals_button.pressed.connect(_on_list_referrals_pressed)



# --- Login ---

func _on_login_pressed():
	var payload := {}
	var text := login_payload_input.text.strip_edges()
	if text != "":
		var parsed = JSON.parse_string(text)
		if parsed == null:
			_show_toast("Invalid JSON payload")
			return
		if parsed is Dictionary:
			payload = parsed
		else:
			_show_toast("Payload must be a JSON object")
			return
	JestSDK.login(payload)
	_show_toast("Login called")
	_refresh_player_state()


# --- Player State Management ---

func _on_add_pressed():
	var key := key_input.text.strip_edges()
	var value := value_input.text.strip_edges()
	if key == "":
		_show_toast("Key is required")
		return
	JestSDK.player.set_value(key, value)
	_show_toast("Set '%s' = '%s'" % [key, value])
	key_input.text = ""
	value_input.text = ""
	_refresh_player_state()


func _on_delete_pressed():
	var key := delete_key_input.text.strip_edges()
	if key == "":
		_show_toast("Key is required")
		return
	JestSDK.player.delete_value(key)
	_show_toast("Deleted '%s'" % key)
	delete_key_input.text = ""
	_refresh_player_state()


func _on_flush_pressed():
	_show_loading()
	var result := await JestSDK.player.flush()
	_hide_loading()
	_show_toast("Flush: %s" % ("ok" if result.ok else result.error))
	_refresh_player_state()


func _on_get_signed_pressed():
	_show_loading()
	var result := await JestSDK.player.get_signed()
	_hide_loading()
	if result.ok:
		_show_toast("Player: %s (registered: %s)" % [result.player_id, result.registered])
	else:
		_show_toast("Error: %s" % result.error)


# --- Player State View ---

func _refresh_player_state():
	var data := JestSDK.player.get_player_data()
	player_data_label.text = data


func _on_copy_pressed():
	DisplayServer.clipboard_set(player_data_label.text)
	_show_toast("Copied to clipboard")


# --- Payments ---

func _on_load_products_pressed():
	_show_loading()
	var products := await JestSDK.payment.get_products()
	_hide_loading()

	for child in products_container.get_children():
		child.queue_free()

	for product in products:
		var cell := _create_product_cell(product)
		products_container.add_child(cell)

	_show_toast("Loaded %d products" % products.size())


func _create_product_cell(product: JestProduct) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var name_label := Label.new()
	name_label.text = product.name
	var desc_label := Label.new()
	desc_label.text = "%s — %.2f %s" % [product.description, product.price, product.currency]
	desc_label.add_theme_font_size_override("font_size", 12)
	desc_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	info.add_child(name_label)
	info.add_child(desc_label)

	var buy_btn := Button.new()
	buy_btn.text = "Buy"
	buy_btn.pressed.connect(_on_buy_pressed.bind(product.sku))

	row.add_child(info)
	row.add_child(buy_btn)
	return row


func _on_buy_pressed(sku: String):
	_show_loading()
	var result := await JestSDK.payment.begin_purchase(sku)
	_hide_loading()
	if result.ok:
		_show_toast("Purchase successful: %s" % result.purchase.product_sku)
	elif result.status == JestPurchaseResult.Status.CANCELED:
		_show_toast("Purchase canceled")
	else:
		_show_toast("Purchase error: %s" % result.error)


func _on_load_incomplete_pressed():
	_show_loading()
	var result := await JestSDK.payment.get_incomplete_purchases()
	_hide_loading()

	for child in incomplete_container.get_children():
		child.queue_free()

	if not result.ok:
		_show_toast("Error: %s" % result.error)
		return

	for purchase in result.purchases:
		var cell := _create_incomplete_cell(purchase)
		incomplete_container.add_child(cell)

	_show_toast("Loaded %d incomplete purchases" % result.purchases.size())


func _create_incomplete_cell(purchase: JestPurchase) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var sku_label := Label.new()
	sku_label.text = purchase.product_sku
	var token_label := Label.new()
	token_label.text = "Token: %s" % purchase.purchase_token
	token_label.add_theme_font_size_override("font_size", 12)
	token_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	info.add_child(sku_label)
	info.add_child(token_label)

	var complete_btn := Button.new()
	complete_btn.text = "Complete"
	complete_btn.pressed.connect(_on_complete_purchase_pressed.bind(purchase.purchase_token))

	row.add_child(info)
	row.add_child(complete_btn)
	return row


func _on_complete_purchase_pressed(token: String):
	_show_loading()
	var result := await JestSDK.payment.complete_purchase(token)
	_hide_loading()
	_show_toast("Complete: %s" % ("ok" if result.ok else result.error))


# --- Notifications ---

func _on_schedule_mode_changed(index: int):
	minutes_row.visible = (index == 0)
	days_row.visible = (index == 1)


func _on_schedule_pressed():
	var opts := JestNotificationOptions.new()
	opts.body = notif_body_input.text.strip_edges()
	opts.cta_text = notif_cta_input.text.strip_edges()
	opts.identifier = notif_identifier_input.text.strip_edges()
	opts.image_reference = notif_image_input.text.strip_edges()

	var entry_text := notif_entry_payload_input.text.strip_edges()
	if entry_text != "":
		var parsed = JSON.parse_string(entry_text)
		if parsed == null:
			_show_toast("Invalid entry payload JSON")
			return
		if parsed is Dictionary:
			opts.entry_payload = parsed

	match priority_option.selected:
		1: opts.priority = "medium"
		2: opts.priority = "high"
		_: opts.priority = "low"

	if schedule_mode_option.selected == 0:
		var minutes_text := minutes_input.text.strip_edges()
		if minutes_text == "":
			_show_toast("Minutes is required for exact scheduling")
			return
		var minutes := minutes_text.to_int()
		if minutes <= 0:
			_show_toast("Minutes must be positive")
			return
		var unix_time := int(Time.get_unix_time_from_system()) + (minutes * 60)
		opts.date = Time.get_datetime_string_from_unix_time(unix_time)
	else:
		var days_text := days_input.text.strip_edges()
		if days_text == "":
			_show_toast("Days is required for fuzzy scheduling")
			return
		opts.scheduled_in_days = days_text.to_int()

	var err := opts.validate()
	if not err.is_empty():
		_show_toast(err)
		return

	JestSDK.notifications.schedule(opts)
	_show_toast("Notification scheduled: %s" % opts.identifier)
	_refresh_player_state()


func _on_unschedule_pressed():
	var identifier := unschedule_id_input.text.strip_edges()
	if identifier == "":
		_show_toast("Identifier is required")
		return
	JestSDK.notifications.unschedule(identifier)
	_show_toast("Notification unscheduled: %s" % identifier)
	unschedule_id_input.text = ""


# --- Debug ---

func _on_debug_register_pressed():
	JestSDK.debug_register()
	_show_toast("Debug register called")


func _on_show_registration_overlay_pressed():
	if _registration_overlay_handle != null and not _registration_overlay_handle.is_closed:
		custom_registration_overlay.visible = true
		return

	var opts := JestRegistrationOverlayOptions.new()
	opts.theme = "dark"
	opts.entry_payload = {"source": "godot_sample_registration_overlay"}
	opts.message = "Join the game! {{registrationCode}} is my code."
	opts.on_close = func():
		custom_registration_overlay.visible = false
		_registration_overlay_handle = null
		_show_toast("Registration popup closed")

	custom_registration_overlay.visible = true
	_registration_overlay_handle = JestSDK.show_registration_overlay(opts)
	if _registration_overlay_handle == null:
		custom_registration_overlay.visible = false
		_show_toast("Registration popup failed")
		return
	_registration_overlay_handle.errored.connect(func(message: String):
		custom_registration_overlay.visible = false
		_show_toast("Registration popup error: %s" % message)
	)
	if _registration_overlay_handle.is_closed:
		_registration_overlay_handle = null
	_show_toast("Registration popup shown")


func _on_custom_registration_login_pressed():
	if _registration_overlay_handle == null or _registration_overlay_handle.is_closed:
		custom_registration_overlay.visible = false
		_show_toast("Show the registration popup first")
		return
	_registration_overlay_handle.login_button_action()


func _on_custom_registration_close_pressed():
	custom_registration_overlay.visible = false
	if _registration_overlay_handle == null or _registration_overlay_handle.is_closed:
		_registration_overlay_handle = null
		return
	_registration_overlay_handle.close_button_action()


# --- Referrals ---

func _on_open_dialog_pressed():
	var opts := JestReferralOptions.new()
	opts.reference = ref_reference_input.text.strip_edges()

	var entry_text := ref_entry_payload_input.text.strip_edges()
	if entry_text != "":
		var parsed = JSON.parse_string(entry_text)
		if parsed == null:
			_show_toast("Invalid entry payload JSON")
			return
		if parsed is Dictionary:
			opts.entry_payload = parsed

	var slug := ref_onboarding_slug_input.text.strip_edges()
	if slug != "":
		opts.onboarding_slug = slug

	# Demonstrate notificationTemplates: notify the referrer after their first conversion.
	opts.notification_templates = [
		{
			"minConversionCount": 1,
			"variants": [
				{"body": "Someone you invited just joined!", "ctaText": "Check it out"},
			],
		},
	]

	var err := opts.validate()
	if not err.is_empty():
		_show_toast(err)
		return

	_show_loading()
	var result := await JestSDK.referrals.open_referral_dialog(opts)
	_hide_loading()
	if result.ok:
		_show_toast("Shared" if not result.canceled else "Share canceled")
	else:
		_show_toast("Error: %s" % result.error)


func _on_list_referrals_pressed():
	_show_loading()
	var result := await JestSDK.referrals.list_referrals()
	_hide_loading()

	if not result.ok:
		_show_toast("Error: %s" % result.error)
		return

	if result.referrals.is_empty():
		referrals_output_label.text = "No referrals found"
	else:
		var lines: PackedStringArray = []
		for ref in result.referrals:
			var regs = ref.get("registrations", [])
			lines.append("%s: %d registrations" % [ref.get("reference", ""), regs.size()])
		referrals_output_label.text = "\n".join(lines)

	_show_toast("Loaded %d referrals" % result.referrals.size())



# --- Bots ---

func _setup_bots_section():
	var content := $ScrollContainer/ContentVBox

	var sep := HSeparator.new()
	content.add_child(sep)

	var heading := Label.new()
	heading.text = "Bots"
	heading.add_theme_font_size_override("font_size", 20)
	content.add_child(heading)

	var caption := Label.new()
	caption.text = "Username (seed)"
	caption.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6, 1))
	caption.add_theme_font_size_override("font_size", 12)
	content.add_child(caption)

	_bots_username_input = LineEdit.new()
	_bots_username_input.placeholder_text = "Bot username (e.g. \"Sparkles\")"
	_bots_username_input.text = "Sparkles"
	content.add_child(_bots_username_input)

	var btn := Button.new()
	btn.text = "Get Bot Avatar"
	btn.pressed.connect(_on_get_bot_avatar_pressed)
	content.add_child(btn)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	content.add_child(row)

	_bots_avatar_texture = TextureRect.new()
	_bots_avatar_texture.custom_minimum_size = Vector2(128, 128)
	_bots_avatar_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_bots_avatar_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(_bots_avatar_texture)

	_bots_url_label = Label.new()
	_bots_url_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_bots_url_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_bots_url_label.add_theme_font_size_override("font_size", 11)
	_bots_url_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1))
	row.add_child(_bots_url_label)

	_bots_http_request = HTTPRequest.new()
	add_child(_bots_http_request)
	_bots_http_request.request_completed.connect(_on_bot_avatar_downloaded)


func _on_get_bot_avatar_pressed():
	var username := _bots_username_input.text.strip_edges()
	if username.is_empty():
		_show_toast("Username is required")
		return
	var url := JestSDK.get_bot_avatar(username, 128)
	_bots_url_label.text = url
	_bots_http_request.cancel_request()
	var err := _bots_http_request.request(url, AVATAR_REQUEST_HEADERS)
	if err != OK:
		_show_toast("Avatar request failed: %d" % err)


func _on_bot_avatar_downloaded(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
	if result != HTTPRequest.RESULT_SUCCESS or response_code < 200 or response_code >= 300:
		_show_toast("Avatar load failed (%d)" % response_code)
		return
	var image := Image.new()
	if not _load_avatar_image(image, headers, body):
		_show_toast("Image decode failed")
		return
	_bots_avatar_texture.texture = ImageTexture.create_from_image(image)


# --- Player Avatar ---

func _setup_player_avatar_section():
	var content := $ScrollContainer/ContentVBox

	var sep := HSeparator.new()
	content.add_child(sep)

	var heading := Label.new()
	heading.text = "Player Avatar"
	heading.add_theme_font_size_override("font_size", 20)
	content.add_child(heading)

	var profile_btn := Button.new()
	profile_btn.text = "Get Profile (social)"
	profile_btn.pressed.connect(_on_get_profile_pressed)
	content.add_child(profile_btn)

	var btn := Button.new()
	btn.text = "Get Player Avatar"
	btn.pressed.connect(_on_get_player_avatar_pressed)
	content.add_child(btn)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	content.add_child(row)

	_player_avatar_texture = TextureRect.new()
	_player_avatar_texture.custom_minimum_size = Vector2(128, 128)
	_player_avatar_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_player_avatar_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(_player_avatar_texture)

	_player_avatar_url_label = Label.new()
	_player_avatar_url_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_player_avatar_url_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_player_avatar_url_label.add_theme_font_size_override("font_size", 11)
	_player_avatar_url_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1))
	row.add_child(_player_avatar_url_label)

	_player_avatar_http_request = HTTPRequest.new()
	add_child(_player_avatar_http_request)
	_player_avatar_http_request.request_completed.connect(_on_player_avatar_downloaded)


func _on_get_profile_pressed():
	var profile := JestSDK.social.get_profile(128)
	var username: String = profile.get("username", "")
	var avatar_url: String = profile.get("avatar_url", "")
	_show_toast("Profile: %s | avatar: %s" % [
		username if not username.is_empty() else "(none)",
		avatar_url if not avatar_url.is_empty() else "(none)",
	])


func _on_get_player_avatar_pressed():
	if not JestSDK.player.is_registered:
		_show_toast("Player is not registered")
		return
	var url := JestSDK.get_player_avatar(128)
	if url.is_empty():
		_show_toast("Player has no avatar")
		return
	_player_avatar_url_label.text = url
	_player_avatar_http_request.cancel_request()
	var err := _player_avatar_http_request.request(url, AVATAR_REQUEST_HEADERS)
	if err != OK:
		_show_toast("Avatar request failed: %d" % err)


func _on_player_avatar_downloaded(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
	if result != HTTPRequest.RESULT_SUCCESS or response_code < 200 or response_code >= 300:
		_show_toast("Avatar load failed (%d)" % response_code)
		return
	var image := Image.new()
	if not _load_avatar_image(image, headers, body):
		_show_toast("Image decode failed")
		return
	_player_avatar_texture.texture = ImageTexture.create_from_image(image)


func _load_avatar_image(image: Image, headers: PackedStringArray, body: PackedByteArray) -> bool:
	var content_type := _avatar_content_type(headers)
	if content_type == "webp":
		return image.load_webp_from_buffer(body) == OK
	if content_type == "png":
		return image.load_png_from_buffer(body) == OK
	if content_type == "jpg":
		return image.load_jpg_from_buffer(body) == OK
	if image.load_webp_from_buffer(body) == OK:
		return true
	if image.load_png_from_buffer(body) == OK:
		return true
	return image.load_jpg_from_buffer(body) == OK


func _avatar_content_type(headers: PackedStringArray) -> String:
	for header in headers:
		var parts := header.split(":", false, 1)
		if parts.size() != 2 or parts[0].strip_edges().to_lower() != "content-type":
			continue
		var content_type := parts[1].strip_edges().to_lower()
		if content_type.contains("webp"):
			return "webp"
		if content_type.contains("png"):
			return "png"
		if content_type.contains("jpeg") or content_type.contains("jpg"):
			return "jpg"
	return ""


# --- Subscriptions ---

func _setup_subscription_section():
	var content := $ScrollContainer/ContentVBox

	var sep := HSeparator.new()
	content.add_child(sep)

	var heading := Label.new()
	heading.text = "Subscriptions"
	heading.add_theme_font_size_override("font_size", 20)
	content.add_child(heading)

	var caption := Label.new()
	caption.text = "Subscription SKU"
	caption.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6, 1))
	caption.add_theme_font_size_override("font_size", 12)
	content.add_child(caption)

	_subscription_sku_input = LineEdit.new()
	_subscription_sku_input.placeholder_text = "e.g. \"premium_monthly\""
	_subscription_sku_input.text = "premium_monthly"
	content.add_child(_subscription_sku_input)

	var btn := Button.new()
	btn.text = "Begin Subscription"
	btn.pressed.connect(_on_begin_subscription_pressed)
	content.add_child(btn)


func _on_begin_subscription_pressed():
	var sku := _subscription_sku_input.text.strip_edges()
	if sku.is_empty():
		_show_toast("SKU is required")
		return
	_show_loading()
	var result := await JestSDK.payment.begin_subscription(sku)
	_hide_loading()
	if result.status == JestSubscriptionResult.Status.SUCCESS:
		_show_toast("Subscribed: %s (%s)" % [result.subscription.name, result.subscription.billing_period])
	elif result.status == JestSubscriptionResult.Status.CANCELED:
		_show_toast("Subscription canceled")
	else:
		_show_toast("Subscription error: %s" % result.error)


# --- Loading ---

func _show_loading():
	loading_overlay.visible = true


func _hide_loading():
	loading_overlay.visible = false


# --- Toast ---

func _show_toast(message: String):
	if _toast_tween and _toast_tween.is_valid():
		_toast_tween.kill()
	toast_label.text = message
	toast_container.visible = true
	toast_container.modulate.a = 1.0
	_toast_tween = create_tween()
	_toast_tween.tween_interval(2.0)
	_toast_tween.tween_property(toast_container, "modulate:a", 0.0, 0.5)
	_toast_tween.tween_callback(func(): toast_container.visible = false)
