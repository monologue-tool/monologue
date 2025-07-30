## Common abstract class for nodes that deal with variables.
class_name AbstractVariableNode extends MonologueGraphNode

var variable := Property.new(DROPDOWN)
var operator := Property.new(DROPDOWN, {}, "=")
var value := Property.new(LINE)

var last_boolean: bool
var last_number: float
var last_string: String


func _ready():
	variable.connect("preview", get_variable_label().set_text)
	operator.callers["set_items"] = [get_operator_options()]
	operator.connect("preview", get_operator_label().set_text)
	operator.connect("shown", value_morph)
	value.connect("preview", record_morph)
	super._ready()


func get_default_text(new_value: Variant, default: String) -> String:
	var is_not_string = new_value is not String
	return str(new_value) if is_not_string or new_value != "" else default


func get_variable_label() -> Label:
	return null


## Returns the variable's typestring from the graph edit.
func get_variable_type(variable_name: String) -> String:
	for data in get_graph_edit().variables.value:
		if data.get("Name") == variable_name:
			return data.get("Type")
	return ""


func get_operator_label() -> Label:
	return null


func get_operator_options() -> Array[Dictionary]:
	return [
		{"id": 0, "text": "="},
		{"id": 1, "text": "+="},
		{"id": 2, "text": "-="},
		{"id": 3, "text": "*="},
		{"id": 4, "text": "/="},
	]


func get_operator_disabler() -> PackedInt32Array:
	return [1, 2, 3, 4]


func get_value_label() -> Label:
	return null


## Reset the variable dropdown to the first value and return its type.
func reset_variable() -> String:
	if get_graph_edit().variables.value:
		variable.value = get_graph_edit().variables.value[0].get("Name")
		return get_graph_edit().variables.value[0].get("Type")
	else:
		variable.value = ""
		return ""


func record_morph(new_value: Variant):
	match typeof(new_value):
		TYPE_BOOL:
			last_boolean = new_value
		TYPE_INT, TYPE_FLOAT:
			last_number = new_value
		TYPE_STRING:
			last_string = new_value

	# display integer without decimals
	match get_variable_type(variable.value):
		"Integer":
			new_value = int(new_value) if new_value else 0
	get_value_label().text = str(new_value)


func value_morph(selected_name: Variant = variable.value) -> void:
	var selected_type = get_variable_type(selected_name)
	if not selected_type:
		selected_type = reset_variable()

	match selected_type:
		"Boolean":
			operator.invoke("disable_items", [get_operator_disabler()])
			value.morph(TOGGLE)
			value.value = last_boolean
			value.propagate(last_boolean, false)
			get_value_label().text = str(last_boolean)
		"Integer":
			operator.invoke("disable_items", [[]])
			value.morph(SPINBOX)
			value.value = int(last_number)
			value.propagate(int(last_number), false)
			get_value_label().text = str(int(last_number))
		"String":
			operator.invoke("disable_items", [get_operator_disabler()])
			value.morph(LINE)
			value.value = last_string
			value.propagate(last_string, false)
			get_value_label().text = get_default_text(last_string, "value")


func _update() -> void:
	variable.callers["set_items"] = [get_graph_edit().variables.value, "Name", "ID", "Type"]
	value_morph(variable.value)
	get_variable_label().text = get_default_text(variable.value, "variable")
	get_operator_label().text = get_default_text(operator.value, "operator")
	get_value_label().text = get_default_text(value.value, "value")
	super._update()
