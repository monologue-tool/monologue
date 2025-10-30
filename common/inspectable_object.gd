@abstract
class_name InspectableObject extends RefCounted

var _properties: Dictionary[String, Property] = {}
var _observers: Array[Callable] = []
var _history: CommandManager
var settings: Dictionary = {}


func _init(command_manager: CommandManager = null) -> void:
	_history = command_manager

	initialize_properties()
	_load_settings()


func _load_settings() -> void:
	var new_settings: Dictionary = {"origin": false, "continuous": false}
	new_settings.merge(get_settings(), true)
	settings = new_settings


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


func add_observer(callable: Callable) -> void:
	if callable in _observers:
		push_warning("Observer is already registered.")
		return

	_observers.append(callable)


func _notify_change(pname: String) -> void:
	for observer: Callable in _observers:
		observer.call(self, pname)


func get_properties() -> Array[Property]:
	var properties: Array[Property] = []
	for pname in _properties.keys():
		properties.append(_properties[pname])

	return properties


func get_property(pname: String) -> Property:
	return _properties.get(pname)


func get_property_value(pname: String) -> Variant:
	return get_property(pname).get_value()


func get_property_settings_value(pname: String, skey: String) -> Variant:
	var property: Property = get_property(pname)
	return property.settings.get(skey)


func set_property_value(pname: String, pvalue: Variant) -> void:
	if not _properties.has(pname):
		return

	var old_value: Variant = get_property_value(pname)

	var command: PropertyChangeCommand = PropertyChangeCommand.new(self, pname, old_value, pvalue)
	_history.execute(command)

	#_notify_change(pname, old_value, pvalue)
	_notify_change(pname)


func set_property_settings_value(pname: String, skey: Variant, svalue: Variant) -> void:
	if not _properties.has(pname):
		return

	var old_value: Variant = get_property_settings_value(pname, skey)

	var command: PropertySettingsChangeCommand = PropertySettingsChangeCommand.new(
		self, pname, skey, old_value, svalue
	)
	_history.execute(command)


func _to_dict() -> Dictionary:
	var dict: Dictionary = {"$type": get_type()}
	for property: Property in get_properties():
		dict[property.name] = property.value

	return dict


func get_settings() -> Dictionary:
	return {}


@abstract func get_type() -> String
@abstract func initialize_properties() -> void
@abstract func _on_property_changed(pname: String, old_value: Variant, new_value: Variant) -> void
