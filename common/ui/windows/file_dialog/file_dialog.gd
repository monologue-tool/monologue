class_name GlobalFileDialog extends FileDialog

var _callback: Callable


func _ready() -> void:
	EventBus.save_file_request.connect(_on_save_file_request)
	EventBus.open_file_request.connect(_on_open_file_request)
	EventBus.open_files_request.connect(_on_open_files_request)


func save_file(
	callback: Callable, filter_list: PackedStringArray = [], root_subdir: String = ""
) -> void:
	_on_save_file_request(callback, filter_list, root_subdir)


func _on_save_file_request(
	callable: Callable, filter_list: PackedStringArray = [], root_subdir: String = ""
) -> void:
	title = "Save"
	ok_button_text = "Save"
	file_mode = FileDialog.FILE_MODE_SAVE_FILE
	_core_request(callable, filter_list, root_subdir)


func _on_open_file_request(
	callable: Callable, filter_list: PackedStringArray = [], root_subdir: String = ""
) -> void:
	title = "Open"
	ok_button_text = "Open"
	file_mode = FileDialog.FILE_MODE_OPEN_FILE
	_core_request(callable, filter_list, root_subdir)


func _on_open_files_request(
	callable: Callable, filter_list: PackedStringArray = [], root_subdir: String = ""
) -> void:
	title = "Open"
	ok_button_text = "Open"
	file_mode = FileDialog.FILE_MODE_OPEN_FILES

	if not files_selected.is_connected(_on_files_selected):
		files_selected.connect(_on_files_selected)

	_core_request(callable, filter_list, root_subdir)


func _core_request(
	callable: Callable, filter_list: PackedStringArray = [], root_subdir: String = ""
) -> void:
	if not root_subdir.ends_with(PathUtil.get_separator()):
		root_subdir += PathUtil.get_separator()

	_callback = callable
	filters = filter_list
	current_path = root_subdir

	popup_centered()


func _on_file_selected(path: String) -> void:
	if file_mode == FILE_MODE_SAVE_FILE:
		FileAccess.open(path, FileAccess.WRITE)
	_callback.call(path as String)


func _on_files_selected(paths: PackedStringArray) -> void:
	_callback.call(paths as Array)
