## A named place in the storyline. Carries nothing and changes nothing; it exists so a
## jump has somewhere to aim at, and so that somewhere has a name in the graph.
class_name LabelNode extends InspectableNode

## The name this waypoint had last time it was looked at, so a rename can be recognised
## as one rather than as a value appearing from nowhere.
var _known_name: String = ""


func _init(command_manager: CommandManager = null) -> void:
	super._init(command_manager)
	_known_name = str(get_property_value("label"))
	property_changed.connect(_on_own_property_changed)


func initialize_properties() -> void:
	define_property(Property.new("waypoint")
		.set_type("context")
		.main_property()
		.exposed()
		.exported())


func get_type() -> String:
	return "label"


func _on_own_property_changed(property_name: String) -> void:
	if property_name != "label":
		return

	var new_name: String = str(get_property_value("label"))
	if new_name == _known_name:
		return

	_retarget_jumps(_known_name, new_name)
	_known_name = new_name


## Points every jump that named this waypoint at its new name.
##
## Written straight to the property rather than through a command: undoing the rename
## runs this again in the other direction, so the jumps follow back on their own and
## the rename stays one undo step.
func _retarget_jumps(old_name: String, new_name: String) -> void:
	if old_name.is_empty() or ProjectManager.current_project == null:
		return

	var storyline: StorylineDocument = ProjectManager.current_project.get_storyline(storyline_id)
	if storyline == null:
		return

	for node: InspectableNode in storyline.nodes:
		if node.get_type() != "jump":
			continue
		var target: Property = node.get_property("target")
		if target and str(target.get_value()) == old_name:
			target.set_value(new_name)


## An unnamed label is unreachable in practice: the jump dropdown lists labels by name.
func validate_object(result: ValidationResult, _context: ValidationContext) -> void:
	if str(get_property_value("label")).strip_edges().is_empty():
		result.add(
			ValidationIssue.warning(
				"This label has no name, so a jump cannot tell it from another.",
				&"unnamed_label"
			).at(self, "label")
		)
