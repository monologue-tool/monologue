class_name MonologueEditor extends Control

const STORYLINE_EXTENSIONS: Array = ["*.mnlg,*.json;Storyline Document"]

@export var welcome_window: WelcomeWindow
@export var graph_container: GraphContainer
@export var file_dialog: GlobalFileDialog

@onready var graph_node_picker: GraphNodePicker = %GraphNodePicker
@onready var inspector_panel_node: InspectorPanel = %Inspector


func _ready() -> void:
	get_tree().auto_accept_quit = false

	DisplayServer.window_set_drop_files_callback(_on_window_drop_file)
	EventBus.add_graph_node.connect(add_node_from_global)
	EventBus.select_new_node.connect(_select_new_node)
	EventBus.test_trigger.connect(test_project)

	var args: PackedStringArray = OS.get_cmdline_args()
	for arg: String in args:
		if arg.ends_with(".mnlp") and FileAccess.file_exists(arg):
			Log.warn("Attempt to open mlnp file on startup.")

	ProjectManager.load_project(MonologueProject.new())


func _select_new_node() -> void:
	graph_node_picker.open_for_node("", -1, null, null, null, true)


#func _input(event: InputEvent) -> void:
#if event.is_action_pressed("Save"):
#ProjectManager.current_project.save()

#if event.is_action_pressed("ui_undo"):
#var focus_owner: Control = get_viewport().gui_get_focus_owner()
#if focus_owner:
#focus_owner.release_focus()
#ProjectManager.current_project.command_manager.undo()
#
#if event.is_action_pressed("ui_redo"):
#ProjectManager.current_project.command_manager.redo()


## Function callback for when th e user wants to add a node from global context.
## Used by header menu and graph node selector (picker).
func add_node_from_global(node_type: String, picker: GraphNodePicker = null) -> void:
	var storyline_id: String = graph_container.graph.storyline_id
	var storyline: StorylineDocument = ProjectManager.current_project.get_storyline(storyline_id)

	if storyline == null:
		Log.error("No active storyline available to add node.")
		return

	var indexer: NodeIndexer = MonologueRegistry.get_instance().get_node(node_type)
	if indexer and indexer.is_singleton:
		Log.warn("A storyline already has its own '%s' node." % node_type)
		return

	var node: InspectableNode = storyline.create_node(node_type)
	if node == null:
		Log.error("Unable to create node of type '%s'." % node_type)
		return

	var graph_edit: MonologueGraphEdit = graph_container.graph
	var target_position: Vector2 = Vector2.ZERO
	if picker and picker.graph_release is Vector2:
		target_position = picker.graph_release
	else:
		target_position = graph_edit.scroll_offset / graph_edit.zoom

	var position_property: Property = node.get_property("editor_position")
	if position_property:
		position_property.set_value(target_position)

	# One transaction, so a node dragged out of a port and its wire are undone together
	# rather than in two steps.
	var transaction: CommandTransaction = storyline.history.begin("Add %s node" % node_type)
	storyline.history.execute(AddNodesCommand.new(storyline.id, [node]))
	_connect_to_source_port(graph_edit, node, picker)
	transaction.commit()

	graph_edit.refresh()


## Wires the new node to the port the picker was dragged out of. Does nothing when the
## picker was opened from a menu, or when nothing on the node accepts that port.
func _connect_to_source_port(
	graph_edit: MonologueGraphEdit, node: InspectableNode, picker: GraphNodePicker
) -> void:
	if picker == null or not picker.has_source_port():
		return

	var from_property: String = graph_edit.get_property_name_at_port(
		picker.from_node, picker.from_port, true
	)
	if from_property.is_empty():
		return

	var to_property: Property = _first_accepting_property(node, picker.source_port_type_id)
	if to_property == null:
		return

	# The port has to exist before a wire can land on it. Through the object, so that
	# undoing the whole thing closes it again.
	node.set_property_settings_value(to_property.name, PropertySettings.KEY_EXPOSED, true)
	graph_edit.get_storyline().history.execute(
		NodeConnectionCommand.new(
			graph_edit, picker.from_node, node.get_id(), from_property, to_property.name
		)
	)


## The first property of [param node] that could take a wire of this type.
func _first_accepting_property(node: InspectableNode, source_type_id: int) -> Property:
	var registry: MonologueRegistry = MonologueRegistry.get_instance()
	for property: Property in node.get_properties():
		if not property.get_settings_value(PropertySettings.KEY_EXPOSABLE, false):
			continue
		var type_id: int = registry.get_field_type_id(property.type)
		if type_id > 0 and registry.is_compatible(source_type_id, type_id):
			return property
	return null


func load_project(path: String) -> void:
	ProjectManager.load_project_from_path(path)


func test_project(_from_node: Variant = null) -> void:
	# TODO: Implement run/test functionality
	pass


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		get_viewport().gui_release_focus()

		if await ProjectManager.close_current_project():
			get_tree().quit()


func _on_window_drop_file(paths: PackedStringArray) -> void:
	Log.info("%s file(s) have been dragged into the editor." % paths.size())
	if paths.size() > 1:
		Log.warn("Can't open multiple files.")
	var path: String = paths[0]

	if not path.ends_with(".%s" % MonologueProject.FILE_FORMAT):
		Log.error("Can't open file at '%s'. (wrong file format)" % path)
		return

	ProjectManager.load_project_from_path(path)
