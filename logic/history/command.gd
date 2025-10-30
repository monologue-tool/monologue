## Abstract base class for undo/redo commands.
##
## Defines the interface that all command classes must implement for the
## command pattern-based undo/redo system. Each command encapsulates a
## reversible operation.
@abstract
class_name Command extends RefCounted

## Executes the command's action.
##
## Implements the forward action that this command represents.
@abstract func execute()

## Reverses the command's action.
##
## Implements the reverse/undo action to restore the previous state.
@abstract func undo()

## Returns a human-readable description of this command.
##
## Used for displaying command history and debugging.
@abstract func get_description() -> String
