## Runs a section, then carries the story on from wherever that section ran out.
##
## Entered twice: once going in, once coming back. The second is told from the first by
## [member MonologueState.ran_out_at], which the session fills in as it unwinds.
extends MonologueBehaviour

## Named here, so endless recursion does not read as the story going round in circles.
const MAX_DEPTH: int = 64


func handles() -> PackedStringArray:
	return ["section"]


func run(ctx: MonologueContext) -> BehaviourResult:
	var came_back_from: String = ctx.state.ran_out_at
	if not came_back_from.is_empty():
		ctx.state.ran_out_at = ""
		# One exit per place the section stops, each keyed by the node it stopped at.
		return BehaviourResult.progress(
			ctx.next("exits", MonologueStoryGraph.EXTERNAL_PREFIX + came_back_from)
		)

	var target: String = str(ctx.value("target", ""))
	if target.is_empty():
		ctx.note(&"section_without_target", "This node names no section.")
		return BehaviourResult.progress(ctx.next())

	var entry: String = ctx.graph.entry_of(target)
	if entry.is_empty():
		ctx.fault(&"unknown_section", "The section this runs is gone.")
		return BehaviourResult.stop()

	if ctx.state.call_stack.size() >= MAX_DEPTH:
		ctx.fault(
			&"section_too_deep", "%d sections deep; a section is running itself." % MAX_DEPTH
		)
		return BehaviourResult.stop()

	ctx.state.call_stack.append(ctx.id)
	return BehaviourResult.progress(entry)
