## Watches a variable while the story runs elsewhere, and takes over when it matches.
##
## The one behaviour that acts on nodes other than the one being played: every behaviour is
## offered each node before it runs, and this one answers for whichever event is armed.
##
## Between two nodes and never inside one. An event that fired mid-line would cut the line
## off, and late is better than that.
extends MonologueBehaviour

## The event nodes of the story, found once when a run starts rather than walked again for
## every node the story enters.
var _armed: PackedStringArray = []


func handles() -> PackedStringArray:
	return ["event"]


func setup(ctx: MonologueContext) -> void:
	_armed = []
	for node_id: String in ctx.graph.nodes:
		if ctx.graph.type_of(node_id) == "event":
			_armed.append(node_id)


## Nothing reaches an event by a wire -- it declares no input. Being entered means the story
## found one anyway, and walking past is kinder than stopping over it.
func run(ctx: MonologueContext) -> BehaviourResult:
	return BehaviourResult.progress(ctx.next())


func step(ctx: MonologueContext) -> BehaviourResult:
	for node_id: String in _armed:
		if node_id == ctx.id:
			continue

		var watcher: MonologueContext = MonologueContext.new(ctx.session, node_id)
		var test: Variant = watcher.value("test")

		# An event watching nothing would otherwise compare null to null and fire at once,
		# on every node, for the whole run.
		if test is not Dictionary:
			continue
		if str((test as Dictionary).get("variable", "")).is_empty():
			continue
		if not watcher.test(test):
			continue

		if watcher.value("one_shot", true) == true:
			if ctx.state.fired_events.has(node_id):
				continue
			ctx.state.fired_events[node_id] = true

		return BehaviourResult.progress(watcher.next())
	return BehaviourResult.wait()
