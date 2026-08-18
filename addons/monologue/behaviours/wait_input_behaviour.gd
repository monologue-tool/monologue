## Holds the story until the reader moves on, without putting anything new on screen.
extends MonologueBehaviour


func handles() -> PackedStringArray:
	return ["wait_input"]


func run(ctx: MonologueContext) -> BehaviourResult:
	# Cleared first: clearing takes back whatever was outstanding, so asking after is the
	# only order that leaves a question standing.
	if ctx.value("hide_text_box", false) == true:
		ctx.player.clear()

	ctx.player.acknowledge()
	return BehaviourResult.wait()


func input(ctx: MonologueContext) -> BehaviourResult:
	return BehaviourResult.progress(ctx.next())
