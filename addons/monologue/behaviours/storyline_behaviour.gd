## Leaves this storyline for another, at that one's own beginning.
extends MonologueBehaviour


func handles() -> PackedStringArray:
	return ["storyline"]


func run(ctx: MonologueContext) -> BehaviourResult:
	var entry: String = ctx.graph.entry_of(str(ctx.value("target", "")))
	if entry.is_empty():
		ctx.fault(&"unknown_storyline", "There is no storyline to continue into.")
		return BehaviourResult.stop()

	# A departure, not a detour. Whatever was waiting to be returned to belongs to the
	# storyline being left, and coming back to it would land the reader where they are not.
	ctx.state.call_stack.clear()
	return BehaviourResult.progress(entry)
