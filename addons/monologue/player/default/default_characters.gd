## Who is on screen, in one of three places.
##
## The three slots and where they sit are the scene's business; everything here only fills
## them. A slot is a place on the stage rather than a person: somebody stepping into one
## takes it from whoever was standing there.
##
## What the story asks for is a picture, a place, and how long to take about it. Arriving and
## leaving are fades, shaped by the easing curve the node names -- there is nothing in the
## data saying where a character would slide in from, so nothing here invents one.
class_name MonologueDefaultCharacters extends MonologueCharacterPart

## How finely a curve is solved before its shape is taken as read. Twelve halvings put the
## answer within a thousandth, which is finer than a fade can be seen.
const CURVE_STEPS: int = 12

@export var left: TextureRect
@export var center: TextureRect
@export var right: TextureRect

## Character id -> the slot they are standing in.
var _standing: Dictionary = {}
## Slot -> the offsets the scene gave it, so that what a node asks for is added to where the
## scene put it rather than replacing it.
var _resting: Dictionary = {}


func _ready() -> void:
	for slot: TextureRect in _slots():
		_resting[slot] = Vector2(slot.offset_left, slot.offset_top)
		slot.texture = null
		slot.modulate.a = 0.0


func apply(character: Dictionary, look: Dictionary) -> void:
	_place(str(character.get("id", "")), look, false)


func leave(character_id: String, duration: float) -> void:
	var slot: TextureRect = _standing.get(character_id)
	if slot == null:
		return

	_standing.erase(character_id)
	_fade(slot, 0.0, duration, [])
	if duration <= 0.0:
		slot.texture = null


## Everyone back where they were, with none of the going there. What a loaded save needs: the
## fades already happened, in a sitting that is over.
func restage(stage: Dictionary) -> void:
	_standing.clear()
	for slot: TextureRect in _slots():
		slot.texture = null
		slot.modulate.a = 0.0

	for character_id: Variant in stage:
		var look: Variant = stage[character_id]
		if look is Dictionary:
			_place(str(character_id), look, true)


func _place(who: String, look: Dictionary, at_once: bool) -> void:
	var slot: TextureRect = _slot_named(str(look.get("position", "Left")))
	if slot == null or who.is_empty():
		return

	for standing: String in _standing.keys():
		if _standing[standing] == slot and standing != who:
			_standing.erase(standing)
	_standing[who] = slot

	slot.texture = MonologueAssets.picture(str(look.get("image", "")))
	slot.flip_h = look.get("flip_h", false) == true
	slot.flip_v = look.get("flip_v", false) == true
	slot.z_index = int(look.get("z_index", 0))

	var offset: Vector2 = look.get("offset", Vector2.ZERO)
	var resting: Vector2 = _resting.get(slot, Vector2.ZERO)
	slot.offset_left = resting.x + offset.x
	slot.offset_top = resting.y + offset.y

	if at_once:
		slot.modulate.a = 1.0
		return
	_fade(slot, 1.0, float(look.get("duration", 0.5)), look.get("curve", []))


func _fade(slot: TextureRect, to: float, duration: float, curve: Variant) -> void:
	if duration <= 0.0:
		slot.modulate.a = to
		return

	var from: float = slot.modulate.a
	var shape: Array = curve if curve is Array else []
	var tween: Tween = create_tween()
	tween.tween_method(
		func(at: float) -> void: slot.modulate.a = lerpf(from, to, _eased(shape, at)),
		0.0,
		1.0,
		duration
	)


func _slots() -> Array[TextureRect]:
	var found: Array[TextureRect] = []
	for slot: TextureRect in [left, center, right]:
		if slot != null:
			found.append(slot)
	return found


func _slot_named(place: String) -> TextureRect:
	match place:
		"Center":
			return center
		"Right":
			return right
	return left


## How far along a curve is at [param at], the curve being the four coordinates of a cubic
## bezier running from (0, 0) to (1, 1) -- the same shape the editor draws.
##
## Solved rather than evaluated: the curve says y for a given x, and x is not the parameter.
static func _eased(curve: Array, at: float) -> float:
	if curve.size() < 4:
		return at

	var low: float = 0.0
	var high: float = 1.0
	for _step: int in CURVE_STEPS:
		var middle: float = (low + high) * 0.5
		if _axis(float(curve[0]), float(curve[2]), middle) < at:
			low = middle
		else:
			high = middle

	return _axis(float(curve[1]), float(curve[3]), (low + high) * 0.5)


## One axis of a cubic bezier whose two ends are 0 and 1.
static func _axis(first: float, second: float, at: float) -> float:
	var rest: float = 1.0 - at
	return 3.0 * rest * rest * at * first + 3.0 * rest * at * at * second + at * at * at
