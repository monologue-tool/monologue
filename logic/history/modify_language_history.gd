class_name ModifyLanguageHistory extends MonologueHistory


## Graph edit which owns the languages.
var graph_edit: MonologueGraphEdit
## Node path to the language option that is being modified.
var node_name: String
## Previous language name.
var before_name: String
## Name of the language to be modified to.
var after_name: String


func _init(graph: MonologueGraphEdit, path: String,
		old_name: String, new_name: String) -> void:
	graph_edit = graph
	node_name = path
	before_name = old_name
	after_name = new_name
	
	_undo_callback = revert
	_redo_callback = change


func change() -> void:
	_set_name(after_name)


func revert() -> void:
	_set_name(before_name)


func _set_name(locale: String) -> void:
	var option = GlobalVariables.language_switcher.vbox.get_node(node_name)
	var index = option.get_index()
	option.set_language_name(locale)
	graph_edit.languages[index] = locale
	GlobalSignal.emit("show_languages")
