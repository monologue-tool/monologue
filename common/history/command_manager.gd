class_name CommandManager extends RefCounted

var undo_redo: UndoRedo

signal command_executed
signal undone
signal redone
signal history_changed

## Godot's UndoRedo cannot nest create_action(), so nested begin() calls share the
## outermost action and only the last commit() closes it.
var _transaction_depth: int = 0


func _init(max_history: int = 200) -> void:
	undo_redo = UndoRedo.new()
	undo_redo.max_steps = max_history
	undo_redo.version_changed.connect(_on_version_changed)


## Opens a transaction: every command executed until it is committed becomes one
## undo step. See [CommandTransaction].
func begin(description: String) -> CommandTransaction:
	if _transaction_depth == 0:
		undo_redo.create_action(description)
	_transaction_depth += 1
	return CommandTransaction.new(self, description)


func is_in_transaction() -> bool:
	return _transaction_depth > 0


func execute(command: Command, merge_mode: UndoRedo.MergeMode = UndoRedo.MERGE_DISABLE) -> void:
	if _transaction_depth > 0:
		# Joins the open transaction instead of becoming its own undo step. The
		# command runs when the transaction commits.
		_record(command)
		return

	undo_redo.create_action(command.get_description(), merge_mode)
	_record(command)
	undo_redo.commit_action()

	command_executed.emit()
	history_changed.emit()


func _record(command: Command) -> void:
	undo_redo.add_do_method(command.execute.bind())
	undo_redo.add_undo_method(command.undo.bind())
	undo_redo.add_do_reference(command)
	undo_redo.add_undo_reference(command)


## Called by [CommandTransaction.commit]. Only the outermost one commits.
func _close_transaction() -> void:
	_transaction_depth = maxi(0, _transaction_depth - 1)
	if _transaction_depth > 0:
		return

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


func clear() -> void:
	undo_redo.clear_history()
	history_changed.emit()


func get_version() -> int:
	return undo_redo.get_version()


func get_history_count() -> int:
	return undo_redo.get_history_count()


func _on_version_changed() -> void:
	history_changed.emit()


## Superseded by begin() / CommandTransaction, which is reentrant and cannot be left
## half-open. Kept only so nothing outside breaks; prefer begin().
func begin_group(description: String = "Group") -> void:
	begin(description)


func add_to_group(command: Command) -> void:
	execute(command)


func end_group() -> void:
	_close_transaction()
