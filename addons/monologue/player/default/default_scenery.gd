## What is behind everyone.
##
## Crossfades rather than cutting: two pictures of the same place swapped outright read as a
## glitch, and the story rarely means one.
class_name MonologueDefaultScenery extends MonologueSceneryPart

## How long one place takes to become another.
const FADE: float = 0.35

## What is on screen now, and what is arriving over it. They trade places once a fade lands,
## so neither is the permanent one.
@export var showing: TextureRect
@export var arriving: TextureRect

var _showing: String = ""
var _fade: Tween


func show_image(path: String) -> void:
	if path == _showing or showing == null or arriving == null:
		return
	_showing = path

	if _fade and _fade.is_valid():
		_fade.kill()

	arriving.texture = MonologueAssets.picture(path)
	arriving.modulate.a = 0.0

	_fade = create_tween()
	_fade.tween_property(arriving, "modulate:a", 1.0, FADE)
	_fade.tween_callback(_settle)


## The picture that arrived becomes the one on screen, and the layer it came in on is emptied
## ready for the next. Without this the two would swap roles every time and only one of them
## would ever be underneath.
func _settle() -> void:
	showing.texture = arriving.texture
	showing.modulate.a = 1.0
	arriving.texture = null
	arriving.modulate.a = 0.0
