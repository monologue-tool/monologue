@abstract
class_name InspectableObject extends Resource

var _properties: Dictionary[String, Property] = {}
var _observers: Array[Callable] = []
var history: CommandManager
var settings: Dictionary = {}


func _init(command_manager: CommandManager = null) -> void:
	if not command_manager:
		push_warning("InspectableObject does not have a command manager.")
	history = command_manager

	initialize_properties()
	_load_settings()


func _load_settings() -> void:
	var new_settings: Dictionary = {}
	new_settings.merge(get_settings(), true)
	settings = new_settings


func define_property(
	pname: String,
	default_value: Variant,
	type: String,
	psettings: Dictionary = {},
	category: String = "General"
) -> void:
	var merged_settings: Dictionary = psettings.duplicate(true)
	merged_settings["category"] = category

	var property: Property = Property.new(pname, default_value, type, merged_settings)
	_properties.set(pname, property)

	property.value_changed.connect(func(_old, _new): _notify_change(pname))


func add_observer(callable: Callable) -> void:
	if callable in _observers:
		push_warning("Observer is already registered.")
		return

	_observers.append(callable)


func remove_observer(callable: Callable) -> void:
	_observers.erase(callable)


func _notify_change(pname: String) -> void:
	for observer: Callable in _observers:
		if not observer or not observer.is_valid() or observer.get_object() == null:
			_observers.erase(observer)
			continue
		observer.call(self, pname)


func get_properties() -> Array[Property]:
	var properties: Array[Property] = []
	for pname in _properties.keys():
		properties.append(_properties[pname])

	return properties


func get_property(pname: String) -> Property:
	return _properties.get(pname)


func get_property_value(pname: String) -> Variant:
	var property: Property = get_property(pname)
	if not property:
		return
	return property.get_value()


func get_property_settings_value(pname: String, skey: String) -> Variant:
	var property: Property = get_property(pname)
	return property.settings.get(skey)


func set_property_value(pname: String, pvalue: Variant) -> void:
	if not _properties.has(pname):
		return

	var old_value: Variant = get_property_value(pname)

	if pvalue == old_value:
		return

	var command: PropertyChangeCommand = PropertyChangeCommand.new(self, pname, old_value, pvalue)
	history.execute(command)

	_notify_change(pname)


func set_property_settings_value(pname: String, skey: Variant, svalue: Variant) -> void:
	if not _properties.has(pname):
		return

	var old_value: Variant = get_property_settings_value(pname, skey)

	var command: PropertySettingsChangeCommand = PropertySettingsChangeCommand.new(
		self, pname, skey, old_value, svalue
	)
	history.execute(command)


func _to_dict() -> Dictionary:
	var dict: Dictionary = {"$type": get_type()}
	for property: Property in get_properties():
		dict[property.name] = property._to_dict()

	return dict


# Do not trigger undo/redo
func _from_dict(dict: Dictionary) -> void:
	dict.erase("$type")
	for property: Property in get_properties():
		var property_dict: Dictionary = dict.get(property.name, {})
		property._from_dict(property_dict)


func get_settings() -> Dictionary:
	return {}


func rebuild_preview() -> void:
	pass


@warning_ignore("native_method_override")
func duplicate(deep: bool = false) -> Resource:
	var duplicated: InspectableNode = super.duplicate(deep)
	duplicated.history = history
	duplicated.settings = settings

	for property: Property in get_properties():
		var d_prop: Property = duplicated.get_property(property.name)
		d_prop.value = property.get_value()

	return duplicated


@abstract func get_type() -> String
@abstract func initialize_properties() -> void
@abstract func _on_property_changed(pname: String, old_value: Variant, new_value: Variant) -> void
