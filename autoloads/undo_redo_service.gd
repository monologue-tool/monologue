# UndoRedoService
extends Node

const MAX_STEPS: int = 100

var contexts: Dictionary = {}
var active_context_id: String = ""


func create_context(context_id: String) -> HistoryHandler:
	if contexts.has(context_id):
		return contexts[context_id]

	var undo_redo: HistoryHandler = HistoryHandler.new()
	undo_redo.max_steps = MAX_STEPS
	contexts[context_id] = undo_redo
	return undo_redo


func get_context(context_id: String) -> HistoryHandler:
	return contexts.get(context_id, null)


func destroy_context(context_id: String) -> void:
	if not contexts.has(context_id):
		return

	var undo_redo: HistoryHandler = contexts[context_id]
	undo_redo.clear_history()
	contexts.erase(undo_redo)


func get_active_context() -> HistoryHandler:
	if active_context_id.is_empty():
		return null
	return get_context(active_context_id)
