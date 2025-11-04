class_name NodeSelectionCommand extends Command

var storyline_id: String
var previous_node: InspectableNode
var next_node: InspectableNode
var apply_callable: Callable


func _init(
	p_storyline_id: String,
	p_previous_node: InspectableNode,
	p_next_node: InspectableNode,
	p_apply_callable: Callable
) -> void:
	storyline_id = p_storyline_id
	previous_node = p_previous_node
	next_node = p_next_node
	apply_callable = p_apply_callable


func execute() -> void:
	_apply_selection(next_node)


func undo() -> void:
	_apply_selection(previous_node)


func get_description() -> String:
	var target_id := ""
	if next_node:
		var id_property := next_node.get_property("id")
		if id_property:
			target_id = String(id_property.get_value())
	if target_id.is_empty():
		return "Change selection"
	return "Select node %s" % target_id


func _apply_selection(target: InspectableNode) -> void:
	if not apply_callable.is_valid():
		return

	apply_callable.call(target, storyline_id)
