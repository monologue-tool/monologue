class_name CommandManager extends RefCounted

var undo_redo: UndoRedo

signal command_executed
signal undone
signal redone
signal history_changed


func _init(max_history: int = 100) -> void:
	undo_redo = UndoRedo.new()
	undo_redo.max_steps = max_history
	undo_redo.version_changed.connect(_on_version_changed)


func execute(command: Command, merge_mode: UndoRedo.MergeMode = UndoRedo.MERGE_ENDS) -> void:
	var description = command.get_description()
	undo_redo.create_action(description, merge_mode)
	undo_redo.add_do_method(command.execute.bind())
	undo_redo.add_undo_method(command.undo.bind())
	undo_redo.add_do_reference(command)
	undo_redo.add_undo_reference(command)

	undo_redo.commit_action()

	command_executed.emit()
	history_changed.emit()


func undo() -> bool:
	if not can_undo():
		return false

	undo_redo.undo()
	undone.emit()
	history_changed.emit()
	return true


func redo() -> bool:
	if not can_redo():
		return false

	undo_redo.redo()
	redone.emit()
	history_changed.emit()
	return true


func can_undo() -> bool:
	return undo_redo.has_undo()


func can_redo() -> bool:
	return undo_redo.has_redo()


func get_undo_description() -> String:
	if not can_undo():
		return ""
	return undo_redo.get_action_name(undo_redo.get_version() - 1)


func get_redo_description() -> String:
	if not can_redo():
		return ""
	return undo_redo.get_action_name(undo_redo.get_version())


func clear():
	undo_redo.clear_history()
	history_changed.emit()


func get_version() -> int:
	return undo_redo.get_version()


func get_history_count() -> int:
	return undo_redo.get_history_count()


func _on_version_changed():
	history_changed.emit()


func begin_group(description: String = "Group"):
	undo_redo.create_action(description, UndoRedo.MERGE_DISABLE)


func add_to_group(command: Command):
	undo_redo.add_do_method(command.execute.bind())
	undo_redo.add_undo_method(command.undo.bind())
	undo_redo.add_do_reference(command)
	undo_redo.add_undo_reference(command)


func end_group():
	undo_redo.commit_action()
	command_executed.emit()
	history_changed.emit()
