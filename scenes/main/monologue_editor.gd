class_name MonologueEditor extends Control

@export var welcome_window: WelcomeWindow
@export var graph_switcher: GraphEditSwitcher

@onready var graph_node_picker: GraphNodePicker = %GraphNodePicker
@onready var inspector_panel_node: InspectorPanel = %Inspector
@onready var run_window := preload("res://scenes/run/run_window.tscn")
@onready var dimmer := $"../../../Dimmer"
@onready var characters_section := %Characters
@onready var variables_section := %Variables
@onready var items_section := %Items


func _ready():
	get_tree().auto_accept_quit = false  # quit handled by _close_tab()
	#welcome_window.show()

	GlobalSignal.add_listener("add_graph_node", add_node_from_global)
	GlobalSignal.add_listener("select_new_node", _select_new_node)
	GlobalSignal.add_listener("load_project", load_project)
	GlobalSignal.add_listener("test_trigger", test_project)
	GlobalSignal.add_listener("save", save)

	StorylineManager.create_storyline()

	# Load the editor sections after creating the storyline
	await get_tree().process_frame
	load_editor_sections()


func _select_new_node() -> void:
	graph_node_picker.open_for_node("", -1, null, null, null, true)


func _input(event):
	if event.is_action_pressed("Save"):
		save()

	if event.is_action_pressed("ui_undo"):
		var focus_owner: Control = get_viewport().gui_get_focus_owner()
		if focus_owner:
			focus_owner.release_focus()
		StorylineManager.get_active_storyline().history.undo()
		#focus_owner.grab_focus()

	if event.is_action_pressed("ui_redo"):
		StorylineManager.get_active_storyline().history.redo()


## Function callback for when the user wants to add a node from global context.
## Used by header menu and graph node selector (picker).
func add_node_from_global(node_type: String, picker: GraphNodePicker = null):
	var storyline := StorylineManager.get_active_storyline()
	if storyline == null:
		push_warning("No active storyline available to add node.")
		return

	var graph_edit: MonologueGraphEdit = graph_switcher.graph_edits.get(storyline.id)
	if graph_edit == null:
		graph_switcher.refresh()
		graph_edit = graph_switcher.graph_edits.get(storyline.id)
	if graph_edit == null:
		push_warning("Graph edit not initialized for the active storyline.")
		return

	var node := storyline.create_node(node_type)
	if node == null:
		push_warning("Unable to create node of type '%s'." % node_type)
		return

	var target_position := Vector2.ZERO
	if picker and picker.graph_release is Vector2:
		target_position = picker.graph_release
	else:
		target_position = graph_edit.scroll_offset / graph_edit.zoom

	var position_property := node.get_property("position")
	if position_property:
		position_property.set_value(target_position)

	graph_edit.add_graph_node_view(node)


func get_root_dict(node_list: Array) -> Dictionary:
	for node in node_list:
		if node.get("$type") == "NodeRoot":
			return node
	return {}


