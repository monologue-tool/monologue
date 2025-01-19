class_name LanguageHistory extends MonologueHistory


## Graph edit which owns the languages.
var graph_edit: MonologueGraphEdit
## Dictionary of old node names to language names.
var old_references: Dictionary
## Dictionary of new node names to language names.
var new_references: Dictionary


func _init(graph: MonologueGraphEdit, old: Dictionary, new: Dictionary) -> void:
	graph_edit = graph
	# old and new params are dictionaries of language names to object reference
	old_references = _convert_to_node_reference(old)
	new_references = _convert_to_node_reference(new)
	
	_undo_callback = revert_language_list
	_redo_callback = change_language_list


func change_language_list() -> void:
	graph_edit.languages = new_references.values()
	pass


func revert_language_list() -> void:
	graph_edit.languages = old_references.values()
	pass


func _convert_to_node_reference(language_data: Dictionary) -> Dictionary:
	var new_dict = {}
	for language_name in language_data:
		new_dict[language_data.get(language_name).name] = language_name
	return new_dict
