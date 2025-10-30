## Represents a row in a graph node with port configuration.
##
## GraphNodeRow defines a single row within a GraphNode, specifying the
## property key, type, and which ports (left/right) should be enabled
## for connections.
class_name GraphNodeRow

## The property key associated with this row.
var _key: String = ""

## The property type for this row.
var _type: String = ""

## Whether the left port is enabled for connections.
var _enable_left_port: bool = false

## Whether the right port is enabled for connections.
var _enable_right_port: bool = false


## Initializes a graph node row.
##
## [param key] The property key for this row.
## [br][br]
## [param type] The property type. Default is empty string.
## [br][br]
## [param enable_left_port] Whether to enable the left port. Default is false.
## [br][br]
## [param enable_right_port] Whether to enable the right port. Default is true.
func _init(
	key: String, type: String = "", enable_left_port: bool = false, enable_right_port: bool = true
) -> void:
	_key = key
	_type = type
	_enable_left_port = enable_left_port
	_enable_right_port = enable_right_port


## Returns the property key for this row.
func get_key() -> String:
	return _key


## Returns the property type for this row.
func get_type() -> String:
	return _type