func load_project(path: String, new_graph: bool = false) -> void:
	var file = FileAccess.open(path, FileAccess.READ)
	if not file or graph_switcher.is_file_opened(path):
		return

	if new_graph:
		graph_switcher.new_graph_edit()
	graph_switcher.current.file_path = path  # set path first before tab creation

	var data = {}
	var text = file.get_as_text()
	if text:
		data = JSON.parse_string(text)
	if not data:
		save()

	var converter := NodeConverter.new()
	graph_switcher.current.languages = data.get("Languages", [])  # load language before tab
	graph_switcher.add_tab(path.get_file())
	graph_switcher.current.clear()
	graph_switcher.current.name = path.get_file().trim_suffix(".json")

	# Load characters and variables into storyline properties
	var storyline = StorylineManager.get_active_storyline()
	if storyline:
		var characters_data = converter.convert_characters(data.get("Characters", []))
		var variables_data = data.get("Variables", [])

		# Convert old character format to new simplified format
		var simple_characters = []
		for char in characters_data:
			if char is Dictionary:
				var char_name = ""
				if char.has("Character") and char["Character"] is Dictionary:
					char_name = char["Character"].get("Name", "")
				elif char.has("name"):
					char_name = char.get("name", "")

				if not char_name.is_empty():
					simple_characters.append({"name": char_name})

		# Convert old variable format to new simplified format if needed
		var simple_variables = []
		for variable in variables_data:
			if variable is Dictionary:
				var var_name = variable.get("name", variable.get("Name", ""))
				var var_type = variable.get("type", "String")
				var var_value = variable.get("value", variable.get("Value", ""))
				if not var_name.is_empty():
					simple_variables.append(
						{"name": var_name, "type": var_type, "value": var_value}
					)

		storyline.set_property_value("characters", simple_characters)
		storyline.set_property_value("variables", simple_variables)

	graph_switcher.current.data = data

	var node_list = data.get("ListNodes")
	_load_nodes(node_list)
	_connect_nodes(node_list)
	graph_switcher.add_root()
	graph_switcher.current.update_node_positions()
	GlobalSignal.emit("load_successful", [path])

	load_editor_sections()


func load_editor_sections() -> void:
	var storyline := StorylineManager.get_active_storyline()
	if storyline:
		characters_section.load_items(storyline.get_property("characters"), storyline)
		variables_section.load_items(storyline.get_property("variables"), storyline)
		items_section.load_items(storyline.get_property("items"), storyline)


func save():
	var storyline = StorylineManager.get_active_storyline()
	var dict: Dictionary = storyline._to_dict()
	dict["editor_version"] = ProjectSettings.get_setting("application/config/version")
	print(JSON.stringify(dict, "\t", true, true))
	return
	var data = JSON.stringify(dict, "\t", false, true)
	if data:
		var path = graph_switcher.current.file_path
		var file = FileAccess.open(path, FileAccess.WRITE)
		file.store_string(data)
		file.close()
		graph_switcher.current.update_version()
		graph_switcher.update_save_state()

	storyline.is_dirty = false


func test_project(from_node: Variant = null):
	if graph_switcher.current.file_path:
		await save()
		var window: RunWindow = run_window.instantiate()
		window.file_path = graph_switcher.current.file_path
		window.from_node = from_node
		window.tree_exited.connect(dimmer.hide)
		get_tree().root.add_child(window)
		dimmer.show()


func _connect_nodes(node_list: Array) -> void:
	for node in node_list:
		var current_node = graph_switcher.current.get_node_by_id(node.get("ID", ""))
		if current_node:
			current_node._load_connections(node)


func _load_nodes(node_list: Array) -> void:
	var converter = NodeConverter.new()
	for node in node_list:
		var data = converter.convert_node(node)
		var node_type = data.get("$type").trim_prefix("Node")
		if node_type == "Option":
			# option data gets sent to the base_options dictionary
			graph_switcher.current.base_options[data.get("ID")] = data
		else:
			var node_scene = Constants.NODE_SCENES.get(node_type)
			if node_scene:
				var node_instance = node_scene.instantiate()
				node_instance.id.value = data.get("ID")
				graph_switcher.current.add_child(node_instance, true)
				node_instance._from_dict(data)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		get_viewport().gui_release_focus()
		#graph_switcher.is_closing_all_tabs = true
		#graph_switcher._on_tab_close_pressed(0)


func _on_button_sparkle_pressed() -> void:
	# TODO: Create an undo/redo action for every nodes. Need to pack undo/redo action into one action.
	pass
	#graph_switcher.current.set_block_signals(true)
	#graph_switcher.current.arrange_nodes()
	#graph_switcher.current.set_block_signals.bind(false).call_deferred()


func _on_button_settings_pressed() -> void:
	GlobalSignal.emit("show_current_config")
