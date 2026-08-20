extends PanelContainer

## How far a section is pushed in from whatever it sits inside.
const INDENT: int = 14

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
	EventBus.storylines_changed.connect(_rebuild_explorer)
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

	_add_document_rows(project.top_level_storylines(), 0, ButtonGroup.new())

	_show_open_storyline()


## One row per document, with whatever sits inside it underneath and pushed in.
func _add_document_rows(
	documents: Array[StorylineDocument], depth: int, group: ButtonGroup
) -> void:
	for document: StorylineDocument in documents:
		var row: MarginContainer = MarginContainer.new()
		row.add_theme_constant_override("margin_top", 0)
		row.add_theme_constant_override("margin_right", 0)
		row.add_theme_constant_override("margin_bottom", 0)
		row.add_theme_constant_override("margin_left", depth * INDENT)

		var button: Button = Button.new()
		button.text = document.name
		button.toggle_mode = true
		button.theme_type_variation = "ToggleButton"
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.button_group = group
		button.pressed.connect(_on_storyline_button_pressed.bind(document))
		button.set_meta("document", document)

		row.add_child(button)
		storylines_container.add_child(row)
		InlineRename.attach(button).committed.connect(_on_storyline_renamed.bind(document))

		_add_document_rows(
			ProjectManager.current_project.get_sections_of(document.id), depth + 1, group
		)


func _document_buttons() -> Array[Button]:
	var found: Array[Button] = []
	if not storylines_container:
		return found

	for row: Node in storylines_container.get_children():
		for child: Node in row.get_children():
			if child is Button:
				found.append(child)
	return found


func _show_open_storyline() -> void:
	var project: MonologueProject = ProjectManager.current_project
	var top_level_storylines: Array[StorylineDocument] = (
		project.top_level_storylines() if project else []
	)
	if top_level_storylines.is_empty():
		return

	if not is_instance_valid(_open_storyline) or not project.storylines.has(_open_storyline):
		var was_showing_one: bool = _open_storyline != null
		_open_storyline = top_level_storylines[0]
		if was_showing_one:
			EventBus.request_storyline_inspection.emit.call_deferred(_open_storyline)

	for button: Button in _document_buttons():
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


## A refused name leaves the button showing the old one, and the reason in the log.
func _on_storyline_renamed(new_name: String, storyline: StorylineDocument) -> void:
	ProjectManager.current_project.rename_storyline(storyline, new_name)


func _on_add_storyline_button_pressed() -> void:
	ProjectManager.current_project.add_new_storyline()


func _on_request_objects_inspection(objects: Array[InspectableObject]) -> void:
	if not collections_container or objects.size() != 1:
		return

	for button: Button in collections_container.get_children():
		var collection: CollectionDocument = button.get_meta("document")
		button.set_pressed_no_signal(collection == objects[0])


func _on_request_storyline_inspection(storyline: StorylineDocument) -> void:
	_open_storyline = storyline
	for button: Button in _document_buttons():
		button.set_pressed_no_signal(button.get_meta("document") == storyline)
