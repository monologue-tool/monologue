## Runs a function, then carries the story on from wherever that function ran out.
##
## The exits are not written by hand. One is grown for each place the called function's chain
## stops, so a call never offers a way out the function does not have.
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


func _build_preview(_language: String = "") -> Control:
	var target: String = NodePreview.named(self, "target")
	if target.is_empty():
		return null
	return NodePreview.line("\u2192 %s" % NodePreview.plain(target))


## Computed, not stored, so they arrive as external items nobody can edit in place.
func get_external_list_items(property_name: String) -> Array[Dictionary]:
	if property_name != "exits":
		return []
	return _list_exits()


## A call naming no function runs nothing. A function that never stops gives the story
## nowhere to come back to.
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


## One entry per place the called function's chain runs out.
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


## The label of the node the function stopped at, or its type when it carries none.
func _exit_name(node: InspectableNode) -> String:
	var project: MonologueProject = ProjectManager.current_project
	var label: String = Util.to_label(
		node.get_property_value("label"), project.active_language_code if project else ""
	)
	return label if not label.is_empty() else Util.to_readable_name(node.get_type())


## Subscribes on the way, so rewiring the called function redraws this node.
func _get_storyline() -> StorylineDocument:
	if storyline_id.is_empty() or ProjectManager.current_project == null:
		return null

	var storyline: StorylineDocument = ProjectManager.current_project.get_storyline(storyline_id)
	if storyline and not storyline.connections_changed.is_connected(rebuild_preview):
		storyline.connections_changed.connect(rebuild_preview)
	return storyline
