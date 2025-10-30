class_name PropertySettingsChangeCommand extends Command

var target: InspectableObject
var property_name: String
var settings_name: String
var old_value: Variant
var new_value: Variant


func _init(
	p_target: InspectableObject,
	p_property: String,
	p_settings_name: String,
	p_old: Variant,
	p_new: Variant,
) -> void:
	target = p_target
	property_name = p_property
	settings_name = p_settings_name
	old_value = p_old
	new_value = p_new


func execute() -> void:
	var property: Property = target.get_property(property_name)
	property.settings[settings_name] = new_value
	target._notify_change(property_name)
	#target._notify_property_settings_change(property_name, settings_name, old_value, new_value)


func undo() -> void:
	var property: Property = target.get_property(property_name)
	property.settings[settings_name] = old_value
	target._notify_change(property_name)
	#target._notify_property_settings_change(property_name, settings_name, new_value, old_value)


func get_description() -> String:
	return "Change settings of `%s` property" % property_name
