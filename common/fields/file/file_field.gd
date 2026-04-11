class_name FileField extends Field

var _filters: PackedStringArray = []

@onready var path_line_edit: LineEdit = %PathLineEdit
@onready var browse_button: Button = %BrowseButton


func _ready() -> void:
	browse_button.pressed.connect(_on_browse_pressed)


func _on_initialize() -> void:
	var raw_filters: Variant = settings.get(PropertySettings.KEY_FILE_FILTERS, [])
	if raw_filters is Array:
		_filters = PackedStringArray(raw_filters as Array)
	else:
		_filters = PackedStringArray()


func set_value(value: Variant) -> void:
	if not is_node_ready():
		await ready
	path_line_edit.text = str(value) if value != null else ""


func get_value() -> Variant:
	return path_line_edit.text


func set_editable(is_editable: bool) -> void:
	browse_button.disabled = not is_editable


func _on_browse_pressed() -> void:
	var root_dir: String = ""
	var project: MonologueProject = ProjectManager.current_project
	if project and not project.file_path.is_empty():
		root_dir = project.file_path.get_base_dir()
	EventBus.open_file_request.emit(_on_file_selected, _filters, root_dir)


func _on_file_selected(absolute_path: String) -> void:
	var relative_path: String = absolute_path
	var project: MonologueProject = ProjectManager.current_project
	if project and not project.file_path.is_empty():
		relative_path = PathUtil.absolute_to_relative(absolute_path, project.file_path)
	path_line_edit.text = relative_path
	emit_value_committed(get_value())
