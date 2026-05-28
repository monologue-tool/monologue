@warning_ignore_start("int_as_enum_without_match", "int_as_enum_without_cast")
extends EditorMenuButton


func _build_menu() -> void:
	var command_manager: CommandManager = ProjectManager.current_project.command_manager
	add_row("Undo", _on_undo, command_manager.can_undo(), ["mnl_undo"])
	add_row("Redo", _on_redo, command_manager.can_redo(), ["mnl_redo"])


func _on_undo() -> void:
	var focus_owner: Control = get_viewport().gui_get_focus_owner()
	if focus_owner:
		focus_owner.release_focus()
	
	var command_manager: CommandManager = ProjectManager.current_project.command_manager
	command_manager.undo()


func _on_redo() -> void:
	var command_manager: CommandManager = ProjectManager.current_project.command_manager
	command_manager.redo()
	
