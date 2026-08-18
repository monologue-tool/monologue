## Writes a variable, either replacing it or doing arithmetic on what was there.
##
## The written value is coerced to the type the project declared for that variable, so a
## story cannot put text into a number by accident. That is [method MonologueContext.set_var]
## doing it, not this.
extends MonologueBehaviour


func handles() -> PackedStringArray:
	return ["variable"]


func run(ctx: MonologueContext) -> BehaviourResult:
	var target: String = str(ctx.value("target", ""))
	if target.is_empty():
		ctx.note(&"variable_without_target", "This node names no variable.")
		return BehaviourResult.progress(ctx.next())

	ctx.set_var(
		target,
		_applied(ctx, ctx.get_var(target), str(ctx.value("operator", "=")), ctx.value("value"))
	)
	return BehaviourResult.progress(ctx.next())


static func _applied(
	ctx: MonologueContext, current: Variant, operator: String, amount: Variant
) -> Variant:
	if operator == "=":
		return amount

	# Adding to text joins it; the alternative is silently reading "3" as three.
	if operator == "+" and (current is String or amount is String):
		return str(current) + str(amount)

	var left: float = float(current) if current != null else 0.0
	var right: float = float(amount) if amount != null else 0.0
	match operator:
		"+": return left + right
		"-": return left - right
		"*": return left * right
		"/":
			if is_zero_approx(right):
				ctx.note(&"division_by_zero", "A variable was divided by zero; it was left as it was.")
				return current
			return left / right
	return amount
