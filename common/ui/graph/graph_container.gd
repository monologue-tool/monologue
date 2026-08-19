## Consists of a TabBar which allows the user to switch between GraphEdits.
## Saving and loading of GraphEdit data is handled by MonologueEditor.
class_name GraphContainer extends PanelContainer

var prompt_scene: PackedScene = preload("uid://bkreq3xdr7gxw")

@export var inspector_panel: InspectorPanel
@onready var graph: MonologueGraphEdit = %GraphEdit
@onready var snap_button: Button = %SnapButton
@onready var grid_button: Button = %GridButton
@onready var trail_container: PanelContainer = %TrailContainer
@onready var trail: HBoxContainer = %Trail

var _selected_nodes: Dictionary = {}
var _graph_offset: Dictionary = {}
var _is_applying_selection: bool = false
var _current_lang_prop: Property = null  # tracked to disconnect on storyline switch


func _ready() -> void:
	graph.selection_changed.connect(_on_graph_selection_changed)
	snap_button.pressed.connect(_on_snap_button_pressed)
	grid_button.pressed.connect(_on_grid_button_pressed)
	snap_button.button_pressed = ConfigManager.get_config("snap")
	grid_button.button_pressed = ConfigManager.get_config("show_grid")
	_on_snap_button_pressed()
	_on_grid_button_pressed()

	EventBus.request_nodes_selection.connect(_on_request_nodes_selection)
	EventBus.request_storyline_inspection.connect(_on_request_storyline_inspection)
	EventBus.storylines_changed.connect(_refresh_trail)
	EventBus.graph_snap.connect(_on_event_graph_snap)
	EventBus.graph_show_grid.connect(_on_event_show_grid)

	ProjectManager.project_loaded.connect(_on_project_loaded)


func _on_project_loaded() -> void:
	await get_tree().process_frame

	var storyline: StorylineDocument = ProjectManager.current_project.top_level_storylines()[0]
	load_storyline(storyline)
	EventBus.request_storyline_inspection.emit(storyline)


func load_storyline(storyline: StorylineDocument) -> void:
	_graph_offset[graph.storyline_id] = graph.scroll_offset
	
	_show_trail(storyline)
	graph.storyline_id = storyline.id
	graph.connection_manager = ConnectionManager.new(storyline)
	graph.refresh()
	graph.scroll_offset = _graph_offset.get(storyline.id, Vector2.ZERO)

	if (
		is_instance_valid(_current_lang_prop)
		and _current_lang_prop.value_changed.is_connected(_on_languages_changed)
	):
		_current_lang_prop.value_changed.disconnect(_on_languages_changed)

	_current_lang_prop = storyline.get_property("languages")
	if _current_lang_prop:
		_current_lang_prop.value_changed.connect(_on_languages_changed)
		EventBus.load_languages.emit(storyline.get_property_value("languages"), graph)

	var selection: Array[InspectableObject] = []
	selection.assign(_selected_nodes.get(storyline.id, []))

	var restored: Array[InspectableObject] = []
	for object: InspectableObject in selection:
		var node: InspectableNode = object as InspectableNode
		if node and is_instance_valid(node) and is_instance_valid(node.graph_view):
			graph.set_selected(node.graph_view)
			restored.append(node)

	EventBus.request_objects_inspection.emit(restored)


func _refresh_trail() -> void:
	var project: MonologueProject = ProjectManager.current_project
	var open_document: StorylineDocument = (
		project.get_storyline(graph.storyline_id) if project else null
	)
	if open_document:
		_show_trail(open_document)


func is_section() -> bool:
	var storyline: StorylineDocument = ProjectManager.current_project.get_storyline(graph.storyline_id)
	var path: Array[StorylineDocument] = _path_to(storyline)
	return path.size() > 1


## Hidden for a storyline at the top, which has nowhere to go back to.
func _show_trail(document: StorylineDocument) -> void:
	for child: Node in trail.get_children():
		trail.remove_child(child)
		child.queue_free()

	var path: Array[StorylineDocument] = _path_to(document)
	trail_container.visible = path.size() > 1
	if not trail.visible:
		return

	for step: StorylineDocument in path:
		if trail.get_child_count() > 0:
			var separator: Label = Label.new()
			separator.text = "/"
			trail.add_child(separator)

		var crumb: Control
		crumb = Button.new()
		crumb.text = step.name
		crumb.disabled = step == document
		crumb.pressed.connect(EventBus.request_storyline_inspection.emit.bind(step))
		trail.add_child(crumb)


