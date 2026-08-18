## A named place in the storyline. Carries nothing and changes nothing. It exists so a
## jump has somewhere to aim at, and so that somewhere has a name in the graph.
class_name WaypointNode extends InspectableNode

## The name this waypoint had last time it was looked at, so a rename can be recognised
## as one rather than as a value appearing from nowhere.
var _known_name: String = ""


func _init(command_manager: CommandManager = null) -> void:
	super._init(command_manager)
	_known_name = str(get_property_value("label"))
	property_changed.connect(_on_own_property_changed)


## What a jump aims at is the "label" every node already carries, so this declares only its
## own flow port. Naming that port "label" too would have it overwritten by the shared one.
func initialize_properties() -> void:
	define_property(Property.new("waypoint")
		.set_type("context")
		.main_property()
		.exposed()
		.exported())


func get_type() -> String:
	return "waypoint"


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
		var aim: Property = node.get_property("waypoint")
		if aim and str(aim.get_value()) == old_name:
			aim.set_value(new_name)


## An unnamed waypoint is unreachable in practice: the jump dropdown lists them by name.
##
## Two of them sharing a name is worse, and nothing checking one property at a time can see
## it: each of the two is perfectly fine on its own, and a jump aiming there quietly reaches
## whichever comes first. Both are named, so the author can see the pair.
func validate_object(result: ValidationResult, context: ValidationContext) -> void:
	var written: String = str(get_property_value("label")).strip_edges()
	if written.is_empty():
		result.add(
			ValidationIssue.warning(
				"This waypoint has no name, so a jump cannot tell it from another.",
				&"unnamed_waypoint"
			).at(self, "label")
		)
		return

	if context.project == null:
		return

	var storyline: StorylineDocument = context.project.get_storyline(storyline_id)
	if storyline == null:
		return

	for node: InspectableNode in storyline.nodes:
		if node == self or node.get_type() != "waypoint":
			continue
		if str(node.get_property_value("label")).strip_edges() != written:
			continue

		result.add(
			ValidationIssue.error(
				"Another waypoint here is also called '%s'; a jump cannot tell them apart."
				% written,
				&"waypoints_share_a_name"
			).at(self, "label")
		)
		return
