## Runs a function, then carries the story on from wherever that function ran out.
##
## Entered twice: once going in, once coming back. The second is told from the first by
## [member MonologueState.ran_out_at], which the session fills in as it unwinds.
extends MonologueBehaviour

## Functions calling each other without end is an authoring mistake worth naming, rather
## than one the loop guard reports as a story going round in circles.
const MAX_DEPTH: int = 64


func handles() -> PackedStringArray:
	return ["call"]


func run(ctx: MonologueContext) -> BehaviourResult:
	var came_back_from: String = ctx.state.ran_out_at
	if not came_back_from.is_empty():
		ctx.state.ran_out_at = ""
		# One exit per place the function stops, each keyed by the node it stopped at.
		return BehaviourResult.progress(
			ctx.next("exits", MonologueStoryGraph.EXTERNAL_PREFIX + came_back_from)
		)

	var target: String = str(ctx.value("target", ""))
	if target.is_empty():
		ctx.note(&"call_without_target", "This call names no function.")
		return BehaviourResult.progress(ctx.next())

	if not ctx.graph.has_node(target):
		ctx.fault(&"unknown_function", "The function this calls is gone.")
		return BehaviourResult.stop()

	if ctx.state.call_stack.size() >= MAX_DEPTH:
		ctx.fault(&"call_too_deep", "%d calls deep; a function is calling itself." % MAX_DEPTH)
		return BehaviourResult.stop()

	ctx.state.call_stack.append(ctx.id)
	return BehaviourResult.progress(target)
