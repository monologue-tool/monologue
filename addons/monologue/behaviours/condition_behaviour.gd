## Leaves by one of two ports depending on what the test says.
extends MonologueBehaviour


func handles() -> PackedStringArray:
	return ["condition"]


func run(ctx: MonologueContext) -> BehaviourResult:
	var port: String = "pass" if ctx.test(ctx.value("test")) else "fail"
	return BehaviourResult.progress(ctx.next(port))
