extends MonologueBehaviour


func handles() -> PackedStringArray:
	return ["end"]


func run(ctx: MonologueContext) -> BehaviourResult:
	ctx.player.hide()
	return BehaviourResult.stop()
