## Similar to MonologueVariable but allows reference to existing variables.
class_name MonologueArgument extends MonologueVariable


var last_boolean: bool
var last_number: float
var last_string: String


func _init(node: MonologueGraphNode):
	super(node)
	type.callers["set_items"][0].append({ "id": 3, "text": "Variable" })
	#type.callers["set_icons"][0][3] = load("res://ui/assets/icons/bool_icon.png")
	value.connect("preview", record_morph)


func change(_old_value: Variant, new_value: Variant, property: String) -> void:
	var old_list = bound_node.arguments.value.duplicate(true)
	var new_list = bound_node.arguments.value.duplicate(true)
	new_list[index][property.capitalize()] = new_value
	
	# bound_node can be deleted, so we need to use PropertyChange here
	graph.undo_redo.create_action("Arguments => %s" % new_value)
	var pc = PropertyChange.new("arguments", old_list, new_list)
	var ph = PropertyHistory.new(graph, graph.get_path_to(bound_node), [pc])
	graph.undo_redo.add_prepared_history(ph)
	graph.undo_redo.commit_action()


## Creates a representation of the argument in an HBoxContainer.
func create_representation(parent: Control) -> HBoxContainer:
	var representation = HBoxContainer.new()
	parent.add_child(representation)
	
	var name_label = Label.new()
	var name_text = name.value if name.value else "argument"
	name_label.text = "  #%d: %s" % [representation.get_index(), name_text]
	representation.add_child(name_label)
	
	var type_label = Label.new()
	type_label.text = "[%s]" % type.value if type.value else "type"
	representation.add_child(type_label)
	
	var value_label = Label.new()
	value_label.theme_type_variation = "Label_NodeValue"
	value_label.text = str(value.value) if value.value is not String or \
			value.value != "" else "value"
	representation.add_child(value_label)
	
	return representation


## Record the argument value so field morphing will populate correct value type.
func record_morph(new_value: Variant) -> void:
	match typeof(new_value):
		TYPE_BOOL:
			last_boolean = new_value
		TYPE_INT, TYPE_FLOAT:
			last_number = new_value
		TYPE_STRING:
			last_string = new_value


## Reset the value if the argument value is not matching the type.
func reset_value():
	match type.value:
		"Boolean":
			if value.value is not bool:
				value.value = last_boolean
		"Integer":
			if value.value is not float and value.value is not int:
				value.value = last_number
		_:
			if value.value is not String:
				value.value = last_string


func _type_morph(selected_type: String = type.value):
	if selected_type == "Variable":
		value.callers["set_items"] = [graph.variables, "Name", "ID", "Type"]
		if graph.variables and value.value is not String:
			value.value = graph.variables[0].get("Name")
		value.morph(MonologueGraphNode.DROPDOWN)
	else:
		value.callers.erase("set_items")
		super._type_morph(selected_type)
	
	reset_value()
	value.propagate(value.value, false)
