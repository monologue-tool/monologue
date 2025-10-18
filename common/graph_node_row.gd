class_name GraphNodeRow

var _key: String = ""
var _value: String = ""
var _enable_left_port: bool = false
var _enable_right_port: bool = false


func _init(
	key: String, value: String = "", enable_left_port: bool = false, enable_right_port: bool = true
) -> void:
	_key = key
	_value = value
	_enable_left_port = enable_left_port
	_enable_right_port = enable_right_port


func get_key() -> String:
	return _key


func get_value() -> String:
	return _value
