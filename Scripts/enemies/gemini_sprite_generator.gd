extends Node

signal generation_completed(textures: Array[Texture2D])
signal generation_failed(message: String)

const MODEL_ENDPOINT := "https://generativelanguage.googleapis.com/v1beta/models/gemini-3.1-flash-image:generateContent"
const OUTPUT_DIRECTORY := "user://enemy_sprites"

var descriptions: Array[String] = []
var api_key := ""
var current_tier := 0
var generated_textures: Array[Texture2D] = []
var image_request: HTTPRequest

func _ready() -> void:
	image_request = HTTPRequest.new()
	image_request.timeout = 120.0
	add_child(image_request)
	image_request.request_completed.connect(_on_request_completed)

func generate_enemy_sprites(enemy_descriptions: Array[String], key: String) -> void:
	if image_request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		generation_failed.emit("A Gemini image request is already in progress.")
		return
	if enemy_descriptions.size() != 3 or key.is_empty():
		generation_failed.emit("Three enemy descriptions and a Gemini API key are required.")
		return
	descriptions = enemy_descriptions.duplicate()
	api_key = key
	current_tier = 0
	generated_textures.clear()
	_request_current_tier()

func _request_current_tier() -> void:
	var tier_number := current_tier + 1
	var prompt := """Create one original 2D game enemy sprite for a top-down survival game.
Enemy concept: %s
Strength tier: %d of 3.
Use a consistent polished hand-painted pixel-art style, bold readable silhouette, centered full-body creature, transparent background, no text, no border, no extra objects. The creature must fill most of a square canvas and be clearly distinct at small size.""" % [descriptions[current_tier], tier_number]
	var payload := {
		"contents": [{"parts": [{"text": prompt}]}],
		"generationConfig": {
			"responseModalities": ["IMAGE"],
			"imageConfig": {"aspectRatio": "1:1", "imageSize": "512"}
		}
	}
	var headers := PackedStringArray([
		"Content-Type: application/json",
		"x-goog-api-key: " + api_key
	])
	var error := image_request.request(MODEL_ENDPOINT, headers, HTTPClient.METHOD_POST, JSON.stringify(payload))
	if error != OK:
		_fail("Could not start Gemini request (%s)." % error_string(error))

func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS:
		_fail("Gemini request failed with network result %d." % result)
		return
	if response_code < 200 or response_code >= 300:
		_fail("Gemini returned HTTP %d. Check the API key, quota, and model access." % response_code)
		return
	var response: Variant = JSON.parse_string(body.get_string_from_utf8())
	if not response is Dictionary:
		_fail("Gemini returned an unreadable response.")
		return
	var candidates: Array = response.get("candidates", [])
	if candidates.is_empty():
		_fail("Gemini did not return an image for tier %d." % (current_tier + 1))
		return
	var content: Dictionary = candidates[0].get("content", {})
	var parts: Array = content.get("parts", [])
	for part in parts:
		var inline_data: Dictionary = part.get("inlineData", part.get("inline_data", {}))
		if inline_data.is_empty():
			continue
		var image_bytes := Marshalls.base64_to_raw(inline_data.get("data", ""))
		var mime_type: String = inline_data.get("mimeType", inline_data.get("mime_type", "image/jpeg"))
		var texture := _texture_from_bytes(image_bytes, mime_type)
		if texture == null:
			_fail("Gemini returned an unsupported or invalid image for tier %d." % (current_tier + 1))
			return
		if not _save_texture_image(texture, current_tier + 1):
			_fail("Could not save the generated enemy sprites to user data.")
			return
		generated_textures.append(texture)
		current_tier += 1
		if current_tier == 3:
			api_key = ""
			generation_completed.emit(generated_textures.duplicate())
		else:
			_request_current_tier()
		return
	_fail("Gemini response for tier %d contained no image data." % (current_tier + 1))

func _texture_from_bytes(image_bytes: PackedByteArray, mime_type: String) -> Texture2D:
	var image := Image.new()
	var error: Error
	match mime_type:
		"image/png":
			error = image.load_png_from_buffer(image_bytes)
		"image/jpeg", "image/jpg":
			error = image.load_jpg_from_buffer(image_bytes)
		"image/webp":
			error = image.load_webp_from_buffer(image_bytes)
		_:
			return null
	if error != OK:
		return null
	return ImageTexture.create_from_image(image)

func _save_texture_image(texture: Texture2D, tier_number: int) -> bool:
	var directory_path := ProjectSettings.globalize_path(OUTPUT_DIRECTORY)
	if DirAccess.make_dir_recursive_absolute(directory_path) != OK and not DirAccess.dir_exists_absolute(directory_path):
		return false
	var image := texture.get_image()
	return image.save_png("%s/tier_%d.png" % [OUTPUT_DIRECTORY, tier_number]) == OK

func _fail(message: String) -> void:
	api_key = ""
	generated_textures.clear()
	generation_failed.emit(message)