## Manages command execution and undo/redo history.
##
## Wraps Godot's UndoRedo system with a command-pattern interface.
## Provides signals for tracking command execution and history changes.
class_name CommandManager extends RefCounted

## The underlying Godot UndoRedo instance managing the history stack.
var undo_redo: UndoRedo

## Emitted when a command is executed.
signal command_executed

## Emitted when an undo operation is performed.
signal undone

## Emitted when a redo operation is performed.
signal redone

## Emitted when the command history changes in any way.
signal history_changed


## Initializes the command manager with a maximum history size.
##
## [param max_history] Maximum number of actions to store in history. Default is 100.
func _init(max_history: int = 100) -> void:
	undo_redo = UndoRedo.new()
	undo_redo.max_steps = max_history
	undo_redo.version_changed.connect(_on_version_changed)


## Executes a command and adds it to the undo history.
##
## Wraps the command's execute and undo methods in an UndoRedo action.
## Emits command_executed and history_changed signals.
## [br][br]
## [param command] The command to execute.
## [br][br]
## [param merge_mode] How to merge with previous actions. Default is MERGE_ENDS.
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


## Undoes the last executed command.
##
## Returns true if undo was successful, false if no actions to undo.
func undo() -> bool:
	if not can_undo():
		return false

	undo_redo.undo()
	undone.emit()
	history_changed.emit()
	return true


## Redoes the previously undone command.
##
## Returns true if redo was successful, false if no actions to redo.
func redo() -> bool:
	if not can_redo():
		return false

	undo_redo.redo()
	redone.emit()
	history_changed.emit()
	return true


## Returns whether undo is possible.
func can_undo() -> bool:
	return undo_redo.has_undo()


## Returns whether redo is possible.
func can_redo() -> bool:
	return undo_redo.has_redo()


## Returns a description of the action that would be undone.
##
## Returns an empty string if no actions are available to undo.
func get_undo_description() -> String:
	if not can_undo():
		return ""
	return undo_redo.get_action_name(undo_redo.get_version() - 1)


## Returns a description of the action that would be redone.
##
## Returns an empty string if no actions are available to redo.
func get_redo_description() -> String:
	if not can_redo():
		return ""
	return undo_redo.get_action_name(undo_redo.get_version())


## Clears all undo/redo history.
##
## Removes all actions from the history stack and emits history_changed signal.
func clear():
	undo_redo.clear_history()
	history_changed.emit()


## Returns the current version number of the undo/redo history.
func get_version() -> int:
	return undo_redo.get_version()


## Returns the total number of actions in the history.
func get_history_count() -> int:
	return undo_redo.get_history_count()


## Internal callback when the undo/redo version changes.
func _on_version_changed():
	history_changed.emit()


## Begins a group of commands to be treated as a single undo/redo action.
##
## [param description] The description for the grouped action. Default is "Group".
func begin_group(description: String = "Group"):
	undo_redo.create_action(description, UndoRedo.MERGE_DISABLE)


## Adds a command to the current group.
##
## Must be called between begin_group() and end_group().
## [br][br]
## [param command] The command to add to the group.
func add_to_group(command: Command):
	undo_redo.add_do_method(command.execute.bind())
	undo_redo.add_undo_method(command.undo.bind())
	undo_redo.add_do_reference(command)
	undo_redo.add_undo_reference(command)


## Ends the current command group and commits it to history.
##
## Emits command_executed and history_changed signals.
func end_group():
	undo_redo.commit_action()
	command_executed.emit()
	history_changed.emit()
