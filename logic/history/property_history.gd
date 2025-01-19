class_name PropertyHistory extends MonologueHistory


## Graph that owns the node whose properties have changed.
var graph_edit: MonologueGraphEdit
## Name of the graph node in the [member graph_edit].
var node_path: NodePath
## List of property changes to make on [member node_name].
var changes: Array[PropertyChange]
## Selected locale in the language switcher when this change was made.
var locale: String = LanguageSwitcher.DEFAULT_LOCALE


func _init(graph: MonologueGraphEdit, path: NodePath,
			change_list: Array[PropertyChange]) -> void:
	graph_edit = graph
	node_path = path
	changes = change_list
	
	_undo_callback = revert_properties
	_redo_callback = change_properties
	
	if GlobalVariables.language_switcher:
		locale = str(GlobalVariables.language_switcher.get_current_language())


func change_properties() -> void:
	reset_language()
	var node: MonologueGraphNode = graph_edit.get_node(node_path)
	for change in changes:
		set_property(node, change.property, change.after)
	_hide_unrelated_windows()
	
	GlobalSignal.emit.call_deferred("refresh")


func revert_properties() -> void:
	reset_language()
	var node: MonologueGraphNode = graph_edit.get_node(node_path)
	for change in changes:
		set_property(node, change.property, change.before)
	_hide_unrelated_windows()
	
	GlobalSignal.emit.call_deferred("refresh")


func reset_language() -> void:
	if GlobalVariables.language_switcher:
		GlobalVariables.language_switcher.select_by_locale(locale, false)


func set_property(node: Variant, property: String, value: Variant) -> void:
	node[property].propagate(value)
	node[property].value = value


func _hide_unrelated_windows() -> void:
	GlobalSignal.emit("close_character_edit")
