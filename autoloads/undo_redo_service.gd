## Undo/Redo service singleton.
##
## Manages multiple undo/redo contexts for different parts of the application.
## Each context maintains its own independent history stack with a maximum
## number of steps.
extends Node

## Maximum number of undo/redo steps to retain in each context.
const MAX_STEPS: int = 100

## Dictionary of all undo/redo contexts, keyed by context ID.
var contexts: Dictionary = {}

## ID of the currently active context.
var active_context_id: String = ""


## Creates or retrieves an undo/redo context for the given ID.
##
## If a context with the specified ID already exists, returns it.
## Otherwise, creates a new HistoryHandler with MAX_STEPS limit.
## [br][br]
## [param context_id] The unique identifier for this context.
## [br][br]
## Returns the HistoryHandler for this context.
func create_context(context_id: String) -> HistoryHandler:
	if contexts.has(context_id):
		return contexts[context_id]

	var undo_redo: HistoryHandler = HistoryHandler.new()
	undo_redo.max_steps = MAX_STEPS
	contexts[context_id] = undo_redo
	return undo_redo


## Retrieves an existing undo/redo context by ID.
##
## [param context_id] The unique identifier of the context.
## [br][br]
## Returns the HistoryHandler if found, null otherwise.
func get_context(context_id: String) -> HistoryHandler:
	return contexts.get(context_id, null)


## Destroys an undo/redo context and clears its history.
##
## Removes the context from the contexts dictionary after clearing its history.
## Does nothing if the context doesn't exist.
## [br][br]
## [param context_id] The unique identifier of the context to destroy.
func destroy_context(context_id: String) -> void:
	if not contexts.has(context_id):
		return

	var undo_redo: HistoryHandler = contexts[context_id]
	undo_redo.clear_history()
	contexts.erase(undo_redo)


## Returns the currently active undo/redo context.
##
## Returns the HistoryHandler of the active context, or null if no context is active.
func get_active_context() -> HistoryHandler:
	if active_context_id.is_empty():
		return null
	return get_context(active_context_id)
