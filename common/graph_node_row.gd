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
## Slot type this row's ports use. 0 means "work it out from [member _type]".
## Set for references, whose port type comes from what they point at rather than from
## the field type they all share.
var port_type_id: int = 0
## Slot type the outgoing side uses, when it is not the one the incoming side uses.
##
## A reroute takes in anything and gives back only what it was given, so its two sides are
## not the same type. 0 means both sides are alike, which is every other row.
var output_type_id: int = 0
## What the outgoing side shows in brackets, when it differs from the incoming one.
var output_type_label: String = ""
## What the outgoing side is drawn in, when it differs from the incoming one.
var output_color: Color = Color.TRANSPARENT
## What the row shows in brackets. Empty means "show [member _type]". A reference shows
## what it accepts -- "character" -- since every one of them would otherwise read
## "reference". The colour and the port type still come from [member _type].
var type_label: String = ""


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


## The bracketed text drawn next to the key.
func get_type_label() -> String:
	return type_label if not type_label.is_empty() else _type


## Returns the connection-level identifier for this row.
## For sub-ports it is the composite "property:item_id"; otherwise the property name.
func get_connection_name() -> String:
	if not sub_property_id.is_empty():
		return sub_property_id
	return _property_name
