## The plainest behaviour that is not instant, and the one worth reading first: hold the
## story in run(), count in process(), leave when the count is out.
extends MonologueBehaviour

var _left: float = 0.0


func handles() -> PackedStringArray:
	return ["wait"]


func setup(_ctx: MonologueContext) -> void:
	_left = 0.0


func run(ctx: MonologueContext) -> BehaviourResult:
	_left = float(ctx.value("seconds", 1.0))
	return process(ctx, 0.0)


func process(ctx: MonologueContext, delta: float) -> BehaviourResult:
	_left -= delta
	if _left > 0.0:
		return BehaviourResult.wait()
	return BehaviourResult.progress(ctx.next())
