extends Node

var _documents: Dictionary = {}
var _active_document_id: String
var _observers: Array = []


func create_storyline(fname: String) -> StorylineDocument:
	var doc: StorylineDocument = StorylineDocument.new(fname)
	_documents.set(doc.id, doc)
	set_active_storyline(doc.id)
	notify_change()
	return doc


func close_storyline(id: String) -> void:
	if _documents.get(id).is_dirty:
		# Save changes ?
		return
	_documents.erase(id)

	if _active_document_id == id:
		var remaining = _documents.keys()
		_active_document_id = remaining[0]

	notify_change()


func set_active_storyline(id: String) -> void:
	_active_document_id = id


func get_storyline(id: String) -> StorylineDocument:
	return _documents.get(id, null)


func get_storyline_ids() -> Array:
	return _documents.keys()


func get_active_storyline() -> StorylineDocument:
	return _documents.get(_active_document_id)


func add_observer(object: Object) -> void:
	if object in _observers:
		push_warning("Observer is already registered.")
		return

	_observers.append(object)


func notify_change() -> void:
	for observer: Object in _observers:
		if not observer.has_method("on_storyline_change"):
			push_warning("Object doesn't have method 'on_storyline_change'.")
			return

		observer.call("on_storyline_change")
