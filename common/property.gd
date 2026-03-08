class_name Property extends RefCounted

signal value_changed(old_value: Variant, new_value: Variant)
signal connection_changed()

var name: String = ""
var value: Variant = 0
var type: String = ""
## Base settings: defaults + descriptor defaults + constructor overrides. Read-only after init.
var _base_settings: Dictionary = {}
## Runtime overrides set by the user (serialized as "_editor_settings" in JSON).
var _overrides: Dictionary = {}
var descriptor: FieldDescriptor
var _bindings: Array[FieldBinding] = []

const DEFAULT_SETTINGS: Dictionary = {
	"visible_in_graph": true,
	"visible_in_inspector": true,
	"editable": true,
	"read_only": false,
	"exposable": true,
	"exposed": false,
	"export": false,
	"category": "General",
	"label": "",
}

## Tracks input connections to this property.
## Each entry: {"node_id": String, "property_name": String, "item_id"?: String}
var connected_from: Array[Dictionary] = []

## Tracks output connections from this property.
## Each entry: {"node_id": String, "property_name": String, "item_id"?: String}
var connected_to: Array[Dictionary] = []

## Property Settings:
## - visible_in_graph: Whether property shows as a row in graph node view
## - visible_in_inspector: Whether property shows in inspector panel
## - editable: Whether property value can be edited (enforced in inspector)
## - exposed: Whether property has input port (left side) for receiving connections
## - export: Whether property has output port (right side) for sending connections
## - is_main_property: Whether this is the main connectable property of the node


func _init(pname: String, pvalue: Variant, ptype: String, psettings: Dictionary = {}) -> void:
	name = pname
	value = pvalue
	if pvalue is Callable:
		@warning_ignore("unsafe_method_access")
		value = pvalue.call()
	
	type = ptype
	descriptor = FieldBucket.get_descriptor(ptype)
	_base_settings = DEFAULT_SETTINGS.duplicate(true)
	if descriptor and descriptor.default_settings:
		_base_settings.merge(descriptor.default_settings, true)
	if psettings:
		_base_settings.merge(psettings, true)
	if not _base_settings.get("category"):
		_base_settings["category"] = DEFAULT_SETTINGS["category"]
	if _base_settings.get("label", "") == "":
		_base_settings.erase("label")


func bind_field(field: Field, target_owner: InspectableObject = null) -> FieldBinding:
	if not is_instance_valid(field):
		return null
	if not field.is_inside_tree():
		field.tree_entered.connect(
			_on_field_tree_entered.bind(field, target_owner), CONNECT_ONE_SHOT
		)
		return null
	var binding: FieldBinding = FieldBucket.bind(self, field, target_owner)
	if binding:
		_bindings.append(binding)
	return binding


func _on_field_tree_entered(field: Field, target_owner: InspectableObject) -> void:
	bind_field(field, target_owner)


func set_value(new_value: Variant) -> void:
	if typeof(value) == typeof(new_value) and value == new_value:
		return
	var old_value: Variant = value
	value = new_value
	value_changed.emit(old_value, new_value)


func get_value() -> Variant:
	return value


func set_settings_value(sname: String, svalue: Variant) -> void:
	_overrides[sname] = svalue


func get_settings() -> Dictionary:
	var merged_settings: Dictionary = _overrides.duplicate(true)
	merged_settings.merge(_base_settings)
	return merged_settings


func has_settings(skey: Variant) -> bool:
	return get_settings().has(skey)


func get_settings_value(skey: String, default_value: Variant = null) -> Variant:
	return get_settings().get(skey, default_value)


func get_display_name() -> String:
	var label: String = get_settings_value("label", "")
	if label.is_empty():
		label = name
	return Util.to_readable_name(label)


func get_category() -> String:
	return get_settings_value("category", "General")


func is_input_connected() -> bool:
	return connected_from.size() > 0


func is_output_connected() -> bool:
	return connected_to.size() > 0


func is_port_connected() -> bool:
	return is_input_connected() or is_output_connected()


## Returns true if this property should appear as a row in the graph node view.
## A property is visible when visible_in_graph is true, or it has at least one port.
func is_visible_in_graph() -> bool:
	var has_input: bool = get_settings_value("exposed", false) == true
	var has_output: bool = get_settings_value("export", false) == true
	if not get_settings_value("visible_in_graph", true) and not (has_input or has_output):
		return false
	return true


func add_connection_from(node_id: String, property_name: String) -> void:
	var conn: Dictionary = {"node_id": node_id, "property_name": property_name}
	if conn not in connected_from:
		connected_from.append(conn)
		connection_changed.emit()


func add_connection_to(node_id: String, property_name: String) -> void:
	var conn: Dictionary = {"node_id": node_id, "property_name": property_name}
	if conn not in connected_to:
		connected_to.append(conn)
		connection_changed.emit()


func remove_connection_from(node_id: String, property_name: String) -> void:
	var old_size: int = connected_from.size()
	connected_from.assign(connected_from.filter(
		func(c: Dictionary) -> bool: return not (c["node_id"] == node_id and c["property_name"] == property_name)
	))
	if connected_from.size() != old_size:
		connection_changed.emit()


func remove_connection_to(node_id: String, property_name: String) -> void:
	var old_size: int = connected_to.size()
	connected_to.assign(connected_to.filter(
		func(c: Dictionary) -> bool: return not (c["node_id"] == node_id and c["property_name"] == property_name)
	))
	if connected_to.size() != old_size:
		connection_changed.emit()


func clear_connections() -> void:
	var had_connections: bool = not connected_from.is_empty() or not connected_to.is_empty()
	connected_from.clear()
	connected_to.clear()
	if had_connections:
		connection_changed.emit()


func refresh_bindings() -> void:
	_bindings = _bindings.filter(func(binding: FieldBinding) -> bool: return binding and binding.is_active())
	for binding: FieldBinding in _bindings:
		binding.refresh()


func get_descriptor() -> FieldDescriptor:
	if descriptor == null:
		descriptor = FieldBucket.get_descriptor(type)
	return descriptor


func _to_dict() -> Variant:
	var dict: Dictionary = {
		"value": get_value(),
	}

	if not connected_from.is_empty():
		dict["from_node"] = connected_from
	if not connected_to.is_empty():
		dict["to_node"] = connected_to

	if not _overrides.is_empty():
		dict["_editor_settings"] = _overrides

	return dict


func _from_dict(raw: Dictionary) -> void:
	if raw is not Dictionary:
		return
		
	value = raw.get("value", value)
	_overrides = raw.get("_editor_settings", _overrides)
	if raw.get("from_node"):
		var from_arr: Array = raw.get("from_node", [])
		connected_from.assign(from_arr)
	if raw.get("to_node"):
		var to_arr: Array = raw.get("to_node", [])
		connected_to.assign(to_arr)
