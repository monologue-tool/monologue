extends Node

var _cache: Dictionary = {}


func load_thumbnail(image_path: String) -> ImageTexture:
	return _get_thumbnail(image_path)


func load_image(image_path: String) -> ImageTexture:
	return _get_image(image_path)


func _load_image_to_cache(image_path: String) -> void:
	var dir_access: DirAccess = DirAccess.open("")
	if not dir_access.file_exists(image_path):
		return

	var im: Image = Image.load_from_file(image_path)
	if not im:
		printerr("Coundn't load image from path: %s" % image_path)
		im = Image.create_empty(128, 128, false, Image.FORMAT_BPTC_RGBA)
	var thumbnail_im: Image = im.duplicate()
	thumbnail_im.resize(
		128, thumbnail_im.get_size().y * 128 / thumbnail_im.get_size().x, Image.INTERPOLATE_CUBIC
	)

	var tx: ImageTexture = ImageTexture.create_from_image(im)
	var thumbnail_tx: ImageTexture = ImageTexture.create_from_image(thumbnail_im)

	_cache[image_path] = {"raw": tx, "thumbnail_128": thumbnail_tx}


func _get_thumbnail(image_path: String) -> ImageTexture:
	var tx: ImageTexture = ImageTexture.new()

	if _cache.has(image_path):
		tx = _cache[image_path].get("thumbnail_128", tx)
	elif not image_path.is_empty():
		_load_image_to_cache(image_path)
		if _cache.has(image_path):
			tx = _cache[image_path].get("thumbnail_128", tx)

	return tx


func _get_image(image_path: String) -> ImageTexture:
	var tx: ImageTexture = ImageTexture.new()

	if _cache.has(image_path):
		tx = _cache[image_path].get("raw", tx)
	elif not image_path.is_empty():
		_load_image_to_cache(image_path)
		if _cache.has(image_path):
			tx = _cache[image_path].get("raw", tx)

	return tx
