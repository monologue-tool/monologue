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

	var position_property: Property = node.get_property("position")
	if position_property:
		position_property.set_value(target_position)

	var command: AddNodesCommand = AddNodesCommand.new(storyline.id, [node])
	storyline.history.execute(command)
	graph_edit.refresh()


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
