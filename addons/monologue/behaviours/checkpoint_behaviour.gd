## Marks where a story can be picked up again. The game reads
## [member MonologueState.checkpoint] and decides whether to offer starting there.
extends MonologueBehaviour


func handles() -> PackedStringArray:
	return ["checkpoint"]


func run(ctx: MonologueContext) -> BehaviourResult:
	ctx.state.checkpoint = ctx.id
	return BehaviourResult.progress(ctx.next())
