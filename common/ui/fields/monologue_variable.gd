class_name MonologueVariable extends RefCounted

var name := Property.new(MonologueGraphNode.LINE)
var type := Property.new(MonologueGraphNode.DROPDOWN, {}, "Boolean")
var value := Property.new(MonologueGraphNode.TOGGLE, {}, false)

var index: int = -1
var graph: MonologueGraphEdit


func _init(graph_edit: MonologueGraphEdit) -> void:
	graph = graph_edit

	type.callers["set_items"] = [
		[
			{"id": 0, "text": "Boolean"},
			{"id": 1, "text": "Integer"},
			{"id": 2, "text": "String"},
		]
	]
	type.callers["set_icons"] = [
		{
			0: load("res://ui/assets/icons/bool_icon.png"),
			1: load("res://ui/assets/icons/int_icon.png"),
			2: load("res://ui/assets/icons/str_icon.png"),
		}
	]

	type.connect("shown", _type_morph)
	type.connect("change", change.bind("type"))
	name.connect("change", change.bind("name"))
	value.connect("change", change.bind("value"))


func change(_old_value: Variant, new_value: Variant, property: String) -> void:
	var old_list = graph.variables.value.duplicate(true)
	var new_list = graph.variables.value.duplicate(true)
	new_list[index][property.capitalize()] = new_value

	graph.undo_redo.create_action("Variables => %s" % new_value)
	graph.undo_redo.add_do_property(graph.variables, "value", new_list)
	graph.undo_redo.add_do_method(graph.variables.propagate.bind(new_list))
	graph.undo_redo.add_undo_property(graph.variables, "value", old_list)
	graph.undo_redo.add_undo_method(graph.variables.propagate.bind(old_list))
	graph.undo_redo.commit_action()


func get_property_names() -> PackedStringArray:
	return ["name", "type", "value"]


func _from_dict(dict: Dictionary) -> void:
	_type_morph()
	name.value = dict.get("Name")
	type.value = dict.get("Type")
	value.value = dict.get("Value")


func _to_dict() -> Dictionary:
	return {"Name": name.value, "Type": type.value, "Value": value.value}


func _type_morph(selected_type: String = type.value):
	match selected_type:
		"Boolean":
			value.morph(MonologueGraphNode.TOGGLE)
		"Integer":
			value.morph(MonologueGraphNode.SPINBOX)
		"String":
			value.morph(MonologueGraphNode.LINE)
