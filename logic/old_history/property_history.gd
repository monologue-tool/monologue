class_name PropertyHistory extends MonologueHistory

## Graph that owns the node whose properties have changed.
var graph_edit: MonologueGraphEdit
## Name of the graph node in the [member graph_edit].
var node_path: NodePath
## List of property changes to make on [member node_name].
var changes: Array[PropertyChange]
## Selected locale in the language switcher when this change was made.
var locale: String = LanguageSwitcher.DEFAULT_LOCALE


func _init(graph: MonologueGraphEdit, path: NodePath, change_list: Array[PropertyChange]) -> void:
	graph_edit = graph
	node_path = path
	changes = change_list

	_undo_callback = revert_properties
	_redo_callback = change_properties

	if GlobalVariables.language_switcher:
		locale = str(GlobalVariables.language_switcher.get_current_language())


func change_properties() -> void:
	var language := str(GlobalVariables.language_switcher.get_current_language())
	reset_language()
	var node = graph_edit.get_node(node_path)
	for change in changes:
		set_property(node, change.property, change.after)
	_hide_unrelated_windows()

	refresh_properties(node, language)


func revert_properties() -> void:
	var language := str(GlobalVariables.language_switcher.get_current_language())
	reset_language()
	var node = graph_edit.get_node(node_path)
	for change in changes:
		set_property(node, change.property, change.before)
	_hide_unrelated_windows()

	refresh_properties(node, language)


func reset_language() -> void:
	if GlobalVariables.language_switcher:
		GlobalVariables.language_switcher.select_by_locale(locale, false)


func set_property(node: Variant, property: String, value: Variant) -> void:
	node[property].propagate(value)
	node[property].value = value


func refresh_properties(node: Variant, language: String) -> void:
	var properties: PackedStringArray = []
	if node is MonologueGraphNode:
		# if language is the same, we can do partial refresh with given properties
		# otherwise, full refresh so other controls can reflect the language change
		if locale == language:
			properties = changes.map(func(c): return c.property)
	else:
		properties = changes.map(func(c): return c.property)
	GlobalSignal.emit.call_deferred("refresh", [node, properties])


func _hide_unrelated_windows() -> void:
	GlobalSignal.emit("close_character_edit")
