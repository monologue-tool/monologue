## Hands the game a name and whatever goes with it. Monologue reads neither.
##
## Told to wait, it holds the story until the game answers and keeps that answer in the
## variable the node names.
extends MonologueBehaviour


func handles() -> PackedStringArray:
	return ["action"]


func run(ctx: MonologueContext) -> BehaviourResult:
	# Plain and not translated. This names something in the game's code.
	var action_name: String = str(ctx.value("name", "")).strip_edges()
	if action_name.is_empty():
		ctx.note(&"action_without_name", "This node asks the game for nothing.")
		return BehaviourResult.progress(ctx.next())

	var arguments: Variant = ctx.value("arguments", [])
	var passed: Array = arguments if arguments is Array else []

	if ctx.value("wait", false) == true:
		ctx.player.await_act(action_name, passed)
		return BehaviourResult.wait()

	_keep(ctx, ctx.player.act(action_name, passed))
	return BehaviourResult.progress(ctx.next())


func input(ctx: MonologueContext) -> BehaviourResult:
	_keep(ctx, ctx.player.action_result())
	return BehaviourResult.progress(ctx.next())


## A node naming no variable drops what came back.
func _keep(ctx: MonologueContext, result: Variant) -> void:
	var target: String = str(ctx.value("result", ""))
	if target.is_empty() or result == null:
		return
	ctx.set_var(target, result)
