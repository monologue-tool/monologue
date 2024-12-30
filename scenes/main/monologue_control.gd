class_name MonologueControl extends Control


@export var tab_bar: TabBar

var dialog = {}
var dialog_for_localisation = []

const UNSAVED_FILE_SUFFIX: String = "*"

@onready var graph_edit_inst = preload("res://common/layouts/graph_edit/monologue_graph_edit.tscn")
@onready var prompt_scene = preload("res://common/windows/prompt_window/prompt_window.tscn")

@onready var graph_edits: Control = $MarginContainer/MainContainer/GraphEditsArea/GraphEditSwitcher/GraphEditZone/GraphEdits
@onready var side_panel_node = %SidePanel
@onready var graph_node_selecter = $GraphNodePicker
@onready var file_dialog = $FileDialog
@onready var graph: GraphEditSwitcher = %GraphEditSwitcher
@onready var welcome: WelcomeWindow = $WelcomeWindow

var root_scene = GlobalVariables.node_dictionary.get("Root")
var live_dict: Dictionary

## Set to true if a file operation is triggered from Header instead of WelcomeWindow.
var is_header_file_operation: bool = false
var is_closing_all_tabs: bool = false

var initial_pos = Vector2(40,40)
var option_index = 0
var node_index = 0
var all_nodes_index = 0
var prev_tab: int = 0

var picker_from_node
var picker_from_port
var picker_position


func _ready():
	get_tree().auto_accept_quit = false  # quit handled by _close_tab()
	welcome.show()
	
	GlobalSignal.add_listener("add_graph_node", add_node_from_global)
	GlobalSignal.add_listener("select_new_node", _select_new_node)
	GlobalSignal.add_listener("load_project", load_project)
	GlobalSignal.add_listener("test_trigger", test_project)
	GlobalSignal.add_listener("save", save)


func _select_new_node() -> void:
	graph_node_selecter.show()


func _input(event):
	if event.is_action_pressed("Save"):
		save()


func _to_dict() -> Dictionary:
	var list_nodes: Array[Dictionary] = []
	var graph_edit = graph.current
	
	# compile all node data of the current graph edit
	for node in graph_edit.get_nodes():
		if node.is_queued_for_deletion():
			continue
		
		# if side panel is still open, release the focus so that some
		# text controls trigger the focus_exited() signal to update
		if side_panel_node.visible and side_panel_node.selected_node == node:
			var refocus = get_viewport().gui_get_focus_owner()
			if refocus:
				refocus.release_focus()
				refocus.grab_focus()
		
		list_nodes.append(node._to_dict())
		if node.node_type == "NodeChoice":
			for child in node.get_children():
				list_nodes.append(child._to_dict())
	
	# build data for dialogue speakers
	var characters = graph.current.speakers
	if characters.size() <= 0:
		characters.append({
			"ID": IDGen.generate(5),
			"Protected": true,
			"Character": {
				"Name": "_NARRATOR"
			},
			"EditorIndex": 0
		})
	
	return {
		"EditorVersion": ProjectSettings.get_setting("application/config/version", "unknown"),
		"RootNodeID": get_root_dict(list_nodes).get("ID"),
		"ListNodes": list_nodes,
		"Characters": characters,
		"Variables": graph.current.variables
	}


## Function callback for when the user wants to add a node from global context.
## Used by header menu and graph node selector (picker).
func add_node_from_global(node_type: String, picker: GraphNodePicker = null):
	picker_from_node = picker.from_node
	picker_from_port = picker.from_port
	
	var new_nodes: Array[MonologueGraphNode] = graph.current.add_node(node_type, true)
	graph.current.pick_and_center(new_nodes, picker)


func get_root_dict(node_list: Array) -> Dictionary:
	for node in node_list:
		if node.get("$type") == "NodeRoot":
			return node
	return {}


func load_project(path: String, new_graph: bool = false) -> void:
	var file = FileAccess.open(path, FileAccess.READ)
	if file and not graph.is_file_opened(path):
		if new_graph:
			graph.new_graph_edit()
		graph.current.file_path = path  # set path first before tab creation
		graph.add_tab(path.get_file())
		
		var data = {}
		var text = file.get_as_text()
		if text: data = JSON.parse_string(text)
		if not data:
			data = _to_dict()
			save()
		
		var converter := NodeConverter.new()
		
		graph.current.clear()
		graph.current.name = path.get_file().trim_suffix(".json")
		graph.current.speakers = converter.convert_characters(data.get("Characters"))
		graph.current.variables = data.get("Variables")
		graph.current.data = data
		
		var node_list = data.get("ListNodes")
		_load_nodes(node_list)
		_connect_nodes(node_list)
		graph.add_root()
		graph.current.update_node_positions()


func save():
	var data = JSON.stringify(_to_dict(), "\t", false, true)
	if data:
		var path = graph.current.file_path
		var file = FileAccess.open(path, FileAccess.WRITE)
		file.store_string(data)
		file.close()
		graph.current.update_version()
		graph.update_save_state()


func test_project(from_node: Variant = null):
	if graph.current.file_path:
		await save()
		var test_window: TestWindow = TestWindow.new(graph.current.file_path, from_node)
		get_tree().root.add_child(test_window)


func _connect_nodes(node_list: Array) -> void:
	for node in node_list:
		var current_node = graph.current.get_node_by_id(node.get("ID", ""))
		if current_node:
			current_node._load_connections(node)


func _load_nodes(node_list: Array) -> void:
	var converter = NodeConverter.new()
	for node in node_list:
		var data = converter.convert_node(node)
		var node_type = data.get("$type").trim_prefix("Node")
		if node_type == "Option":
			# option data gets sent to the base_options dictionary
			graph.current.base_options[data.get("ID")] = data
		else:
			var node_scene = GlobalVariables.node_dictionary.get(node_type)
			if node_scene:
				var node_instance = node_scene.instantiate()
				node_instance.id.value = data.get("ID")
				graph.current.add_child(node_instance, true)
				node_instance._from_dict(data)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		get_viewport().gui_release_focus()
		graph.is_closing_all_tabs = true
		graph._on_tab_close_pressed(0)
