class_name PropertyChangeCommand extends Command

var target: InspectableObject
var property_name: String
var old_value: Variant
var new_value: Variant


func _init(p_target: InspectableObject, p_property: String, p_old: Variant, p_new: Variant) -> void:
	target = p_target
	property_name = p_property
	old_value = p_old
	new_value = p_new


func execute() -> void:
	var property: Property = target.get_property(property_name)
	property.set_value(new_value)
	target._notify_change(property_name)
	_broadcast_change()


func undo() -> void:
	var property: Property = target.get_property(property_name)
	property.set_value(old_value)
	target._notify_change(property_name)
	_broadcast_change(true)


func get_description() -> String:
	return "Change value of `%s` property" % property_name


func _broadcast_change(is_undo: bool = false) -> void:
	if not (target is InspectableNode):
		return

	var node := target as InspectableNode
	var property: Property = node.get_property(property_name)
	if not property:
		return

	if target is InspectableNode and property_name == "position":
		EventBus.request_node_inspection.emit(node, node.storyline_id, true)

	if not property.get_settings_value("visible_in_inspector", true):
		return

	EventBus.inspector_property_changed.emit(node, property_name, is_undo)
