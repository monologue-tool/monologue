@icon("res://ui/assets/icons/root.svg")
class_name RootNode extends MonologueGraphNode


var characters := Property.new(LIST, {}, [])
var variables  := Property.new(LIST, {}, [])

var _character_references = []
var _variable_references = []


func _ready():
	node_type = "NodeRoot"
	super._ready()
	
	load_character(get_parent().speakers)
	characters.setters["add_callback"] = add_character
	characters.setters["get_callback"] = get_speakers
	characters.connect("preview", load_character)
	
	load_variables(get_parent().variables)
	variables.setters["add_callback"] = add_variable
	variables.setters["get_callback"] = get_variables
	variables.connect("preview", load_variables)


func add_character(data: Dictionary = {}) -> MonologueCharacter:
	var character = MonologueCharacter.new(self)
	if data:
		character._from_dict(data)
	character.idx.value = _character_references.size()
	character.character.setters["character_index"] = character.idx.value
	_character_references.append(character)
	return character


func add_variable(data: Dictionary = {}) -> MonologueVariable:
	var variable = MonologueVariable.new(self)
	if data:
		variable._from_dict(data)
	variable.index = _variable_references.size()
	_variable_references.append(variable)
	return variable


func get_speakers():
	return _character_references


func get_variables():
	return _variable_references


## Perform initial loading of speakers and set indexes correctly.
func load_character(new_character_list: Array):
	_character_references.clear()
	var ascending = func(a, b): return a.get("EditorIndex") < b.get("EditorIndex")
	new_character_list.sort_custom(ascending)
	for speaker_data in new_character_list:
		add_character(speaker_data)
	
	if _character_references.is_empty():
		var narrator = add_character()
		narrator.character.value["Name"] = "_NARRATOR"
		narrator.protected.value = true
		new_character_list.append(narrator._to_dict())
	
	characters.value = new_character_list
	get_graph_edit().speakers = new_character_list


func load_variables(new_variable_list: Array):
	_variable_references.clear()
	for variable in new_variable_list:
		add_variable(variable)
	variables.value = new_variable_list
	get_graph_edit().variables = new_variable_list


func _to_fields(_dict: Dictionary) -> void:
	pass  # speakers and variables are stored outside of root node
