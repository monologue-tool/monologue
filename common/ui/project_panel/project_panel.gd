extends PanelContainer

@onready var project_explorer: VBoxContainer = %ProjectExplorer

@onready var delete_icon: DPITexture = preload("res://ui/assets/icons/trash.svg")
@onready var add_icon: DPITexture = preload("res://ui/assets/icons/plus.svg")

var collections_fc: FoldableContainer
var collections_container: VBoxContainer
var storylines_fc: FoldableContainer
var storylines_container: VBoxContainer

## The storyline the graph is showing, so a rebuild puts the highlight back where it was.
var _open_storyline: StorylineDocument


func _ready() -> void:
	ProjectManager.project_loaded.connect(_rebuild_explorer)
	EventBus.request_objects_inspection.connect(_on_request_objects_inspection)
	EventBus.request_storyline_inspection.connect(_on_request_storyline_inspection)
	EventBus.show_project_explorer.connect(_on_event_show_project_panel)
	EventBus.storyline_deleted.connect(_rebuild_explorer)

	visible = ConfigManager.get_config("show_project_explorer")

	_rebuild_explorer()


func _on_event_show_project_panel(_visible: bool) -> void:
	visible = ConfigManager.get_config("show_project_explorer")


func _rebuild_explorer() -> void:
	for child: Control in project_explorer.get_children():
		child.queue_free()

	collections_fc = null
	collections_container = null
	storylines_fc = null
	storylines_container = null

	var project: MonologueProject = ProjectManager.current_project
	if not project:
		return

	var display_name: String = project.name
	if project.project_path.is_empty():
		display_name = "<%s>" % display_name
	if project.is_dirty:
		display_name = "%s*" % display_name

	collections_fc = _create_foldable_container("Collections")
	collections_container = VBoxContainer.new()
	collections_fc.add_child(collections_container)

	storylines_fc = _create_foldable_container("Storylines")
	storylines_container = VBoxContainer.new()
	storylines_fc.add_child(storylines_container)

	var add_button: Button = Button.new()
	add_button.theme_type_variation = "IconButton"
	add_button.icon = add_icon
	add_button.pressed.connect(_on_add_storyline_button_pressed)
	storylines_fc.add_title_bar_control(add_button)

	var collection_button_group: ButtonGroup = ButtonGroup.new()
	for collection: CollectionDocument in project.collections:
		var collection_btn: Button = Button.new()
		collection_btn.text = collection.name
		collection_btn.toggle_mode = true
		collection_btn.theme_type_variation = "ToggleButton"
		collection_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		collection_btn.button_group = collection_button_group
		collection_btn.pressed.connect(_on_collection_button_pressed.bind(collection))
		collection_btn.set_meta("document", collection)
		collections_container.add_child(collection_btn)

	var storyline_button_group: ButtonGroup = ButtonGroup.new()
	for storyline: StorylineDocument in project.storylines:
		var storyline_btn: Button = Button.new()
		storyline_btn.text = storyline.name
		storyline_btn.toggle_mode = true
		storyline_btn.theme_type_variation = "ToggleButton"
		storyline_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		storyline_btn.button_group = storyline_button_group
		storyline_btn.pressed.connect(_on_storyline_button_pressed.bind(storyline))
		storyline_btn.set_meta("document", storyline)
		storylines_container.add_child(storyline_btn)
		InlineRename.attach(storyline_btn).committed.connect(
			_on_storyline_renamed.bind(storyline)
		)

	_show_open_storyline()


## A project always has a storyline open, so the explorer always has one highlighted: the
## one that was, or the first, which is the one the graph opens a project on.
func _show_open_storyline() -> void:
	var project: MonologueProject = ProjectManager.current_project
	if not project or project.storylines.is_empty():
		return

	if not is_instance_valid(_open_storyline) or not project.storylines.has(_open_storyline):
		var was_showing_one: bool = _open_storyline != null
		_open_storyline = project.storylines[0]
		# The storyline that was open has just gone, and the graph is still on it. Deferred
		# because a rebuild also happens while a project is still being opened, before
		# the graph is in any state to be handed one.
		if was_showing_one:
			EventBus.request_storyline_inspection.emit.call_deferred(_open_storyline)

	for button: Button in storylines_container.get_children():
		button.set_pressed_no_signal(button.get_meta("document") == _open_storyline)


func _create_foldable_container(title: String) -> FoldableContainer:
	var container: FoldableContainer = FoldableContainer.new()
	container.title = title
	container.title_alignment = HORIZONTAL_ALIGNMENT_LEFT
	project_explorer.add_child(container)
	return container


func _on_collection_button_pressed(collection: CollectionDocument) -> void:
	var selection: Array[InspectableObject] = [collection]
	EventBus.request_objects_inspection.emit(selection)


func _on_storyline_button_pressed(storyline: StorylineDocument) -> void:
	EventBus.request_storyline_inspection.emit(storyline)


## A refused name leaves the button showing the old one, which is already what the rename
## put back: nothing to undo, and the reason is in the log.
func _on_storyline_renamed(new_name: String, storyline: StorylineDocument) -> void:
	if ProjectManager.current_project.rename_storyline(storyline, new_name):
		_rebuild_explorer()


func _on_add_storyline_button_pressed() -> void:
	ProjectManager.current_project.add_new_storyline()
	_rebuild_explorer()


func _on_request_objects_inspection(objects: Array[InspectableObject]) -> void:
	if not collections_container or objects.size() != 1:
		return

	for button: Button in collections_container.get_children():
		var collection: CollectionDocument = button.get_meta("document")
		button.set_pressed_no_signal(collection == objects[0])


func _on_request_storyline_inspection(storyline: StorylineDocument) -> void:
	_open_storyline = storyline
	if not storylines_container:
		return

	for button: Button in storylines_container.get_children():
		var btn_storyline: StorylineDocument = button.get_meta("document")
		button.set_pressed_no_signal(btn_storyline == storyline)
