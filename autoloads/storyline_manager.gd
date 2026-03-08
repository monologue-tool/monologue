extends Node

signal storyline_created
signal storyline_closed
signal storyline_changed
signal storyline_switched
signal _file_prompt_done

const SAVE_PROMPT: String = "%s has been modified."

var _documents: Dictionary = {}
var _active_document_id: String
var _cancel_close: bool = false


func create_storyline(fname: String = "unnamed_storyline") -> StorylineDocument:
	var doc: StorylineDocument = StorylineDocument.new(fname)
	doc.is_dirty = true
	doc.content_changed.connect(_on_document_content_changed)
	_documents.set(doc.id, doc)
	storyline_created.emit()
	set_active_storyline(doc.id)
	return doc


func open_document(path: String) -> StorylineDocument:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	var text: String = file.get_as_text()
	var data: Dictionary = JSON.parse_string(text) if text else {}
		
	var doc: StorylineDocument = StorylineDocument.new(path.get_file())
	doc._from_dict(data)
	doc.file_path = path
	doc.is_dirty = false
	doc.content_changed.connect(_on_document_content_changed)
	_documents.set(doc.id, doc)
	storyline_created.emit()
	set_active_storyline(doc.id)
	return doc
	


func close_storyline(id: String, force: bool = false) -> void:
	_cancel_close = false
	var doc: StorylineDocument = _documents.get(id, null)
	if doc == null:
		return
		
	if doc.is_dirty and not force:
		var title: String = SAVE_PROMPT % Util.truncate_filename(doc.name)
		var description: String = "The document you have opened will be closed. Do you want to save the changes?"
		EventBus.ask_dialog.emit(_on_file_prompt_response.bind(), title, description)
		await _file_prompt_done
	
	if _cancel_close:
		return
	
	_documents.erase(id)

	if _active_document_id == id:
		var remaining: Array = _documents.keys()
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
	
func _on_file_prompt_response(storyline: StorylineDocument, response: int) -> void:
		if response == Prompt.DENIED:
			_file_prompt_done.emit()
			return
		if response == Prompt.CONFIRMED:
			if storyline.has_method("save"):
				storyline.call("save")
			_file_prompt_done.emit()
			
		_cancel_close = true
		_file_prompt_done.emit()
		return


func is_document_opened(path: String) -> bool:
	for id: String in _documents:
		var document: StorylineDocument = get_storyline(id)
		if document.file_path.simplify_path() == path.simplify_path():
			return true
	return false
