## Asks the reader for text and keeps it in a variable.
extends MonologueBehaviour


func handles() -> PackedStringArray:
	return ["input"]


func run(ctx: MonologueContext) -> BehaviourResult:
	ctx.player.ask(
		ctx.text("text"), ctx.text("placeholder"), ctx.value("allow_empty", false) == true
	)
	return BehaviourResult.wait()


func input(ctx: MonologueContext) -> BehaviourResult:
	var target: String = str(ctx.value("variable", ""))
	if target.is_empty():
		ctx.note(&"input_without_variable", "What was typed had nowhere to go.")
	else:
		ctx.set_var(target, ctx.player.answer)
	return BehaviourResult.progress(ctx.next())
