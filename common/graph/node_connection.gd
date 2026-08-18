## One directed wire between two node ports.
##
## A value object: two instances describing the same wire are equal, so comparisons go
## through [method equals] rather than identity.
##
## A port may be a sub-port of a list item, such as one particular option of a choice
## node. That is the item id, kept beside the property name instead of glued into it.
## [method get_from_name] and [method get_to_name] produce the composite form the graph
## view and the connection dictionaries use.
class_name NodeConnection extends RefCounted

## Separates a property name from the list item it belongs to.
const ITEM_SEPARATOR: String = ":"
## Marks a sub-port standing for something computed rather than stored: an option node
## wired into a choice's list, or the exit a called function ran out at.
##
## Declared here because it is part of a saved wire's identity. It used to be spelled out
## in the graph view, which left a widget defining a persisted format.
const EXTERNAL_PREFIX: String = "ext_"

var from_node_id: String = ""
var from_property: String = ""
var from_item_id: String = ""
var to_node_id: String = ""
var to_property: String = ""
var to_item_id: String = ""


static func create(
	p_from_node_id: String,
	p_from_property: String,
	p_to_node_id: String,
	p_to_property: String,
	p_from_item_id: String = "",
	p_to_item_id: String = ""
) -> NodeConnection:
	var connection: NodeConnection = NodeConnection.new()
	connection.from_node_id = p_from_node_id
	connection.from_property = p_from_property
	connection.from_item_id = p_from_item_id
	connection.to_node_id = p_to_node_id
	connection.to_property = p_to_property
	connection.to_item_id = p_to_item_id
	return connection


## Names may carry an item id, as "choices:option-4F2K".
static func from_names(
	p_from_node_id: String, p_from_name: String, p_to_node_id: String, p_to_name: String
) -> NodeConnection:
	var from_parts: PackedStringArray = split_name(p_from_name)
	var to_parts: PackedStringArray = split_name(p_to_name)
	return create(
		p_from_node_id, from_parts[0], p_to_node_id, to_parts[0], from_parts[1], to_parts[1]
	)


## Splits "choices:option-4F2K" into ["choices", "option-4F2K"], and a plain name into
## [name, ""].
static func split_name(name: String) -> PackedStringArray:
	if ITEM_SEPARATOR in name:
		return name.split(ITEM_SEPARATOR, true, 1)
	return PackedStringArray([name, ""])


static func from_dict(data: Dictionary) -> NodeConnection:
	return create(
		str(data.get("from_node_id", "")),
		str(data.get("from_property", "")),
		str(data.get("to_node_id", "")),
		str(data.get("to_property", "")),
		str(data.get("from_item_id", "")),
		str(data.get("to_item_id", ""))
	)


func equals(other: NodeConnection) -> bool:
	return other != null and to_key() == other.to_key()


## Stable identity of this wire, used to keep duplicates out of the list.
func to_key() -> String:
	return "%s.%s->%s.%s" % [from_node_id, get_from_name(), to_node_id, get_to_name()]


func involves(node_id: String) -> bool:
	return from_node_id == node_id or to_node_id == node_id


## Source property, with its item id when the wire leaves one list item in particular.
func get_from_name() -> String:
	return _compose(from_property, from_item_id)


## Target property, with its item id when the wire lands on one list item in particular.
func get_to_name() -> String:
	return _compose(to_property, to_item_id)


func _to_dict() -> Dictionary:
	var dict: Dictionary = {
		"from_node_id": from_node_id,
		"from_property": from_property,
		"to_node_id": to_node_id,
		"to_property": to_property,
	}
	if not from_item_id.is_empty():
		dict["from_item_id"] = from_item_id
	if not to_item_id.is_empty():
		dict["to_item_id"] = to_item_id
	return dict


func _to_string() -> String:
	return to_key()


static func _compose(property_name: String, item_id: String) -> String:
	if item_id.is_empty():
		return property_name
	return "%s%s%s" % [property_name, ITEM_SEPARATOR, item_id]
