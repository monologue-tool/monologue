## Makes changing the graph selection undoable.
##
## Selections are Array[InspectableObject] throughout, even here where they only hold nodes.
## GDScript typed arrays are invariant, and `as` does not convert between them.
class_name NodeSelectionCommand extends Command

var storyline_id: String
var previous_nodes: Array[InspectableObject]
var next_nodes: Array[InspectableObject]
var apply_callable: Callable


func _init(
	p_storyline_id: String,
	p_previous_nodes: Array[InspectableObject],
	p_next_nodes: Array[InspectableObject],
	p_apply_callable: Callable
) -> void:
	storyline_id = p_storyline_id
	previous_nodes = p_previous_nodes.duplicate()
	next_nodes = p_next_nodes.duplicate()
	apply_callable = p_apply_callable


func execute() -> void:
	_apply_selection(next_nodes)


func undo() -> void:
	_apply_selection(previous_nodes)


func get_description() -> String:
	var target_ids: PackedStringArray = []
	for node: InspectableObject in next_nodes:
		if node:
			target_ids.append(str(node.get_property_value("id")))

	if target_ids.is_empty():
		return "Clear selection"
	return "Select %s" % ", ".join(target_ids)


func _apply_selection(targets: Array[InspectableObject]) -> void:
	if not apply_callable.is_valid():
		return

	apply_callable.call(targets, storyline_id)
