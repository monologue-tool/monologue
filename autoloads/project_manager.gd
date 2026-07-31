extends Node

signal project_loaded
signal file_prompt_done

const SAVE_PROMPT: String = "%s has been modified."

var current_project: MonologueProject
var _cancel_close: bool = false


func _ready() -> void:
	EventBus.load_project.connect(load_project_from_path)


func close_current_project() -> bool:
	if not current_project:
		_update_window_title()
		return true

	if current_project and current_project.is_dirty:
		EventBus.ask_dialog.emit(
			_on_close_project_dialog_response,
			"Save change before closing?",
			SAVE_PROMPT % current_project.project_path,
			"Save",
			"Don't Save",
			"Cancel"
		)
		await file_prompt_done

		if _cancel_close:
			return false

	_update_window_title()
	return true


func load_project(project: MonologueProject) -> void:
	if not await close_current_project():
		return

	Log.info("Project loaded!")
	current_project = project
	project_loaded.emit.call_deferred()
	EventBus.hide_welcome.emit()

	if not project.project_path.is_empty():
		add_path_to_history(project.project_path)

	_update_window_title()


func save_project(project: MonologueProject) -> void:
	project.save()


func load_project_from_path(path: String) -> void:
	var new_project: MonologueProject
	if FileAccess.file_exists(path) and path.ends_with(".%s" % MonologueProject.FILE_FORMAT):
		new_project = await MonologueProject.from_file_path(path)
	elif path.ends_with(".%s" % ManifestDocument.FILE_FORMAT):
		new_project = await MonologueProject.from_dir_path(path.get_base_dir())

	if not new_project:
		Log.error("Can't load project from an invalid path.")
		return

	load_project(new_project)


func add_path_to_history(path: String) -> void:
	var paths: Array = get_history() as Array
	paths.erase(path.simplify_path())
	paths.push_front(path)

	_ensure_history_file()
	var file: FileAccess = FileAccess.open(Constants.HISTORY_PATH, FileAccess.WRITE)
	var content: String = JSON.stringify(paths)
	file.store_string(content)
	file.close()


func get_history() -> PackedStringArray:
	if not FileAccess.file_exists(Constants.HISTORY_PATH):
		FileAccess.open(Constants.HISTORY_PATH, FileAccess.WRITE)

	var file: FileAccess = FileAccess.open(Constants.HISTORY_PATH, FileAccess.READ)
	var content: String = file.get_as_text()
	file.close()

	var paths: Array = []
	for path: String in _parse_history(content):
		if path not in paths:
			paths.append(path)

	for path: String in paths:
		if not FileAccess.file_exists(path):
			paths.erase(path)

	return paths as PackedStringArray


func _parse_history(text: String) -> Array:
	var data: Variant = JSON.parse_string(text)
	if data is Array:
		return data.filter(func(p: Variant) -> bool: return FileAccess.file_exists(p))
	return []


func _ensure_history_file() -> void:
	if not FileAccess.file_exists(Constants.HISTORY_PATH):
		FileAccess.open(Constants.HISTORY_PATH, FileAccess.WRITE)


func _on_close_project_dialog_response(response: int) -> void:
	_cancel_close = false
	if response == Prompt.DENIED:
		file_prompt_done.emit()
		return
	if response == Prompt.CONFIRMED:
		await current_project.save()
		file_prompt_done.emit()
		return

	_cancel_close = true
	file_prompt_done.emit()
	return


func _update_window_title() -> void:
	var base_title: String = (
		"Monologue %s" % ProjectSettings.get_setting("application/config/version")
	)

	if not current_project:
		DisplayServer.window_set_title(base_title)
		return

	var title: String = "<unsaved>"
	if current_project.project_path:
		title = current_project.project_path.get_file().get_basename()

	if current_project.is_dirty:
		title = "* " + title

	DisplayServer.window_set_title("%s - %s" % [title, base_title])
