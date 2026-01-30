class_name MonologueEditor extends Control

const STORYLINE_EXTENSIONS: Array = ["*.mnlg,*.json;Storyline Document"]

@export var welcome_window: WelcomeWindow
@export var graph_container: GraphContainer
@export var file_dialog: GlobalFileDialog

@onready var graph_node_picker: GraphNodePicker = %GraphNodePicker
@onready var inspector_panel_node: InspectorPanel = %Inspector
@onready var run_window := preload("res://scenes/run/run_window.tscn")
@onready var dimmer := $"../../../Dimmer"
@onready var document_tab_manager: DocumentTabManager = %_Tabs

@onready var characters_section := %Characters
@onready var variables_section := %Variables
@onready var items_section := %Items
@onready var locations_section := %Locations


func _ready():
	get_tree().auto_accept_quit = false  # quit handled by _close_tab()
	#welcome_window.show()

	EventBus.add_graph_node.connect(add_node_from_global)
	EventBus.select_new_node.connect(_select_new_node)
	EventBus.load_project.connect(load_project)
	EventBus.test_trigger.connect(test_project)
	EventBus.save_current_project.connect(save)

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

	if event.is_action_pressed("ui_redo"):
		StorylineManager.get_active_storyline().history.redo()


## Function callback for when the user wants to add a node from global context.
## Used by header menu and graph node selector (picker).
func add_node_from_global(node_type: String, picker: GraphNodePicker = null):
	var storyline := StorylineManager.get_active_storyline()
	if storyline == null:
		push_warning("No active storyline available to add node.")
		return

	var node := storyline.create_node(node_type)
	if node == null:
		push_warning("Unable to create node of type '%s'." % node_type)
		return

	var graph_edit: MonologueGraphEdit = graph_container.graph
	var target_position := Vector2.ZERO
	if picker and picker.graph_release is Vector2:
		target_position = picker.graph_release
	else:
		target_position = graph_edit.scroll_offset / graph_edit.zoom

	var position_property := node.get_property("position")
	if position_property:
		position_property.set_value(target_position)

	var command: AddNodesCommand = AddNodesCommand.new(storyline.id, [node])
	storyline.history.execute(command)


func get_root_dict(node_list: Array) -> Dictionary:
	for node in node_list:
		if node.get("$type") == "NodeRoot":
			return node
	return {}


func load_project(path: String, new_graph: bool = false) -> void:
	var file = FileAccess.open(path, FileAccess.READ)
	if not file or graph_container.is_file_opened(path):
		return

	var data = {}
	var text = file.get_as_text()
	if text:
		data = JSON.parse_string(text)
	if not data:
		save()

	var converter := NodeConverter.new()
	var storyline = StorylineManager.get_active_storyline()

	load_editor_sections()


func load_editor_sections() -> void:
	var storyline := StorylineManager.get_active_storyline()
	if storyline:
		characters_section.load_items(storyline.get_property("characters"), storyline)
		variables_section.load_items(storyline.get_property("variables"), storyline)
		items_section.load_items(storyline.get_property("items"), storyline)
		locations_section.load_items(storyline.get_property("locations"), storyline)


func save():
	var storyline = StorylineManager.get_active_storyline()
	if storyline.file_path.is_empty():
		file_dialog.save_file(save_file_logic, STORYLINE_EXTENSIONS)
		return
	save_file_logic(storyline.file_path)


func save_file_logic(path: String) -> void:
	var storyline = StorylineManager.get_active_storyline()
	var dict: Dictionary = storyline._to_dict()
	dict["editor_version"] = ProjectSettings.get_setting("application/config/version")
	var storyline_data: String = JSON.stringify(dict, "\t", false, true)

	if path.get_extension().is_empty():
		path = path.trim_suffix(".")
		path = "%s.mnlg" % path

	var access: FileAccess = FileAccess.open(path, FileAccess.WRITE_READ)
	access.store_string(storyline_data)

	storyline.file_path = path
	storyline.name = path.get_file()
	storyline.is_dirty = false
	storyline.content_changed.emit()


func test_project(_from_node: Variant = null):
	return
	#if graph_switcher.current.file_path:
	#await save()
	#var window: RunWindow = run_window.instantiate()
	#window.file_path = graph_switcher.current.file_path
	#window.from_node = from_node
	#window.tree_exited.connect(dimmer.hide)
	#get_tree().root.add_child(window)
	#dimmer.show()


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


func _on__tabs_add_document() -> void:
	welcome_window.show()
