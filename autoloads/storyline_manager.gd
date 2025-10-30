## Storyline document manager singleton.
##
## Manages multiple open storyline documents, tracks the active document,
## and notifies observers of changes. Provides document lifecycle management
## including creation, switching, and closing.
extends Node

## Dictionary of all open storyline documents, keyed by document ID.
var _documents: Dictionary = {}

## ID of the currently active/focused document.
var _active_document_id: String

## Array of observer objects that are notified when storyline state changes.
var _observers: Array = []


## Creates a new storyline document with the given filename.
##
## Creates a new StorylineDocument, adds it to the document collection,
## sets it as active, and notifies observers.
## [br][br]
## [param fname] The filename for the new storyline document.
## [br][br]
## Returns the newly created StorylineDocument.
func create_storyline(fname: String) -> StorylineDocument:
	var doc: StorylineDocument = StorylineDocument.new(fname)
	_documents.set(doc.id, doc)
	set_active_storyline(doc.id)
	notify_change()
	return doc


## Closes a storyline document by its ID.
##
## Removes the document from the collection. If the closed document was active,
## switches to another open document or clears the active ID. Currently checks
## for unsaved changes but does not prompt (commented out).
## [br][br]
## [param id] The ID of the document to close.
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
	notify_change()


## Sets the active storyline document by ID.
##
## [param id] The ID of the document to make active.
func set_active_storyline(id: String) -> void:
	_active_document_id = id


## Retrieves a storyline document by its ID.
##
## [param id] The ID of the document to retrieve.
## [br][br]
## Returns the StorylineDocument if found, null otherwise.
func get_storyline(id: String) -> StorylineDocument:
	return _documents.get(id, null)


## Returns an array of all open storyline document IDs.
func get_storyline_ids() -> Array:
	return _documents.keys()


## Returns the currently active storyline document.
##
## Returns the active StorylineDocument, or null if no document is active.
func get_active_storyline() -> StorylineDocument:
	return _documents.get(_active_document_id)


## Registers an observer object to be notified of storyline changes.
##
## The observer must implement an [code]on_storyline_change()[/code] method.
## [br][br]
## [param object] The object to register as an observer.
func add_observer(object: Object) -> void:
	if object in _observers:
		push_warning("Observer is already registered.")
		return

	_observers.append(object)


## Notifies all registered observers of a storyline state change.
##
## Calls the [code]on_storyline_change()[/code] method on each registered observer.
func notify_change() -> void:
	for observer: Object in _observers:
		if not observer.has_method("on_storyline_change"):
			push_warning("Object doesn't have method 'on_storyline_change'.")
			continue

		observer.call("on_storyline_change")
