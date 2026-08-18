## Moves the story to a place, and shows that place when the node says to.
##
## The picture goes in the slot a background node uses, because it is the same thing on
## screen: whichever ran last is what is behind everyone, and one slot means one of them puts
## it back after a save instead of both.
extends MonologueBehaviour

const SLOT: String = "location"
const BACKDROP_SLOT: String = "background"


func handles() -> PackedStringArray:
	return ["location"]


func run(ctx: MonologueContext) -> BehaviourResult:
	var target: String = str(ctx.value("target", ""))
	var place: Dictionary = ctx.graph.record("locations", target)
	if place.is_empty():
		ctx.note(&"location_without_place", "This node names nowhere to move to.")
		return BehaviourResult.progress(ctx.next())

	var variation: Dictionary = ctx.pick(
		place.get("variations", []), str(ctx.value("variation", ""))
	)
	ctx.state.stage[SLOT] = {
		"location": target,
		"variation": str(variation.get("id", "")),
	}

	if ctx.value("show_image", true) == true:
		_show(ctx, str(variation.get("image", "")))

	return BehaviourResult.progress(ctx.next())


func _show(ctx: MonologueContext, image: String) -> void:
	if image.is_empty():
		ctx.note(&"location_without_image", "This place has no picture to show.")
		return

	ctx.state.stage[BACKDROP_SLOT] = image
	if ctx.player.scenery:
		ctx.player.scenery.show_image(ctx.player.resolve(image))
