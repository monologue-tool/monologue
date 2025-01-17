class_name AddLanguageHistory extends MonologueHistory


## Graph edit which owns the languages.
var graph_edit: MonologueGraphEdit
## Node name of the language option that is being added.
var node_name: String
## Name of the language to be added.
var language_name: String


func _init(graph: MonologueGraphEdit, locale: String = "") -> void:
	graph_edit = graph
	language_name = locale
	
	_undo_callback = delete_language_option
	_redo_callback = add_language_option


func add_language_option() -> void:
	var option = GlobalVariables.language_switcher.add_language(language_name)
	if node_name:
		option.name = node_name
	else:
		node_name = option.name
	graph_edit.languages = GlobalVariables.language_switcher.get_languages().keys()
	GlobalSignal.emit("show_languages")


func delete_language_option() -> void:
	var node = GlobalVariables.language_switcher.vbox.get_node(node_name)
	node.queue_free()
	graph_edit.languages.erase(language_name)
	GlobalSignal.emit("show_languages")
	
	# update selection if selected_index exceeds language count
	var languages = GlobalVariables.language_switcher.get_languages()
	if GlobalVariables.language_switcher.selected_index >= languages.size():
		var select = languages.values()[languages.size() - 1]
		GlobalVariables.language_switcher._on_option_selected(select)
