## Image loading and caching singleton.
##
## Provides efficient image loading with automatic caching and thumbnail generation.
## Images are loaded once and stored in memory to avoid repeated disk access.
extends Node

## Internal cache storing loaded images and their thumbnails.
## Keys are image file paths, values are dictionaries with "raw" and "thumbnail_128" entries.
var _cache: Dictionary = {}


## Loads and returns a thumbnail version of an image.
##
## Returns a cached 128px wide thumbnail if available, otherwise loads and caches it.
## [br][br]
## [param image_path] The file system path to the image file.
## [br][br]
## Returns an ImageTexture of the thumbnail, or an empty texture if loading fails.
func load_thumbnail(image_path: String) -> ImageTexture:
	return _get_thumbnail(image_path)


## Loads and returns the full-size image.
##
## Returns a cached full-resolution image if available, otherwise loads and caches it.
## [br][br]
## [param image_path] The file system path to the image file.
## [br][br]
## Returns an ImageTexture of the image, or an empty texture if loading fails.
func load_image(image_path: String) -> ImageTexture:
	return _get_image(image_path)


## Loads an image from disk and stores both full and thumbnail versions in cache.
##
## Creates a 128px wide thumbnail using cubic interpolation. If the image fails to load,
## creates a placeholder 128x128 image instead.
## [br][br]
## [param image_path] The file system path to the image file.
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


## Internal method to retrieve or load a thumbnail from cache.
func _get_thumbnail(image_path: String) -> ImageTexture:
	var tx: ImageTexture = ImageTexture.new()

	if _cache.has(image_path):
		tx = _cache[image_path].get("thumbnail_128", tx)
	elif not image_path.is_empty():
		_load_image_to_cache(image_path)
		if _cache.has(image_path):
			tx = _cache[image_path].get("thumbnail_128", tx)

	return tx


## Internal method to retrieve or load a full-size image from cache.
func _get_image(image_path: String) -> ImageTexture:
	var tx: ImageTexture = ImageTexture.new()

	if _cache.has(image_path):
		tx = _cache[image_path].get("raw", tx)
	elif not image_path.is_empty():
		_load_image_to_cache(image_path)
		if _cache.has(image_path):
			tx = _cache[image_path].get("raw", tx)

	return tx
