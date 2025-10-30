## A reference object that stores callbacks for undo and redo as a pair.
## This streamlines some operations and provide more control over node data.
class_name MonologueHistory
extends RefCounted

## Function to call on undo. Arguments should be bound beforehand.
var _undo_callback: Callable
## Function to call on redo. Arguments should be bound beforehand.
var _redo_callback: Callable


## Must have undo and redo [Callable] that has bound arguments.
## Use [method Callable.bind()] to create them.
func _init(undo_function: Callable, redo_function: Callable):
	_undo_callback = undo_function
	_redo_callback = redo_function


## General interface method for undo-ing.
func undo() -> Variant:
	return _undo_callback.call()


## General interface method for redo-ing.
func redo() -> Variant:
	return _redo_callback.call()
