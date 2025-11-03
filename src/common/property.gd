class_name Property extends RefCounted

signal changed
signal value_changed(old_value: Variant, new_value: Variant)

var name: String = ""
var value: Variant = 0
var type: String = ""
var settings: Dictionary = {}
var _field: Field

## Tracks input connections to this property (nodes connecting TO this property)
var connected_from: Array[Dictionary] = []  # [{node_name: String, property_name: String, port: int}]

## Tracks output connections from this property (nodes this property connects TO)
var connected_to: Array[Dictionary] = []  # [{node_name: String, property_name: String, port: int}]

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
	type = ptype
	settings = psettings


func bind_field(field: Field) -> void:
	_field = field
	_field.set_value(value)
	_field.field_changed.connect(on_field_changed)


func set_value(new_value: Variant) -> void:
	var old_value: Variant = value
	value = new_value

	#changed.emit()
	value_changed.emit(old_value, new_value)


func get_value() -> Variant:
	return value


func get_settings_value(skey: String, default_value: Variant) -> Variant:
	return settings.get(skey, default_value)


func get_display_name() -> String:
	return Util.to_readable_name(settings.get("label", name))


func get_category() -> String:
	return settings.get("category", "General")


func is_intput_connected() -> bool:
	return connected_from.size() > 0


func is_output_connected() -> bool:
	return connected_to.size() > 0


func is_port_connected() -> bool:
	return is_intput_connected() or is_output_connected()


func add_connection_from(node_name: String, property_name: String, port: int) -> void:
	var conn = {"node_name": node_name, "property_name": property_name, "port": port}
	if conn not in connected_from:
		connected_from.append(conn)


func add_connection_to(node_name: String, property_name: String, port: int) -> void:
	var conn = {"node_name": node_name, "property_name": property_name, "port": port}
	if conn not in connected_to:
		connected_to.append(conn)


func remove_connection_from(node_name: String, port: int) -> void:
	connected_from = connected_from.filter(
		func(c): return not (c["node_name"] == node_name and c["port"] == port)
	)


func remove_connection_to(node_name: String, port: int) -> void:
	connected_to = connected_to.filter(
		func(c): return not (c["node_name"] == node_name and c["port"] == port)
	)


func clear_connections() -> void:
	connected_from.clear()
	connected_to.clear()


func on_field_changed() -> void:
	set_value(_field.get_value())
