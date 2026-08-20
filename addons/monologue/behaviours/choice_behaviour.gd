extends MonologueBehaviour


func handles() -> PackedStringArray:
	return ["choice"]


func run(ctx: MonologueContext) -> BehaviourResult:
	var offered: Array[Dictionary] = _offered(ctx)
	if offered.is_empty():
		ctx.note(&"nothing_to_offer", "Every option was spent or switched off.")
		return BehaviourResult.progress(ctx.next())

	ctx.player.offer(offered)
	return BehaviourResult.wait()


## The item id on the wire is the option's own, which is what makes an answer a route.
func input(ctx: MonologueContext) -> BehaviourResult:
	var picked: String = ctx.player.picked
	var option: Dictionary = _option(ctx, picked)
	if option.get("one_shot", false) == true:
		ctx.state.consume(ctx.id, picked)

	# What was chosen belongs in the backlog as much as what was said. Reading a run back
	# without it shows the story taking turns nobody can account for.
	var history: Object = ctx.service("history")
	if history and history.has_method(&"record"):
		history.call(&"record", ctx.label(option.get("text")), "", ctx.id)
	return BehaviourResult.progress(ctx.next("choices", picked))


## A key to answer with, and text already in the right language. The part only draws them.
func _offered(ctx: MonologueContext) -> Array[Dictionary]:
	var offered: Array[Dictionary] = []
	for option: Dictionary in ctx.items("choices"):
		var key: String = str(option.get("id", ""))
		if key.is_empty() or option.get("enabled", true) != true:
			continue
		if ctx.state.is_consumed(ctx.id, key):
			continue
		if option.get("enable_condition", false) == true and not ctx.test(option.get("condition")):
			continue

		var text: String = ctx.label(option.get("text"))
		offered.append({
			"key": key,
			"text": text if not text.is_empty() else "[Empty option]",
			"speaker": str(option.get("speaker", "")),
			"one_shot": option.get("one_shot", false) == true,
		})
	return offered


func _option(ctx: MonologueContext, key: String) -> Dictionary:
	for option: Dictionary in ctx.items("choices"):
		if str(option.get("id", "")) == key:
			return option
	return {}
