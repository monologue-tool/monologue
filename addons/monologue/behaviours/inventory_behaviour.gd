extends MonologueBehaviour


func handles() -> PackedStringArray:
	return ["inventory"]


func run(ctx: MonologueContext) -> BehaviourResult:
	var item: String = str(ctx.value("item", ""))
	if item.is_empty():
		ctx.note(&"inventory_without_item", "This node names no item.")
		return BehaviourResult.progress(ctx.next())

	var who: String = str(ctx.value("who", ""))
	if who.is_empty():
		ctx.note(&"inventory_without_who", "This node names nobody to carry the item.")
		return BehaviourResult.progress(ctx.next())

	var held: int = ctx.state.held(who, item)
	var quantity: int = int(ctx.value("quantity", 1))
	match str(ctx.value("operation", "Give")):
		"Take": held -= quantity
		"Set": held = quantity
		_: held += quantity

	# Kept at zero, so the entry still says the item was met.
	ctx.state.hold(who, item, held)
	return BehaviourResult.progress(ctx.next())
