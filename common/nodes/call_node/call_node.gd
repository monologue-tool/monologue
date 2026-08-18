## Runs a function, then carries the story on from wherever that function ran out.
##
## The exits are not written by hand. One is grown for each place the called function's
## chain stops, so rewiring the function changes what a call to it offers, and a call
## never claims a way out the function does not have.
class_name CallNode extends InspectableNode


func initialize_properties() -> void:
	define_property(Property.new("call")
		.set_type("context")
		.main_property()
		.exposed()
		.exported(false))

	define_property(Property.new("target")
		.set_type("reference")
		.reference_scope("node:function")
		.required()
		.tooltip("Function to run.")
		.hidden_in_graph()
		.not_exposable())

	define_property(Property.new("exits")
		.set_type("collection")
		.collection("exits")
		.read_only()
		.not_exposable()
		.exported(false)
		.tooltip("One per place the function stops. Wire each onward.")
		.hidden_in_inspector())


func get_type() -> String:
	return "call"


## Which function runs before the story comes back here.
func _build_preview(_language: String = "") -> Control:
	var target: String = NodePreview.named(self, "target")
	if target.is_empty():
		return null
	return NodePreview.line("\u2192 %s" % NodePreview.plain(target))


## The exits are computed rather than stored, so they arrive the same way a choice
## node's connected options do: as external items nobody can edit in place.
func get_external_list_items(property_name: String) -> Array[Dictionary]:
	if property_name != "exits":
		return []
	return _list_exits()


## A call naming no function runs nothing, and a function that never stops gives the
## story nowhere to come back to.
func validate_object(result: ValidationResult, _context: ValidationContext) -> void:
	if str(get_property_value("target")).is_empty():
		result.add(
			ValidationIssue.warning(
				"This call names no function, so it does nothing.", &"empty_call"
			).at(self, "target")
		)
		return

	if _list_exits().is_empty():
		result.add(
			ValidationIssue.warning(
				"The function called here never stops, so this call has no way out.",
				&"call_without_exit"
			).at(self, "exits")
		)


## One entry per place the called function's chain runs out. Empty while no function is
## named, and while the project is still being built.
func _list_exits() -> Array[Dictionary]:
	var storyline: StorylineDocument = _get_storyline()
	var target_id: String = str(get_property_value("target"))
	if storyline == null or target_id.is_empty():
		return []

	var exits: Array[Dictionary] = []
	for node: InspectableNode in storyline.find_terminations(target_id):
		exits.append(
			{"external": true, "source_node_id": node.get_id(), "name": _exit_name(node)}
		)
	return exits


## How one exit is named: the label of the node the function stopped at, or that node's
## type when it carries no label.
func _exit_name(node: InspectableNode) -> String:
	var project: MonologueProject = ProjectManager.current_project
	var label: String = Util.to_label(
		node.get_property_value("label"), project.active_language_code if project else ""
	)
	return label if not label.is_empty() else Util.to_readable_name(node.get_type())


## The storyline this call lives in, subscribing to it on the way so that rewiring the
## function it calls redraws this node.
func _get_storyline() -> StorylineDocument:
	if storyline_id.is_empty() or ProjectManager.current_project == null:
		return null

	var storyline: StorylineDocument = ProjectManager.current_project.get_storyline(storyline_id)
	if storyline and not storyline.connections_changed.is_connected(rebuild_preview):
		storyline.connections_changed.connect(rebuild_preview)
	return storyline
