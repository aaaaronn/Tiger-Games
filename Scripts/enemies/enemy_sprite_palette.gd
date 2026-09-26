extends RefCounted

var tinted_textures: Dictionary = {}

func get_tinted_texture(source: Texture2D, tint: Color) -> Texture2D:
	var cache_key := "%d:%s" % [source.get_instance_id(), tint.to_html()]
	if tinted_textures.has(cache_key):
		return tinted_textures[cache_key]
	var image := source.get_image()
	if image.is_empty():
		return source
	var target_hue := tint.h
	for y in image.get_height():
		for x in image.get_width():
			var pixel := image.get_pixel(x, y)
			if pixel.a <= 0.01:
				continue
			var saturation := maxf(pixel.s, 0.72)
			if pixel.v > 0.94 and pixel.s < 0.18:
				saturation = 0.08
			image.set_pixel(x, y, Color.from_hsv(target_hue, saturation, pixel.v, pixel.a))
	var tinted_texture := ImageTexture.create_from_image(image)
	tinted_textures[cache_key] = tinted_texture
	return tinted_texture