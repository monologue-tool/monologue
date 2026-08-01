## Groups several commands into a single undo step.
##
## Obtain one from [method CommandManager.begin]. Commands run through
## [method CommandManager.execute] while a transaction is open join it automatically,
## so existing code needs no change to take part:
## [codeblock]
## var transaction := history.begin("Edit 4 nodes")
## for node in nodes:
##     node.set_property_value("color", "#ff0000")
## transaction.commit()
## [/codeblock]
##
## Note that the commands only take effect on [method commit] -- that is what makes
## them one step rather than several.
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
