extends MonologueBehaviour


func handles() -> PackedStringArray:
	return ["sentence"]


func run(ctx: MonologueContext) -> BehaviourResult:
	var speaker: Dictionary = ctx.graph.record("characters", str(ctx.value("speaker", "")))
	var line: String = ctx.text("line")

	var named: String = _name_of(ctx, speaker)
	ctx.player.say(
		line if not line.is_empty() else "[i][Empty line][/i]",
		named,
		Color(str(speaker.get("color", "#ffffff"))),
		str(ctx.value("voiceline", ""))
	)

	# Duck-typed like every service, so a game with no backlog pays nothing for this.
	var history: Object = ctx.service("history")
	if history and history.has_method(&"record"):
		history.call(&"record", line, named, ctx.id)
	return BehaviourResult.wait()


func input(ctx: MonologueContext) -> BehaviourResult:
	return BehaviourResult.progress(ctx.next())


static func _name_of(ctx: MonologueContext, speaker: Dictionary) -> String:
	var shown: String = ctx.text("display_name")
	if shown.is_empty():
		shown = ctx.label(speaker.get("display_name"))
	return shown if not shown.is_empty() else str(speaker.get("name", ""))
