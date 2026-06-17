@abstract
class_name InspectableObject extends Resource

const ID_LENGTH: int = 4

signal property_changed(property_name: String)

var _properties: Dictionary[String, Property] = {}
var _children: Dictionary[String, Array] = {} # Children object of properties
var history: CommandManager
var settings: Dictionary = {}
var _parent_object: InspectableObject
var _parent_property_name: String


func get_parent_object() -> InspectableObject:
	return _parent_object


func get_parent_property_name() -> String:
	return _parent_property_name


func _set_parent_info(parent: InspectableObject, pname: String) -> void:
	_parent_object = parent
	_parent_property_name = pname


func _init(command_manager: CommandManager = null) -> void:
	if not command_manager:
		Log.warn("InspectableObject does not have a command manager.")
	history = command_manager
	
	define_property(
		"id",
		"%s-%s" % [get_type(), IDGen.generate(ID_LENGTH)],
		"text",
		{
			"visible_in_graph": false,
			"visible_in_inspector": true,
			"flat": true,
			"unique": true,
		},
		"Special:Header"
	)

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

	property.value_changed.connect(
		func(_old: Variant, _new: Variant) -> void: 
			property_changed.emit(pname)
	)


func get_properties() -> Array[Property]:
	var properties: Array[Property] = []
	for pname: String in _properties.keys():
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
	return property._overrides.get(skey)


func set_property_value(pname: String, pvalue: Variant) -> void:
	if not _properties.has(pname):
		return

	var old_value: Variant = get_property_value(pname)

	if typeof(pvalue) == typeof(old_value) and pvalue == old_value:
		return

	var command: PropertyChangeCommand = PropertyChangeCommand.new(self, pname, old_value, pvalue)
	history.execute(command)


func set_property_settings_value(pname: String, skey: String, svalue: Variant) -> void:
	if not _properties.has(pname):
		return

	var old_value: Variant = get_property_settings_value(pname, skey)

	var command: PropertySettingsChangeCommand = PropertySettingsChangeCommand.new(
		self, pname, skey, old_value, svalue
	)
	history.execute(command)


func get_property_children(property_name: String) -> Array:
	return _children.get(property_name, [])


func set_property_children(property_name: String, objects: Array) -> void:
	for object: InspectableObject in objects:
		if not object.property_changed.is_connected(_on_property_children_property_change):
			object.property_changed.connect(_on_property_children_property_change.bind(property_name))
		object._set_parent_info(self, property_name)
	
	_children[property_name] = objects


func add_property_children(property_name: String, object: InspectableObject) -> void:
	if not object.property_changed.is_connected(_on_property_children_property_change):
		object.property_changed.connect(_on_property_children_property_change.bind(property_name))
	object._set_parent_info(self, property_name)
	
	_children.get_or_add(property_name, [])
	_children.get(property_name).append(object)


func remove_property_children(property_name: String, object: InspectableObject) -> void:
	if not property_name in _children:
		return
	if object.property_changed.is_connected(_on_property_children_property_change):
		object.property_changed.disconnect(_on_property_children_property_change)
	object._set_parent_info(null, "")
	_children.get(property_name).erase(object)


func move_property_child(property_name: String, object: InspectableObject, to_index: int) -> void:
	if not property_name in _children:
		return
	
	var children_array: Array = _children.get(property_name)
	var current_index: int = children_array.find(object)
	
	if current_index == -1:
		return
	
	children_array.remove_at(current_index)
	children_array.insert(to_index, object)


func _on_property_children_property_change(_children_property_name: String, property_name: String) -> void:
	var childrens: Array = get_property_children(property_name)
	var value: Array = []
	for object: InspectableObject in childrens:
		value.append(object._to_dict())
	
	set_property_value(property_name, value)


func _to_dict() -> Dictionary:
	var dict: Dictionary = {"$type": get_type()}
	for property: Property in get_properties():
		var property_dict: Dictionary = property._to_dict()
		dict[property.name] = property_dict
	return dict


func _from_dict(dict: Dictionary) -> void:
	dict.erase("$type")
	for property: Property in get_properties():
		var property_dict: Dictionary = dict.get(property.name, {})
		property._from_dict(property_dict)


func get_settings() -> Dictionary:
	return {}


## Returns external list items for a given list property (e.g. connected OptionNodes).
## Override in subclasses that support externally-sourced list items.
func get_external_list_items(_property_name: String) -> Array[Dictionary]:
	return []


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
