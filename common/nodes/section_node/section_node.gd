## Runs a section, then carries the story on from wherever that section ran out.
##
## One exit is grown per place the section stops, so it never offers a way out its own
## graph does not have.
class_name SectionNode extends InspectableNode

## The section this node is subscribed to.
var _watched: StorylineDocument = null


func initialize_properties() -> void:
	define_property(Property.new("section")
		.set_type("context")
		.main_property()
		.exposed()
		.exported(false))

	define_property(Property.new("target")
		.set_type("reference")
		.reference_scope("sections")
		.required()
		.tooltip("Section to run.")
		.hidden_in_graph()
		.hidden_in_inspector()
		.not_exposable())

	define_property(Property.new("exits")
		.set_type("collection")
		.collection("exits")
		.read_only()
		.not_exposable()
		.exported(false)
		.tooltip("One per place the section stops. Wire each onward.")
		.hidden_in_inspector())


func get_type() -> String:
	return "section"


func _build_preview(_language: String = "") -> Control:
	var named: String = NodePreview.named(self, "target")
	if named.is_empty():
		return null

	var heading: RichTextLabel = NodePreview.line("\u2192 %s" % NodePreview.plain(named))
	var map: SectionMap = SectionMap.of(_get_target())
	if map == null:
		return heading

	var stack: VBoxContainer = VBoxContainer.new()
	stack.mouse_filter = Control.MOUSE_FILTER_PASS
	stack.custom_minimum_size.y = NodePreview.LINE_HEIGHT + SectionMap.HEIGHT
	stack.add_child(heading)
	stack.add_child(map)
	return stack


func get_external_list_items(property_name: String) -> Array[Dictionary]:
	if property_name != "exits":
		return []
	return _list_exits()


func validate_object(result: ValidationResult, context: ValidationContext) -> void:
	var target_id: String = str(get_property_value("target"))
	if target_id.is_empty():
		result.add(
			ValidationIssue.warning(
				"This node names no section, so it does nothing.", &"empty_section"
			).at(self, "target")
		)
		return

	if _leads_back_here(target_id, context.project):
		result.add(
			ValidationIssue.error(
				"This section ends up running itself, so it would never stop.",
				&"section_contains_itself"
			).at(self, "target")
		)
		return

	if _list_exits().is_empty():
		result.add(
			ValidationIssue.warning(
				"The section run here never stops, so this node has no way out.",
				&"section_without_exit"
			).at(self, "exits")
		)


## One entry per place the section's chain runs out, starting from its root.
func _list_exits() -> Array[Dictionary]:
	var section: StorylineDocument = _get_target()
	var root: InspectableNode = section.get_root() if section else null
	if root == null:
		return []

	var exits: Array[Dictionary] = []
	for node: InspectableNode in section.find_terminations(root.get_id()):
		exits.append(
			{"external": true, "source_node_id": node.get_id(), "name": _exit_name(node)}
		)
	return exits


## The label of the node the section stopped at, or its type when it carries none.
func _exit_name(node: InspectableNode) -> String:
	var project: MonologueProject = ProjectManager.current_project
	var label: String = Util.to_label(
		node.get_property_value("label"), project.active_language_code if project else ""
	)
	return label if not label.is_empty() else Util.to_readable_name(node.get_type())


func _leads_back_here(from_id: String, project: MonologueProject) -> bool:
	if project == null:
		return false

	var seen: Dictionary[String, bool] = {}
	var pending: Array[String] = [from_id]
	while not pending.is_empty():
		var document_id: String = pending.pop_back()
		if document_id == storyline_id:
			return true
		if document_id.is_empty() or seen.has(document_id):
			continue
		seen[document_id] = true

		var document: StorylineDocument = project.get_storyline(document_id)
		if document == null:
			continue
		for node: InspectableNode in document.nodes:
			if node.get_type() == "section":
				pending.append(str(node.get_property_value("target")))
	return false


## Subscribes to the section it runs, so editing that section's graph regrows the exits here.
func _get_target() -> StorylineDocument:
	var project: MonologueProject = ProjectManager.current_project
	var section: StorylineDocument = (
		project.get_storyline(str(get_property_value("target"))) if project else null
	)
	if section == _watched:
		return section

	_follow(_watched, false)
	_follow(section, true)
	_watched = section
	return section


## Everything that can move where a section's chains run out.
func _follow(document: StorylineDocument, wanted: bool) -> void:
	if document == null:
		return

	for changed: String in ["connections_changed", "node_added", "node_removed"]:
		var moved: Signal = document.get(changed)
		if wanted and not moved.is_connected(rebuild_preview):
			moved.connect(rebuild_preview)
		elif not wanted and moved.is_connected(rebuild_preview):
			moved.disconnect(rebuild_preview)
