## Global file dialog for handling save/open file requests via signals.
##
## Listens for global file request signals and presents appropriate file
## dialogs, then calls back with the selected file path(s).
class_name GlobalFileDialog extends FileDialog

## Callback to invoke when a file is selected.
var _callback: Callable


## Initializes the dialog and registers signal listeners.
func _ready():
	GlobalSignal.add_listener("save_file_request", _on_save_file_request)
	GlobalSignal.add_listener("open_file_request", _on_open_file_request)
	GlobalSignal.add_listener("open_files_request", _on_open_files_request)


## Handles save file requests.
##
## [param callable] The callback to invoke with the selected path.
## [br][br]
## [param filter_list] Optional file filters.
## [br][br]
## [param root_subdir] Optional root directory to start in.
func _on_save_file_request(
	callable: Callable, filter_list: PackedStringArray = [], root_subdir: String = ""
) -> void:
	title = "Save"
	ok_button_text = "Save"
	file_mode = FileDialog.FILE_MODE_SAVE_FILE
	_core_request(callable, filter_list, root_subdir)


## Handles open single file requests.
##
## [param callable] The callback to invoke with the selected path.
## [br][br]
## [param filter_list] Optional file filters.
## [br][br]
## [param root_subdir] Optional root directory to start in.
func _on_open_file_request(
	callable: Callable, filter_list: PackedStringArray = [], root_subdir: String = ""
) -> void:
	title = "Open"
	ok_button_text = "Open"
	file_mode = FileDialog.FILE_MODE_OPEN_FILE
	_core_request(callable, filter_list, root_subdir)


## Handles open multiple files requests.
##
## [param callable] The callback to invoke with the selected paths array.
## [br][br]
## [param filter_list] Optional file filters.
## [br][br]
## [param root_subdir] Optional root directory to start in.
func _on_open_files_request(
	callable: Callable, filter_list: PackedStringArray = [], root_subdir: String = ""
) -> void:
	title = "Open"
	ok_button_text = "Open"
	file_mode = FileDialog.FILE_MODE_OPEN_FILES

	if not files_selected.is_connected(_on_files_selected):
		files_selected.connect(_on_files_selected)

	_core_request(callable, filter_list, root_subdir)


## Core request handler that configures and shows the dialog.
##
## [param callable] The callback to invoke with the result.
## [br][br]
## [param filter_list] File filters to apply.
## [br][br]
## [param root_subdir] Starting directory.
func _core_request(callable: Callable, filter_list: PackedStringArray = [],
		root_subdir: String = "") -> void:
	if not root_subdir.ends_with(Path.get_separator()):
		root_subdir += Path.get_separator()
		
	_callback = callable
	filters = filter_list
	current_path = root_subdir

	popup_centered()


## Handles single file selection.
##
## Creates the file if in save mode, then invokes the callback.
## [br][br]
## [param path] The selected file path.
func _on_file_selected(path: String) -> void:
	if file_mode == FILE_MODE_SAVE_FILE:
		FileAccess.open(path, FileAccess.WRITE)
	_callback.call(path as String)


## Handles multiple files selection.
##
## Invokes the callback with an array of selected paths.
## [br][br]
## [param paths] The selected file paths.
func _on_files_selected(paths: PackedStringArray) -> void:
	_callback.call(paths as Array)
