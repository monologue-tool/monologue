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
	storyline_created.emit()
	set_active_storyline(doc.id)
	return doc


func open_document(path: String) -> StorylineDocument:
	var file = FileAccess.open(path, FileAccess.READ)
	var text = file.get_as_text()
	var data = JSON.parse_string(text) if text else {}
		
	var doc: StorylineDocument = StorylineDocument.new(path.get_file())
	doc._from_dict(data)
	doc.file_path = path
	doc.is_dirty = false
	doc.content_changed.connect(_on_document_content_changed)
	_documents.set(doc.id, doc)
	storyline_created.emit()
	set_active_storyline(doc.id)
	return doc
	


func close_storyline(id: String) -> void:
	var doc = _documents.get(id, null)
	if doc == null:
		return
	if doc.is_dirty:
		# TODO: Save changes ?
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
	storyline_switched.emit()


func get_storyline(id: String) -> StorylineDocument:
	return _documents.get(id, null)


func get_storyline_ids() -> Array:
	return _documents.keys()


func get_active_storyline() -> StorylineDocument:
	return _documents.get(_active_document_id)


func _on_document_content_changed() -> void:
	storyline_changed.emit()


func is_document_opened(path: String) -> bool:
	for id in _documents:
		var document: StorylineDocument = get_storyline(id)
		if document.file_path.simplify_path() == path.simplify_path():
			return true
	return false
