## Continues at a waypoint named somewhere else in this storyline.
##
## By name and not by id, which is what the editor stores. Renaming a waypoint rewrites every
## jump that named it.
extends MonologueBehaviour


func handles() -> PackedStringArray:
	return ["jump"]


func run(ctx: MonologueContext) -> BehaviourResult:
	var target: String = str(ctx.value("waypoint", "")).strip_edges()
	if target.is_empty():
		ctx.fault(&"jump_without_target", "This jump names no waypoint.")
		return BehaviourResult.stop()

	var found: PackedStringArray = ctx.graph.find_by(ctx.storyline, "label", target)
	if found.is_empty():
		ctx.fault(&"unknown_waypoint", "No waypoint here is called '%s'." % target)
		return BehaviourResult.stop()

	if found.size() > 1:
		ctx.note(
			&"ambiguous_waypoint",
			"%d waypoints are called '%s'; the first was taken." % [found.size(), target]
		)
	return BehaviourResult.progress(found[0])
