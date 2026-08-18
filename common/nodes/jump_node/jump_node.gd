## Continues the story at a waypoint somewhere else in this storyline. Terminal: the
## story carries on over there, so there is nothing to wire out of.
##
## What is stored is the waypoint's own name, not its id. Names are unique among the nodes
## of a storyline, and [WaypointNode] rewrites the jumps that named it whenever it is renamed.
class_name JumpNode extends InspectableNode


func initialize_properties() -> void:
	define_property(Property.new("jump")
		.set_type("context")
		.main_property()
		.exposed()
		.exported(false))

	define_property(Property.new("waypoint")
		.set_type("dropdown")
		.source("node:waypoint")
		.required()
		.tooltip("Waypoint to continue from."))


func get_type() -> String:
	return "jump"


## Where the story carries on.
func _build_preview(_language: String = "") -> Control:
	var waypoint: String = NodePreview.named(self, "waypoint")
	if waypoint.is_empty():
		return null
	return NodePreview.line("\u2192 %s" % NodePreview.plain(waypoint))


## A jump aimed at a name no label carries goes nowhere, and reads as if it worked.
func validate_object(result: ValidationResult, context: ValidationContext) -> void:
	var target: String = str(get_property_value("waypoint")).strip_edges()
	if target.is_empty() or context.project == null:
		return

	var storyline: StorylineDocument = context.project.get_storyline(storyline_id)
	if storyline == null:
		return

	for node: InspectableNode in storyline.nodes:
		if node.get_type() == "waypoint" and str(node.get_property_value("label")) == target:
			return

	result.add(
		ValidationIssue.error(
			"No waypoint in this storyline is called '%s'." % target, &"unknown_waypoint"
		).at(self, "waypoint")
	)
