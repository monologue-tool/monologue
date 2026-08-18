## Remembers the image, so a restored save does not come back to an empty stage.
extends MonologueBehaviour

const SLOT: String = "background"


func handles() -> PackedStringArray:
	return ["background"]


## Rebuilds the stage after a save is put back, without replaying the story.
func setup(ctx: MonologueContext) -> void:
	var kept: String = str(ctx.state.stage.get(SLOT, ""))
	if not kept.is_empty():
		_show(ctx, kept)


func run(ctx: MonologueContext) -> BehaviourResult:
	var image: String = str(ctx.value("image", ""))
	if image.is_empty():
		ctx.note(&"background_without_image", "This node names no image.")
		return BehaviourResult.progress(ctx.next())

	ctx.state.stage[SLOT] = image
	_show(ctx, image)
	return BehaviourResult.progress(ctx.next())


func _show(ctx: MonologueContext, image: String) -> void:
	if ctx.player.scenery:
		ctx.player.scenery.show_image(ctx.player.resolve(image))
