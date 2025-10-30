## Command for changing a property value with undo/redo support.
##
## Encapsulates a property value change operation, storing the target object,
## property name, and both old and new values for reversibility.
class_name PropertyChangeCommand extends Command

## The inspectable object whose property is being changed.
var target: InspectableObject

## Name of the property being changed.
var property_name: String

## The original value before the change.
var old_value: Variant

## The new value after the change.
var new_value: Variant


## Initializes a property change command.
##
## [param p_target] The InspectableObject containing the property.
## [br][br]
## [param p_property] The name of the property to change.
## [br][br]
## [param p_old] The original value before the change.
## [br][br]
## [param p_new] The new value to set.
func _init(p_target: InspectableObject, p_property: String, p_old: Variant, p_new: Variant) -> void:
	target = p_target
	property_name = p_property
	old_value = p_old
	new_value = p_new


## Executes the property change by setting the new value.
func execute() -> void:
	var property: Property = target.get_property(property_name)
	property.set_value(new_value)


## Undoes the property change by restoring the old value.
func undo() -> void:
	var property: Property = target.get_property(property_name)
	property.set_value(old_value)


## Returns a description of this command for display purposes.
func get_description() -> String:
	return "Change value of `%s` property" % property_name
