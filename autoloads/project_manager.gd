extends Node

signal project_loaded
signal storyline_created
signal storyline_closed
signal _file_prompt_done

const SAVE_PROMPT: String = "%s has been modified."

var current_project: MonologueProject
var _cancel_close: bool = false


func load_project(project: MonologueProject) -> void:
	current_project = project
	project_loaded.emit.call_deferred()

	
func _on_file_prompt_response(storyline: StorylineDocument, response: int) -> void:
	if response == Prompt.DENIED:
		_file_prompt_done.emit()
		return
	if response == Prompt.CONFIRMED:
		if storyline.has_method("save"):
			storyline.call("save")
		_file_prompt_done.emit()
		
	_cancel_close = true
	_file_prompt_done.emit()
	return
