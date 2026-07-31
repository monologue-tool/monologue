class_name GraphNodeRow

var _key: String = ""
var _type: String = ""
var _property_name: String = ""
var _enable_left_port: bool = false
var _enable_right_port: bool = false
## If non-empty, this row represents a sub-port of a list item.
## Format: "property_name:item_id"
var sub_property_id: String = ""
## Port size: "normal" or "large"
var port_size: String = "normal"


func _init(
	key: String, type: String = "", enable_left_port: bool = false, enable_right_port: bool = true
) -> void:
	_key = key
	_type = type
	_enable_left_port = enable_left_port
	_enable_right_port = enable_right_port


func get_key() -> String:
	return _key


func get_type() -> String:
	return _type


## Returns the connection-level identifier for this row.
## For sub-ports it is the composite "property:item_id"; otherwise the property name.
func get_connection_name() -> String:
	if not sub_property_id.is_empty():
		return sub_property_id
	return _property_name
