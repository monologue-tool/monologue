class_name GraphNodeRow

var _content: String = ""
var _enable_left_port: bool = false
var _enable_right_port: bool = false


func _init(content: String, enable_left_port: bool = false, enable_right_port: bool = true) -> void:
	_content = content
	_enable_left_port = enable_left_port
	_enable_right_port = enable_right_port


func get_content() -> String:
	return _content
