## Hands the game a name and whatever goes with it. Monologue reads neither.
extends MonologueBehaviour


func handles() -> PackedStringArray:
	return ["action"]


func run(ctx: MonologueContext) -> BehaviourResult:
	# Plain rather than translated: this names something in the game's code, not to a reader.
	var action_name: String = str(ctx.value("name", "")).strip_edges()
	if action_name.is_empty():
		ctx.note(&"action_without_name", "This node asks the game for nothing.")
		return BehaviourResult.progress(ctx.next())

	var arguments: Variant = ctx.value("arguments", [])
	ctx.player.act(action_name, arguments if arguments is Array else [])
	return BehaviourResult.progress(ctx.next())
