## Groups several commands into a single undo step.
##
## Obtain one from [method CommandManager.begin]. Anything run through
## [method CommandManager.execute] while it is open joins it, and nothing takes effect until
## [method commit].
class_name CommandTransaction extends RefCounted

var description: String

var _manager: CommandManager
var _closed: bool = false


func _init(manager: CommandManager, transaction_description: String) -> void:
	_manager = manager
	description = transaction_description


## Adds a command explicitly. Rarely needed: anything going through
## [method CommandManager.execute] joins the open transaction on its own.
func add(command: Command) -> CommandTransaction:
	if _closed:
		push_error("Transaction '%s' is already closed." % description)
		return self
	_manager.execute(command)
	return self


## Runs everything collected, as one undoable step. Doing this twice is a no-op.
func commit() -> void:
	if _closed:
		return
	_closed = true
	_manager._close_transaction()


func is_open() -> bool:
	return not _closed
