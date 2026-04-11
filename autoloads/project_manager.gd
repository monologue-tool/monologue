extends Node

signal project_loaded
signal _file_prompt_done

const SAVE_PROMPT: String = "%s has been modified."

var current_project: MonologueProject
var _cancel_close: bool = false


func _ready() -> void:
	EventBus.load_project.connect(load_project_from_path)


func close_current_project() -> bool:
	if not current_project:
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
		await _file_prompt_done
	
		if _cancel_close:
			return false
	
	return true


func load_project(project: MonologueProject) -> void:
	if not await close_current_project():
		return
	
	Log.info("Project loaded!")
	current_project = project
	project_loaded.emit.call_deferred()


func save_project(project: MonologueProject) -> void:
	project.save()


func load_project_from_path(path: String) -> void:
	if not FileAccess.file_exists(path):
		Log.error("Can't load project from an invalid path.")
		return
	
	var new_project: MonologueProject = await MonologueProject.from_path(path)
	load_project(new_project)



func _on_close_project_dialog_response(response: int) -> void:
	_cancel_close = false
	if response == Prompt.DENIED:
		_file_prompt_done.emit()
		return
	if response == Prompt.CONFIRMED:
		await current_project.save()
		_file_prompt_done.emit()
		return
		
	_cancel_close = true
	_file_prompt_done.emit()
	return
