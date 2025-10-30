## Abstract base class for objects with inspectable properties.
##
## Provides a property system with change tracking, undo/redo support,
## and observer notifications. All objects that need to expose properties
## to the inspector inherit from this class.
@abstract
class_name InspectableObject extends RefCounted

## Dictionary of all properties owned by this object, keyed by property name.
var _properties: Dictionary[String, Property] = {}

## Array of callable observers that are notified when properties change.
var _observers: Array[Callable] = []

## Command manager for undo/redo functionality.
var _history: CommandManager

## Dictionary of object-level settings controlling behavior.
var settings: Dictionary = {}


## Initializes the inspectable object with an optional command manager.
##
## [param command_manager] Optional CommandManager for undo/redo support. Can be null.
func _init(command_manager: CommandManager = null) -> void:
	_history = command_manager

	initialize_properties()
	_load_settings()


## Loads default settings and merges with custom settings from get_settings().
func _load_settings() -> void:
	var new_settings: Dictionary = {"origin": false, "continuous": false}
	new_settings.merge(get_settings(), true)
	settings = new_settings


## Defines a new property for this object.
##
## Creates a Property instance with the specified parameters and registers it
## with this object. The property will appear in the inspector based on its settings.
## [br][br]
## [param pname] The property name/identifier.
## [br][br]
## [param default_value] The initial value for the property.
## [br][br]
## [param type] The property type (e.g., "text", "number", "dropdown").
## [br][br]
## [param psettings] Optional dictionary of property-specific settings.
## [br][br]
## [param category] The category this property belongs to. Default is "General".
func define_property(
	pname: String,
	default_value: Variant,
	type: String,
	psettings: Dictionary = {},
	category: String = "General"
) -> void:
	var default_settings: Dictionary = {}
	default_settings["display"] = true
	default_settings["exposed"] = false
	default_settings["private"] = false
	default_settings["protected"] = false
	default_settings["export"] = false

	psettings["category"] = category
	psettings.merge(default_settings)

	var property: Property = Property.new(pname, default_value, type, psettings)
	_properties.set(pname, property)

	property.changed.connect(_notify_change.bind())


## Registers a callable observer to be notified of property changes.
##
## The callable will be invoked with (object, property_name) when any property changes.
## Warns if the observer is already registered.
## [br][br]
## [param callable] The callable function to register as an observer.
func add_observer(callable: Callable) -> void:
	if callable in _observers:
		push_warning("Observer is already registered.")
		return

	_observers.append(callable)


## Notifies all registered observers about a property change.
##
## [param pname] The name of the property that changed.
func _notify_change(pname: String) -> void:
	for observer: Callable in _observers:
		observer.call(self, pname)


## Returns an array of all properties owned by this object.
func get_properties() -> Array[Property]:
	var properties: Array[Property] = []
	for pname in _properties.keys():
		properties.append(_properties[pname])

	return properties


## Returns a specific property by name.
##
## [param pname] The property name to look up.
## [br][br]
## Returns the Property object, or null if not found.
func get_property(pname: String) -> Property:
	return _properties.get(pname)


## Returns the current value of a property by name.
##
## [param pname] The property name.
## [br][br]
## Returns the property's current value.
func get_property_value(pname: String) -> Variant:
	return get_property(pname).get_value()


## Returns a settings value from a property's settings dictionary.
##
## [param pname] The property name.
## [br][br]
## [param skey] The settings key to retrieve.
## [br][br]
## Returns the settings value.
func get_property_settings_value(pname: String, skey: String) -> Variant:
	var property: Property = get_property(pname)
	return property.settings.get(skey)


## Sets a property value with undo/redo support.
##
## Creates a PropertyChangeCommand and executes it through the command manager,
## enabling undo/redo. Notifies observers of the change.
## [br][br]
## [param pname] The property name.
## [br][br]
## [param pvalue] The new value to set.
func set_property_value(pname: String, pvalue: Variant) -> void:
	if not _properties.has(pname):
		return

	var old_value: Variant = get_property_value(pname)

	var command: PropertyChangeCommand = PropertyChangeCommand.new(self, pname, old_value, pvalue)
	_history.execute(command)

	#_notify_change(pname, old_value, pvalue)
	_notify_change(pname)


## Sets a property settings value with undo/redo support.
##
## Creates a PropertySettingsChangeCommand and executes it through the command manager.
## [br][br]
## [param pname] The property name.
## [br][br]
## [param skey] The settings key to change.
## [br][br]
## [param svalue] The new settings value.
func set_property_settings_value(pname: String, skey: Variant, svalue: Variant) -> void:
	if not _properties.has(pname):
		return

	var old_value: Variant = get_property_settings_value(pname, skey)

	var command: PropertySettingsChangeCommand = PropertySettingsChangeCommand.new(
		self, pname, skey, old_value, svalue
	)
	_history.execute(command)


## Converts this object to a dictionary representation.
##
## Used for serialization. Includes the object type and all property values.
## [br][br]
## Returns a dictionary with "$type" key and property name/value pairs.
func _to_dict() -> Dictionary:
	var dict: Dictionary = {"$type": get_type()}
	for property: Property in get_properties():
		dict[property.name] = property.value

	return dict


## Returns custom settings for this object type.
##
## Override in subclasses to provide object-specific settings.
## [br][br]
## Returns an empty dictionary by default.
func get_settings() -> Dictionary:
	return {}


## Returns the type identifier string for this object.
##
## Must be implemented by subclasses to identify the object type for serialization.
@abstract func get_type() -> String

## Initializes all properties for this object.
##
## Must be implemented by subclasses to define their properties using define_property().
@abstract func initialize_properties() -> void

## Called when a property value changes.
##
## Override in subclasses to respond to property changes.
## [br][br]
## [param pname] The name of the property that changed.
## [br][br]
## [param old_value] The previous value.
## [br][br]
## [param new_value] The new value.
@abstract func _on_property_changed(pname: String, old_value: Variant, new_value: Variant) -> void
