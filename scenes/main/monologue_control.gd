class_name MonologueControl extends Control


@onready var graph_switcher: GraphEditSwitcher = %GraphEditSwitcher
@onready var side_panel_node: SidePanel = %SidePanel


func _ready():
	get_tree().auto_accept_quit = false  # quit handled by _close_tab()
	$WelcomeWindow.show()
	
	GlobalSignal.add_listener("add_graph_node", add_node_from_global)
	GlobalSignal.add_listener("select_new_node", _select_new_node)
	GlobalSignal.add_listener("refresh", refresh)
	GlobalSignal.add_listener("load_project", load_project)
	GlobalSignal.add_listener("test_trigger", test_project)
	GlobalSignal.add_listener("save", save)


func _select_new_node() -> void:
	$GraphNodePicker.show()


func _input(event):
	if event.is_action_pressed("Save"):
		save()


func _to_dict() -> Dictionary:
	var list_nodes: Array[Dictionary] = []
	
	# compile all node data of the current graph edit
	for node in graph_switcher.current.get_nodes():
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
	var characters = graph_switcher.current.speakers
	if characters.size() <= 0:
		characters.append({
			"Reference": "_NARRATOR",
			"ID": 0
		})
	
	return {
		"EditorVersion": ProjectSettings.get_setting("application/config/version", "unknown"),
		"RootNodeID": get_root_dict(list_nodes).get("ID"),
		"ListNodes": list_nodes,
		"Characters": characters,
		"Variables": graph_switcher.current.variables,
		"Languages": GlobalVariables.language_switcher.get_languages().keys()
	}


## Function callback for when the user wants to add a node from global context.
## Used by header menu and graph node selector (picker).
func add_node_from_global(node_type: String, picker: GraphNodePicker = null):
	var nodes: Array[MonologueGraphNode] = graph_switcher.current.add_node(node_type, true, picker)
	graph_switcher.current.pick_and_center(nodes, picker)


func get_root_dict(node_list: Array) -> Dictionary:
	for node in node_list:
		if node.get("$type") == "NodeRoot":
			return node
	return {}


func load_project(path: String, new_graph: bool = false) -> void:
	var file = FileAccess.open(path, FileAccess.READ)
	if file and not graph_switcher.is_file_opened(path):
		if new_graph:
			graph_switcher.new_graph_edit()
		
		var data = {}
		var text = file.get_as_text()
		if text: data = JSON.parse_string(text)
		if not data:
			data = _to_dict()
			save()
		
		graph_switcher.current.file_path = path  # set path first before tab creation
		graph_switcher.current.languages = data.get("Languages", [])  # load language before tab
		graph_switcher.add_tab(path.get_file())
		graph_switcher.current.clear()
		graph_switcher.current.name = path.get_file().trim_suffix(".json")
		graph_switcher.current.speakers = data.get("Characters")
		graph_switcher.current.variables = data.get("Variables")
		graph_switcher.current.data = data
		
		var node_list = data.get("ListNodes")
		_load_nodes(node_list)
		_connect_nodes(node_list)
		graph_switcher.add_root()
		graph_switcher.current.update_node_positions()


## Reload the current graph edit and side panel values.
func refresh() -> void:
	for node in graph_switcher.current.get_nodes():
		node.reload_preview()
	if side_panel_node.visible:
		side_panel_node.on_graph_node_selected(side_panel_node.selected_node, true)


func save():
	var data = JSON.stringify(_to_dict(), "\t", false, true)
	if data:
		var path = graph_switcher.current.file_path
		var file = FileAccess.open(path, FileAccess.WRITE)
		file.store_string(data)
		file.close()
		graph_switcher.current.update_version()
		graph_switcher.update_save_state()
	


func test_project(from_node: Variant = null):
	if graph_switcher.current.file_path:
		await save()
		var test_window: TestWindow = TestWindow.new(graph_switcher.current.file_path, from_node)
		get_tree().root.add_child(test_window)


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
		graph_switcher.is_closing_all_tabs = true
		graph_switcher._on_tab_close_pressed(0)
