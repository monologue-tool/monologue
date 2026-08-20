## Continues inside a section, with nowhere to come back to.
##
## Nothing is pushed and nothing is dropped, so a jump made inside a section still unwinds
## to whatever ran it.
extends MonologueBehaviour


func handles() -> PackedStringArray:
	return ["jump"]


func run(ctx: MonologueContext) -> BehaviourResult:
	var target: String = str(ctx.value("target", ""))
	if target.is_empty():
		ctx.fault(&"jump_without_target", "This jump names no section.")
		return BehaviourResult.stop()

	var entry: String = ctx.graph.entry_of(target)
	if entry.is_empty():
		ctx.fault(&"unknown_section", "The section this jumps to is gone.")
		return BehaviourResult.stop()

	return BehaviourResult.progress(entry)
