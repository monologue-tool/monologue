class_name MonologueProject extends Resource

const FILE_FORMAT: String = "mnlp"

signal content_changed
signal undo_redo_changed

var manifest: ManifestDocument
var collections: Array[CollectionDocument]
var storylines: Array[StorylineDocument]
var compact: bool = true

var command_manager: CommandManager = CommandManager.new()
var project_path: String = ""
var is_dirty: bool = false
var active_language_code: String = "en"


func _init() -> void:
	command_manager.command_executed.connect(_on_command_executed)
	command_manager.undone.connect(_on_undo)
	command_manager.redone.connect(_on_redo)
	
	_init_documents.call_deferred()
	
func _init_documents() -> void:
	manifest = ManifestDocument.new(command_manager)
	storylines.append(StorylineDocument.new("main", command_manager))
	_init_collections()


func _init_collections() -> void:
	var default_narrator: ListItem = CollectionBucket.create_item("characters", command_manager)
	default_narrator.set_property_value("name", "Narrator")
	default_narrator.set_property_value("protected", true)
	
	var default_language: ListItem = CollectionBucket.create_item("languages", command_manager)
	default_language.set_property_value("name", "English")
	default_language.set_property_value("code", "en")
	default_language.set_property_value("protected", true)
	
	var default_beziers: Dictionary = {
		"Ease": [0.25, 0.10, 0.25, 1.0],
		"Linear": [0.0, 0.0, 1.0, 1.0],
		"Ease-In": [0.42, 0.0, 1.0, 1.0],
		"Ease-Out": [0.0, 0.0, 0.58, 1.0],
		"Ease-In-Out": [0.42, 0.0, 0.58, 1.0]
	}
	var beziers_data: Array = []
	for bezier_name: String in default_beziers:
		var bezier_item: ListItem = CollectionBucket.create_item("beziers", command_manager)
		bezier_item.set_property_value("name", bezier_name)
		bezier_item.set_property_value("bezier", default_beziers.get(bezier_name))
		beziers_data.append(bezier_item._to_dict())
	
	collections.append(CollectionDocument.new("characters", [default_narrator._to_dict()], command_manager))
	collections.append(CollectionDocument.new("variables", [], command_manager))
	collections.append(CollectionDocument.new("items", [], command_manager))
	collections.append(CollectionDocument.new("locations", [], command_manager))
	collections.append(CollectionDocument.new("languages", [default_language._to_dict()], command_manager))
	collections.append(CollectionDocument.new("beziers", beziers_data, command_manager))


func get_documents() -> Array[InspectableDocument]:
	var documents: Array[InspectableDocument] = []
	documents.append(manifest)
	documents.append_array(collections)
	documents.append_array(storylines)
	
	return documents

func get_collection_value(collection_name: String) -> Array:
	for collection: CollectionDocument in collections:
		if not collection.name == collection_name:
			continue
		return collection.get_value()
	
	Log.error("Can't find collection '%s'" % collection_name)
	return []


func get_storyline(storyline_id: String) -> StorylineDocument:
	for storyline: StorylineDocument in storylines:
		if not storyline.id == storyline_id:
			continue
		return storyline
	return


func add_new_storyline() -> void:
	var base_name: String = "new_storyline"
	var try: int = 1
	var name: String = base_name
	var names: Array[String] = _get_all_documents_name(storylines)
	
	while name in names:
		name = base_name + " %s" % try
		try += 1
	
	storylines.append(StorylineDocument.new(name, command_manager))


func is_valid_storyline_name(name: String) -> bool:
	for doc_name: String in _get_all_documents_name(storylines):
		if doc_name == name:
			return true
	
	return false


func _get_all_documents_name(documents: Array) -> Array[String]:
	var result: Array[String] = []
	for doc: InspectableDocument in documents:
		result.append(doc.name)
	
	return result

func _on_command_executed() -> void:
	is_dirty = true
	content_changed.emit()
	undo_redo_changed.emit()


func _on_undo() -> void:
	content_changed.emit()
	undo_redo_changed.emit()


func _on_redo() -> void:
	is_dirty = true
	content_changed.emit()
	undo_redo_changed.emit()


func save() -> void:
	# TODO Open a window to select the path, check if the location is empty and ask if the user want a compact project or no.
	if project_path.is_empty():
		_ask_path()


func _ask_path() -> void:
	EventBus.open_dir_request.emit(_open_dir_request_callback)
	

func _open_dir_request_callback(path: String) -> void:
	project_path = path
