@tool
extends EditorPlugin

const AUTOLOAD_NAME = "JestSDK"
const AUTOLOAD_PATH = "res://addons/jest_sdk/jest_sdk.gd"
const JESTSDK_CDN_URL = "https://cdn.jest.com/sdk/latest/jestsdk.js"
const PLUGIN_CFG_PATH = "res://addons/jest_sdk/plugin.cfg"

var _export_plugin: JestExportPlugin


func _enter_tree() -> void:
	add_autoload_singleton(AUTOLOAD_NAME, AUTOLOAD_PATH)
	_export_plugin = JestExportPlugin.new()
	add_export_plugin(_export_plugin)


func _exit_tree() -> void:
	remove_autoload_singleton(AUTOLOAD_NAME)
	remove_export_plugin(_export_plugin)
	_export_plugin = null


class JestExportPlugin extends EditorExportPlugin:
	var _export_path: String = ""

	func _get_name() -> String:
		return "JestSDK"

	func _export_begin(features: PackedStringArray, is_debug: bool, path: String, flags: int) -> void:
		_export_path = path

	func _export_end() -> void:
		if _export_path.is_empty():
			return

		# Only post-process HTML files (web exports)
		if not _export_path.ends_with(".html"):
			_export_path = ""
			return

		var html_path := ProjectSettings.globalize_path(_export_path)

		# Read the exported HTML
		var html_file := FileAccess.open(_export_path, FileAccess.READ)
		if html_file == null:
			push_warning("[JestSDK] Could not read exported HTML at %s" % _export_path)
			_export_path = ""
			return
		var html_content := html_file.get_as_text()
		html_file.close()

		# Validate HTML structure
		if html_content.find("<head>") == -1:
			push_warning("[JestSDK] Exported HTML is missing <head> tag. SDK may not work correctly.")
		var insert_pos := html_content.find("</head>")
		if insert_pos == -1:
			push_warning("[JestSDK] Could not find </head> in exported HTML. Cannot inject SDK.")
			_export_path = ""
			return

		# Read plugin version from plugin.cfg
		var sdk_version := "unknown"
		var cfg := ConfigFile.new()
		if cfg.load(PLUGIN_CFG_PATH) == OK:
			sdk_version = cfg.get_value("plugin", "version", "unknown")

		# Helper bridge: GDScript's Object.set()/get() shadows JS method calls on
		# JavaScriptObject, so we expose data methods under collision-free names.
		# Also patches sdkVersion on outgoing messages (jestsdk.js ships with "unknown").
		var helper_js := """
window.__jestDataHelper = {
	getValue: function(k) { return window.JestSDK.data.get(k); },
	setValue: function(k, v) { window.JestSDK.data.set(k, v); },
	deleteValue: function(k) { window.JestSDK.data.delete(k); },
	getAll: function() { return window.JestSDK.data.getAll(); },
	flush: function() { return window.JestSDK.data.flush(); }
};
(function() {
	var origPostMessage = window.parent.postMessage.bind(window.parent);
	window.parent.postMessage = function(msg, target) {
		if (msg && msg.source_channel === 'textclub' && msg.sdkVersion === 'unknown') {
			msg.sdkVersion = 'godot-sdk-%s';
		}
		return origPostMessage(msg, target);
	};
})();
""" % sdk_version

		# Inject the SDK script + helper into <head> — right before </head>
		var script_tag := "\n<!-- Jest SDK -->\n<script src=\"" + JESTSDK_CDN_URL + "\"></script>\n<script>\n" + helper_js + "\n</script>\n"
		var modified_html := html_content.substr(0, insert_pos) + script_tag + html_content.substr(insert_pos)

		# Verify injection
		if modified_html.find("JestSDK") == -1:
			push_warning("[JestSDK] SDK injection may have failed — JestSDK not found in output HTML.")

		# Write the modified HTML back
		var out_file := FileAccess.open(_export_path, FileAccess.WRITE)
		if out_file == null:
			push_warning("[JestSDK] Could not write modified HTML")
			_export_path = ""
			return
		out_file.store_string(modified_html)
		out_file.close()

		print("[JestSDK] Injected jestsdk.js into exported HTML: %s" % html_path)
		_export_path = ""
