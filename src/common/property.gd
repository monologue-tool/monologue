## Represents a single property with metadata and change tracking.
##
## Properties are the basic building blocks for inspectable objects in Monologue.
## Each property has a name, value, type, and configurable settings that control
## how it's displayed and edited in the inspector.
class_name Property extends RefCounted

## Emitted when the property value changes (without parameters).
signal changed

## Emitted when the property value changes with old and new values.
##
## [param old_value] The previous value before the change.
## [br][br]
## [param new_value] The new value after the change.
signal value_changed(old_value: Variant, new_value: Variant)

## The property's identifier name.
var name: String = ""  # Protected

## The current value of the property.
var value: Variant = 0

## The property type (e.g., "text", "number", "dropdown").
var type: String = ""  # Protected

## Dictionary of property settings controlling display and behavior.
var settings: Dictionary = {}


## Initializes a new property with the specified parameters.
##
## [param pname] The property name/identifier.
## [br][br]
## [param pvalue] The initial value of the property.
## [br][br]
## [param ptype] The property type string.
## [br][br]
## [param psettings] Optional dictionary of property settings.
func _init(pname: String, pvalue: Variant, ptype: String, psettings: Dictionary = {}) -> void:
	name = pname
	value = pvalue
	type = ptype
	settings = psettings


## Sets a new value for the property and emits change signals.
##
## [param new_value] The new value to assign to this property.
func set_value(new_value: Variant) -> void:
	var old_value: Variant = value
	value = new_value

	changed.emit()
	value_changed.emit(old_value, new_value)


## Returns the current value of the property.
func get_value() -> Variant:
	return value


## Retrieves a setting value from the property's settings dictionary.
##
## [param skey] The settings key to look up.
## [br][br]
## [param default_value] The value to return if the key is not found.
## [br][br]
## Returns the setting value if found, otherwise the default value.
func get_settings_value(skey: String, default_value: Variant) -> Variant:
	return settings.get(skey, default_value)


## Returns the human-readable display name for this property.
##
## Uses the "label" setting if available, otherwise converts the property name
## to a readable format using Util.to_readable_name().
func get_display_name() -> String:
	return Util.to_readable_name(settings.get("label", name))


## Returns the category this property belongs to.
##
## Returns the "category" setting if available, otherwise "General".
func get_category() -> String:
	return settings.get("category", "General")
