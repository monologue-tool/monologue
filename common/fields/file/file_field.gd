## Points at a file on disk, stored relative to the project so a project stays portable.
class_name FileField extends Field

const EMPTY_TEXT: String = "No file selected."

var _value: String = ""
var _filters: PackedStringArray = []

@onready var browse_button: Button = %BrowseButton
@onready var clear_button: Button = %ClearButton


func _ready() -> void:
	super._ready()
	browse_button.pressed.connect(_on_browse_pressed)
	clear_button.pressed.connect(_on_clear_pressed)
	_refresh()


func _on_initialize() -> void:
	var raw_filters: Variant = settings.get(PropertySettings.KEY_FILE_FILTERS, [])
	if raw_filters is Array:
		_filters = PackedStringArray(raw_filters as Array)
	else:
		_filters = PackedStringArray()


func set_value(value: Variant) -> void:
	if not is_node_ready():
		await ready
	_value = str(value) if value != null else ""
	_refresh()


func get_value() -> Variant:
	return _value


func set_editable(is_editable: bool) -> void:
	if not is_node_ready():
		await ready
	browse_button.disabled = not is_editable
	_refresh()


func _refresh() -> void:
	browse_button.text = _value.get_file() if _value.get_file() else EMPTY_TEXT
	browse_button.tooltip_text = "File path: %s" % _value
	clear_button.disabled = _value.is_empty() or browse_button.disabled
	clear_button.visible = not _value.is_empty()


func _commit(new_value: String) -> void:
	if new_value == _value:
		return
	_value = new_value
	_refresh()
	emit_value_committed(_value)


func _on_browse_pressed() -> void:
	var root_dir: String = ""
	var project: MonologueProject = ProjectManager.current_project
	if project and not project.project_path.is_empty():
		root_dir = project.project_path.get_base_dir()
	EventBus.open_file_request.emit(_on_file_selected, _filters, root_dir)


func _on_clear_pressed() -> void:
	_commit("")


## Stored relative to the project file, so moving the project with its assets keeps every
## reference working. Falls back to the absolute path while the project is unsaved and
## there is nothing to be relative to.
func _on_file_selected(absolute_path: String) -> void:
	var project: MonologueProject = ProjectManager.current_project
	if project and not project.project_path.is_empty():
		_commit(PathUtil.absolute_to_relative(absolute_path, project.project_path))
		return
	_commit(absolute_path)


func _can_drop_data(_position: Vector2, data: Variant) -> bool:
	return not browse_button.disabled and not _dropped_file(data).is_empty()


func _drop_data(_position: Vector2, data: Variant) -> void:
	_on_file_selected(_dropped_file(data))


func _dropped_file(data: Variant) -> String:
	if data is not Dictionary or (data as Dictionary).get("type") != "files":
		return ""

	var files: Variant = (data as Dictionary).get("files")
	if files is not Array or (files as Array).size() != 1:
		return ""

	var path: String = str((files as Array)[0])
	if _filters.is_empty():
		return path

	for filter: String in _filters:
		if path.get_file().matchn(filter):
			return path
	return ""
