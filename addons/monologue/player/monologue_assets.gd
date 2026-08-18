## The pictures and sounds a story names, loaded however they happen to be stored.
##
## A story's art usually lives beside the story rather than inside the game, so [ResourceLoader]
## is not enough on its own: it reads what an export imported and knows nothing of a file
## sitting next to the save. Both are tried, in that order, and what comes back is kept --
## a portrait is shown again every time its character speaks.
class_name MonologueAssets

## Extension -> the stream class that can read it off disk. Named rather than referenced:
## which of them can, and since when, is the engine's business and is asked at the time.
const AUDIO_READERS: Dictionary = {
	"ogg": "AudioStreamOggVorbis",
	"mp3": "AudioStreamMP3",
	"wav": "AudioStreamWAV",
}

static var _pictures: Dictionary = {}
static var _sounds: Dictionary = {}


## The picture at [param path], or null when there is nothing readable there. Asking twice
## costs nothing.
static func picture(path: String) -> Texture2D:
	if path.is_empty():
		return null
	if _pictures.has(path):
		return _pictures[path]

	var texture: Texture2D = _imported(path) as Texture2D
	if texture == null and FileAccess.file_exists(path):
		var image: Image = Image.load_from_file(path)
		if image != null and not image.is_empty():
			texture = ImageTexture.create_from_image(image)

	_pictures[path] = texture
	return texture


static func sound(path: String) -> AudioStream:
	if path.is_empty():
		return null
	if _sounds.has(path):
		return _sounds[path]

	var stream: AudioStream = _imported(path) as AudioStream
	if stream == null:
		stream = _loose_sound(path)

	_sounds[path] = stream
	return stream


## Whether a stream comes back to its beginning, said in the one way each kind of stream
## understands it.
static func set_looping(stream: AudioStream, looping: bool) -> void:
	if stream is AudioStreamWAV:
		(stream as AudioStreamWAV).loop_mode = (
			AudioStreamWAV.LOOP_FORWARD if looping else AudioStreamWAV.LOOP_DISABLED
		)
	elif "loop" in stream:
		stream.set("loop", looping)


## Lets go of everything kept. What a game calls when a story ends and its art is no longer
## worth the memory it is holding.
static func forget() -> void:
	_pictures.clear()
	_sounds.clear()


static func _imported(path: String) -> Resource:
	return ResourceLoader.load(path) if ResourceLoader.exists(path) else null


## A file the game never imported, read as it sits on disk. Not every kind can be: a format
## with no reader reads as nothing rather than as an error nobody can act on.
static func _loose_sound(path: String) -> AudioStream:
	if not FileAccess.file_exists(path):
		return null

	var reader: String = str(AUDIO_READERS.get(path.get_extension().to_lower(), ""))
	if reader.is_empty() or not ClassDB.class_has_method(reader, &"load_from_file", true):
		return null
	return ClassDB.class_call_static(reader, &"load_from_file", path) as AudioStream
