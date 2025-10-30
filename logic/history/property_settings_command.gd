## Command for changing a property's settings value with undo/redo support.
##
## Similar to PropertyChangeCommand but operates on the property's settings
## dictionary rather than the property value itself. Used for changing metadata
## like display options, exposed state, etc.
class_name PropertySettingsChangeCommand extends Command

## The inspectable object whose property settings are being changed.
var target: InspectableObject

## Name of the property whose settings are being changed.
var property_name: String

## Name of the settings key being changed.
var settings_name: String

## The original settings value before the change.
var old_value: Variant

## The new settings value after the change.
var new_value: Variant


## Initializes a property settings change command.
##
## [param p_target] The InspectableObject containing the property.
## [br][br]
## [param p_property] The name of the property.
## [br][br]
## [param p_settings_name] The settings key to change.
## [br][br]
## [param p_old] The original settings value.
## [br][br]
## [param p_new] The new settings value.
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


## Executes the settings change by updating the property's settings dictionary.
func execute() -> void:
	var property: Property = target.get_property(property_name)
	property.settings[settings_name] = new_value
	target._notify_change(property_name)
	#target._notify_property_settings_change(property_name, settings_name, old_value, new_value)


## Undoes the settings change by restoring the old value.
func undo() -> void:
	var property: Property = target.get_property(property_name)
	property.settings[settings_name] = old_value
	target._notify_change(property_name)
	#target._notify_property_settings_change(property_name, settings_name, new_value, old_value)


## Returns a description of this command for display purposes.
func get_description() -> String:
	return "Change settings of `%s` property" % property_name
