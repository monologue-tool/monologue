class_name MonologueInspector extends Node

var _properties: Array = []
var _node: Node


func bind_node(node: Node) -> void:
	_node = node


## Create a property
##
##
##
func add_property(property_name: String, property_data: Dictionary) -> void:
	if has_property(property_name):
		push_error("Property %s already exist." % property_name)
		return

	property_data.merge({"name": property_name})
	_properties.append(property_data)


func has_property(property_name: String) -> bool:
	var candidates: Array = _properties.filter(func(p): return p.get("name") == property_name)
	return candidates.size() <= 0


func get_property(property_name: String) -> Variant:
	var candidates: Array = _properties.filter(func(p): return p.get("name") == property_name)
	if candidates.size() <= 0:
		return null

	return candidates.get(0)


func update_property(property_name: String, property_data: Dictionary) -> void:
	if not has_property(property_name):
		push_warning("Cannot find property %s." % property_name)
		return


func _get_inspector_property_list() -> Array:
	return _properties
