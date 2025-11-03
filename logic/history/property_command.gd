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


func undo() -> void:
	var property: Property = target.get_property(property_name)
	property.set_value(old_value)
	target._notify_change(property_name)


func get_description() -> String:
	return "Change value of `%s` property" % property_name
