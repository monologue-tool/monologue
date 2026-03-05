class_name Property extends RefCounted

signal value_changed(old_value: Variant, new_value: Variant)

var name: String = ""
var value: Variant = 0
var type: String = ""
var _settings: Dictionary = {}
var settings: Dictionary = {}
var descriptor
var _bindings: Array = []

const DEFAULT_SETTINGS := {
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

## Tracks input connections to this property
var connected_from: Array = []

## Tracks output connections from this property
var connected_to: Array = []

## Property Settings:
## - visible_in_graph: Whether property shows as a row in graph node view
## - visible_in_inspector: Whether property shows in inspector panel
## - editable: Whether property value can be edited (enforced in inspector)
## - exposed: Whether property has input port (left side) for receiving connections
## - export: Whether property has output port (right side) for sending connections
## - is_main_property: Whether this is the main connectable property of the node


func _init(pname: String, pvalue: Variant, ptype: String, psettings: Dictionary = {}) -> void:
	name = pname
	value = pvalue.call() if pvalue is Callable else pvalue
	type = ptype
	descriptor = FieldBucket.get_descriptor(ptype)
	_settings = DEFAULT_SETTINGS.duplicate(true)
	if descriptor and descriptor.default_settings:
		_settings.merge(descriptor.default_settings, true)
	if psettings:
		_settings.merge(psettings, true)
	if not _settings.get("category"):
		_settings["category"] = DEFAULT_SETTINGS["category"]
	if _settings.get("label", "") == "":
		_settings.erase("label")


func bind_field(field: Field, target_owner: InspectableObject = null):
	if not is_instance_valid(field):
		return null
	if not field.is_inside_tree():
		field.tree_entered.connect(
			_on_field_tree_entered.bind(field, target_owner), CONNECT_ONE_SHOT
		)
		return null
	var binding = FieldBucket.bind(self, field, target_owner)
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


func get_settings() -> Dictionary:
	var merged_settings: Dictionary = settings.duplicate(true)
	merged_settings.merge(_settings)
	return merged_settings


func has_settings(skey) -> bool:
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


func add_connection_from(node_id: String, property_name: String) -> void:
	var conn = {"node_id": node_id, "property_name": property_name}
	if conn not in connected_from:
		connected_from.append(conn)


func add_connection_to(node_id: String, property_name: String) -> void:
	var conn = {"node_id": node_id, "property_name": property_name}
	if conn not in connected_to:
		connected_to.append(conn)


func remove_connection_from(node_id: String, property_name: String) -> void:
	connected_from = connected_from.filter(
		func(c): return not (c["node_id"] == node_id and c["property_name"] == property_name)
	)


func remove_connection_to(node_id: String, property_name: String) -> void:
	connected_to = connected_to.filter(
		func(c): return not (c["node_id"] == node_id and c["property_name"] == property_name)
	)


func clear_connections() -> void:
	connected_from.clear()
	connected_to.clear()


func refresh_bindings() -> void:
	_bindings = _bindings.filter(func(binding): return binding and binding.is_active())
	for binding in _bindings:
		binding.refresh()


func get_descriptor():
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

	if not settings.is_empty():
		dict["_editor_settings"] = settings

	return dict


func _from_dict(raw: Dictionary) -> void:
	if raw is not Dictionary:
		return
		
	value = raw.get("value", value)
	settings = raw.get("_editor_settings", settings)
	if raw.get("from_node"):
		connected_from = raw.get("from_node", connected_from)
	if raw.get("to_node"):
		connected_to = raw.get("to_node", connected_to)
