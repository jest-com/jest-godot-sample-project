class_name JestUtils
extends RefCounted

const _CLOUDFLARE_IMAGE_PROXY := "https://cdn.jestpub.com/cdn-cgi/image/"
const _BOT_AVATAR_BASE_URL := "https://cdn.jest.com/avatars/bot/"
const _AVAILABLE_AVATARS := 1000
const _U32_MASK := 0xFFFFFFFF


## Returns a CDN URL for a bot avatar deterministically seeded by [param username].
## [param size] must be one of 64, 128, 256, 512, or 1000 (defaults to 1000); other
## values are bucketed down to the next supported size.
static func get_bot_avatar(username: String, size: int = 1000) -> String:
	var bucketed := _bucket_bot_avatar_size(size)
	var rand := _seed_random_first(username)
	var index := int(floor(rand * _AVAILABLE_AVATARS))
	var bot_url := "%s%d.webp" % [_BOT_AVATAR_BASE_URL, index]
	if bucketed >= _AVAILABLE_AVATARS:
		return bot_url
	return _build_cloudflare_image_url(bot_url, bucketed)


## Wraps a raw player avatar URL through the Cloudflare image proxy at the given
## [param size]. Used by [JestSocial.get_player_avatar] to return a URL that
## avoids AVIF negotiation in Godot. Returns an empty string
## when [param avatar_url] is empty, and the URL unchanged when it points at
## localhost (Cloudflare can't fetch those in dev).
static func get_player_avatar(avatar_url: String, size: int = 1000) -> String:
	if avatar_url.is_empty():
		return ""
	if avatar_url.begins_with("http://localhost") or avatar_url.begins_with("https://localhost"):
		return avatar_url
	return _build_cloudflare_image_url(avatar_url, _bucket_bot_avatar_size(size))


static func _bucket_bot_avatar_size(size: int) -> int:
	if size >= 1000: return 1000
	if size >= 512: return 512
	if size >= 256: return 256
	if size >= 128: return 128
	return 64


# Computes the first sfc32 PRNG output seeded with cyrb128(username), in [0, 1).
# Bit-compatible with the JS implementation in @textclub/common/prng so all SDKs
# return the same avatar for the same username.
static func _seed_random_first(seed: String) -> float:
	var h1: int = 1779033703
	var h2: int = 3144134277
	var h3: int = 1013904242
	var h4: int = 2773480762
	for k in _to_utf16_units(seed):
		h1 = (h2 ^ (((h1 ^ k) * 597399067) & _U32_MASK)) & _U32_MASK
		h2 = (h3 ^ (((h2 ^ k) * 2869860233) & _U32_MASK)) & _U32_MASK
		h3 = (h4 ^ (((h3 ^ k) * 951274213) & _U32_MASK)) & _U32_MASK
		h4 = (h1 ^ (((h4 ^ k) * 2716044179) & _U32_MASK)) & _U32_MASK
	h1 = ((h3 ^ (h1 >> 18)) * 597399067) & _U32_MASK
	h2 = ((h4 ^ (h2 >> 22)) * 2869860233) & _U32_MASK
	h3 = ((h1 ^ (h3 >> 17)) * 951274213) & _U32_MASK
	h4 = ((h2 ^ (h4 >> 19)) * 2716044179) & _U32_MASK
	h1 = (h1 ^ h2 ^ h3 ^ h4) & _U32_MASK
	h2 = (h2 ^ h1) & _U32_MASK
	h3 = (h3 ^ h1) & _U32_MASK
	h4 = (h4 ^ h1) & _U32_MASK
	var t: int = (((h1 + h2) & _U32_MASK) + h4) & _U32_MASK
	return float(t) / 4294967296.0


# Converts a string to UTF-16 code units, matching JS String.charCodeAt.
# Supplementary plane code points are split into surrogate pairs.
static func _to_utf16_units(s: String) -> PackedInt32Array:
	var out := PackedInt32Array()
	for i in range(s.length()):
		var cp: int = s.unicode_at(i)
		if cp < 0x10000:
			out.append(cp)
		else:
			cp -= 0x10000
			out.append(0xD800 | (cp >> 10))
			out.append(0xDC00 | (cp & 0x3FF))
	return out


static func _build_cloudflare_image_url(image_url: String, width: int) -> String:
	return "%sformat=webp%%2Cfit=cover%%2Cwidth=%d%%2C/%s" % [
		_CLOUDFLARE_IMAGE_PROXY,
		width,
		image_url.uri_encode(),
	]


## Parses a JSON string and returns the result, or the provided default if parsing fails.
static func parse_json(json_str: String, default: Variant = null) -> Variant:
	if json_str.is_empty():
		return default
	var result = JSON.parse_string(json_str)
	if result == null:
		return default
	return result


## Parses a JSON string and returns it as Dictionary, or the provided default.
static func parse_json_dict(json_str: String, default: Dictionary = {}) -> Dictionary:
	var result = parse_json(json_str)
	if result is Dictionary:
		return result
	return default


## Parses a JSON string and returns it as Array, or the provided default.
static func parse_json_array(json_str: String, default: Array = []) -> Array:
	var result = parse_json(json_str)
	if result is Array:
		return result
	return default