## Remembers where it has been, so a parent pointing back down the tree stops the walk.
func _path_to(document: StorylineDocument) -> Array[StorylineDocument]:
	var project: MonologueProject = ProjectManager.current_project
	var path: Array[StorylineDocument] = []
	var walked: Dictionary[String, bool] = {}
	var step: StorylineDocument = document

	while step != null and not walked.has(step.id):
		walked[step.id] = true
		path.push_front(step)
		step = project.get_storyline(step.parent) if project else null
	return path


func _on_languages_changed(_old: Variant, new_value: Variant) -> void:
	EventBus.load_languages.emit(new_value, graph)


## Hands the whole selection to the inspector. One node is not a special case, just a
## selection of one, so there is nothing here to branch on.
func _on_graph_selection_changed(nodes: Array[InspectableObject]) -> void:
	if _is_applying_selection:
		return

	# Several nodes go straight to the inspector. A single one also records an undo
	# step, so stepping back through the graph works.
	if nodes.size() > 1:
		EventBus.request_objects_inspection.emit(nodes)
		return

	request_node_selection(nodes)


func _on_request_nodes_selection(
	nodes: Array[InspectableObject], storyline_id: String, skip_history: bool = false
) -> void:
	if storyline_id != graph.storyline_id:
		return
	request_node_selection(nodes, skip_history)


func _on_request_storyline_inspection(storyline: StorylineDocument) -> void:
	if graph.storyline_id == storyline.id:
		return

	load_storyline(storyline)


func request_node_selection(nodes: Array[InspectableObject], skip_history: bool = false) -> void:
	if _is_applying_selection:
		return

	var current_nodes: Array[InspectableObject] = []
	current_nodes.assign(_selected_nodes.get(graph.storyline_id, []))

	var needs_selection_update: bool = current_nodes != nodes
	if not needs_selection_update:
		# Same set, but the graph may have lost the highlight. Put it back.
		for object: InspectableObject in nodes:
			var node: InspectableNode = object as InspectableNode
			if node and is_instance_valid(node.graph_view) and not node.graph_view.selected:
				needs_selection_update = true
				break

	if not needs_selection_update and inspector_panel.current_objects == nodes:
		return

	var history: CommandManager = ProjectManager.current_project.command_manager
	if skip_history or not history:
		_apply_selection(nodes, graph.storyline_id)
		return

	history.execute(
		NodeSelectionCommand.new(graph.storyline_id, current_nodes, nodes, _apply_selection)
	)


func _apply_selection(nodes: Array[InspectableObject], storyline_id: String) -> void:
	_is_applying_selection = true

	if nodes.is_empty():
		_selected_nodes.erase(storyline_id)
	else:
		_selected_nodes[storyline_id] = nodes

	# set_selected() deselects everything else, so only the first call may use it. The
	# rest add to the selection.
	var is_first: bool = true
	for object: InspectableObject in nodes:
		var node: InspectableNode = object as InspectableNode
		if not node or not is_instance_valid(node.graph_view):
			continue
		if is_first:
			graph.set_selected(node.graph_view)
			is_first = false
		else:
			node.graph_view.selected = true

	EventBus.request_objects_inspection.emit(nodes)
	_is_applying_selection = false


func _on_add_node_btn_pressed() -> void:
	EventBus.enable_picker_mode.emit("", -1, null, null, null, true)


func _on_snap_button_pressed() -> void:
	graph.snapping_enabled = snap_button.button_pressed
	ConfigManager.set_config("snap", snap_button.button_pressed)


func _on_grid_button_pressed() -> void:
	graph.show_grid = grid_button.button_pressed
	ConfigManager.set_config("show_grid", grid_button.button_pressed)


func _on_event_graph_snap(enabled: bool) -> void:
	graph.snapping_enabled = enabled
	snap_button.button_pressed = enabled


func _on_event_show_grid(grid_visible: bool) -> void:
	graph.show_grid = grid_visible
	grid_button.button_pressed = grid_visible
