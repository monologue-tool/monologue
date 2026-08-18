## Brings a character on stage, takes them off, or changes how they are shown, and keeps the
## stage in the state so a restored save comes back to the same picture.
extends MonologueBehaviour

const SLOT: String = "characters"
const LEAVING: String = "Leave"
## What an ease falls back to when the project names none of its own.
const DEFAULT_EASE: Array = [0.25, 0.1, 0.25, 1.0]


func handles() -> PackedStringArray:
	return ["character"]


## Called again after a save is put back, which is when the stage has to be rebuilt without
## replaying the story that filled it.
func setup(ctx: MonologueContext) -> void:
	if ctx.player.characters:
		var staged: Dictionary = ctx.state.stage.get(SLOT, {})
		ctx.player.characters.restage(staged)


func run(ctx: MonologueContext) -> BehaviourResult:
	var who: String = str(ctx.value("who", ""))
	if who.is_empty():
		ctx.note(&"character_without_who", "This node names nobody.")
		return BehaviourResult.progress(ctx.next())

	var staged: Dictionary = ctx.state.stage.get_or_add(SLOT, {})
	var duration: float = float(ctx.value("duration", 0.5))

	if str(ctx.value("action", "Join")) == LEAVING:
		staged.erase(who)
		if ctx.player.characters:
			ctx.player.characters.leave(who, duration)
		return BehaviourResult.progress(ctx.next())

	var look: Dictionary = _look(ctx, who, duration)
	staged[who] = look
	if ctx.player.characters:
		ctx.player.characters.apply(ctx.graph.record("characters", who), look)
	return BehaviourResult.progress(ctx.next())


## Everything the part needs to draw, resolved here rather than there: a part is handed a
## portrait and a curve, never an id it would have to go looking up.
func _look(ctx: MonologueContext, who: String, duration: float) -> Dictionary:
	var portraits: Variant = ctx.graph.record("characters", who).get("portraits", [])
	return {
		"portrait": ctx.pick(portraits, str(ctx.value("portrait", ""))),
		"position": str(ctx.value("position", "Left")),
		"z_index": int(ctx.value("z_index", 0)),
		"flip_h": bool(ctx.value("flip_h", false)),
		"flip_v": bool(ctx.value("flip_v", false)),
		"offset": _vector(ctx.value("offset")),
		"duration": duration,
		"curve": _curve(ctx, str(ctx.value("curve", ""))),
	}


## The named ease, or the project's default one, as its four coordinates.
func _curve(ctx: MonologueContext, chosen: String) -> Array:
	var record: Dictionary = ctx.graph.record("eases", chosen)
	if record.is_empty():
		record = _default_ease(ctx)

	var coordinates: Variant = record.get("ease")
	if coordinates is Array and (coordinates as Array).size() >= 4:
		return coordinates as Array
	return DEFAULT_EASE


func _default_ease(ctx: MonologueContext) -> Dictionary:
	var eases: Dictionary = ctx.graph.collections.get("eases", {})
	for record: Variant in eases.values():
		if record is Dictionary and record.get("is_default") == true:
			return record
	return {}


## A vector2 property is stored as its two numbers, which is not what anyone wants to draw with.
func _vector(stored: Variant) -> Vector2:
	if stored is Vector2:
		return stored
	if stored is Array and (stored as Array).size() >= 2:
		return Vector2(float(stored[0]), float(stored[1]))
	return Vector2.ZERO
