extends EditorMenuButton

@onready var graph: MonologueGraphEdit = %GraphEdit


func _build_menu() -> void:
	var is_last_storyline: bool = ProjectManager.current_project.storylines.size() <= 1
	add_row("Delete Storyline", _on_delete_storyline, not is_last_storyline)


func _get_storyline() -> StorylineDocument:
	var storyline_id: String = graph.storyline_id
	return ProjectManager.current_project.get_storyline(storyline_id)


func _on_delete_storyline() -> void:
	var storyline: StorylineDocument = _get_storyline()
	EventBus.ask_dialog.emit(
		_on_delete_storyline_dialog_callback,
		"Are you sure?",
		"You are about to delete the storyline '%s'." % storyline.name
	)


func _on_delete_storyline_dialog_callback(response: int) -> void:
	if not response == Prompt.CONFIRMED:
		return

	var storyline: StorylineDocument = _get_storyline()
	ProjectManager.current_project.delete_storyline(storyline)
	EventBus.request_storyline_inspection.emit(ProjectManager.current_project.storylines[0])
