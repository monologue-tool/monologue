extends Node

signal storyline_created
signal storyline_closed
signal storyline_changed
signal storyline_switched

var _documents: Dictionary = {}
var _active_document_id: String


func create_storyline(fname: String = "unnamed_storyline") -> StorylineDocument:
	var doc: StorylineDocument = StorylineDocument.new(fname)
	doc.is_dirty = true
	doc.content_changed.connect(_on_document_content_changed)
	_documents.set(doc.id, doc)
	set_active_storyline(doc.id)
	storyline_created.emit()
	if _documents.size() <= 1:
		storyline_switched.emit()
	return doc


func close_storyline(id: String) -> void:
	var doc = _documents.get(id, null)
	if doc == null:
		return
	if doc.is_dirty:
		# Save changes ?
		return
	_documents.erase(id)

	if _active_document_id == id:
		var remaining = _documents.keys()
		if remaining.size() > 0:
			_active_document_id = remaining[0]
		else:
			_active_document_id = ""
	storyline_closed.emit()


func set_active_storyline(id: String) -> void:
	_active_document_id = id


func get_storyline(id: String) -> StorylineDocument:
	return _documents.get(id, null)


func get_storyline_ids() -> Array:
	return _documents.keys()


func get_active_storyline() -> StorylineDocument:
	return _documents.get(_active_document_id)


func _on_document_content_changed() -> void:
	storyline_changed.emit()
