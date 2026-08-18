## Runs a node nothing else claims, including a type this runtime has never heard of, so a
## story walks past what it does not recognise instead of stalling on it.
class_name MonologuePathThroughBehaviour extends MonologueBehaviour


func handles() -> PackedStringArray:
	return []


func run(ctx: MonologueContext) -> BehaviourResult:
	return BehaviourResult.progress(ctx.next())
