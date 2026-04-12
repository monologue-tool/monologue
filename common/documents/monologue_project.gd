class_name MonologueProject extends Resource

const FILE_FORMAT: String = "mnlp"

signal ready
signal content_changed
signal undo_redo_changed
signal _project_path_changed

var manifest: ManifestDocument
var collections: Array[CollectionDocument]
var storylines: Array[StorylineDocument]
var compact: bool = true

var command_manager: CommandManager = CommandManager.new()
var project_path: String = ""
var is_dirty: bool = false
var active_language_code: String = "en"


func _init() -> void:
	_init_documents.call_deferred()
	
	command_manager.command_executed.connect(_on_command_executed)
	command_manager.undone.connect(_on_undo)
	command_manager.redone.connect(_on_redo)


func _init_documents() -> void:
	manifest = ManifestDocument.new(command_manager)
	storylines.append(StorylineDocument.new("main", command_manager))
	_init_collections()
	
	ready.emit()


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


func get_collection(collection_name: String) -> CollectionDocument:
	for collection: CollectionDocument in collections:
		if not collection.name == collection_name:
			continue
		return collection
	return


func get_collection_value(collection_name: String) -> Array:
	var collection: CollectionDocument = get_collection(collection_name)
	if collection:
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
	if project_path.is_empty():
		EventBus.save_file_request.emit(
			_open_file_request_callback,
			["*.%s;Monologue Project" % FILE_FORMAT],
			"",
			[{"name": "Compact", "values": [], "default_value_index": 1}]
		)
		await _project_path_changed
	
	var writer: ZIPPacker = ZIPPacker.new()
	writer.compression_level = 0
	var err: Error = writer.open(project_path, ZIPPacker.APPEND_CREATE)
	if err != OK:
		Log.error(err)
		return
	
	pack_document(writer, manifest, "manifest.json")
	for collection: CollectionDocument in collections:
		pack_document(writer, collection, "collections/%s.json" % collection.name)
	for storyline: StorylineDocument in storylines:
		pack_document(writer, storyline, "storylines/%s.json" % storyline.name)

	writer.close()
	is_dirty = false
	Log.info("Project saved at path '%s'" % project_path)


func pack_document(writer: ZIPPacker, document: InspectableDocument, path: String) -> void:
	var data: Dictionary = document._to_dict()
	var s_data: String = JSON.stringify(data, "\t")
	
	writer.start_file(path)
	writer.write_file(s_data.to_utf8_buffer())
	writer.close_file()


func _open_file_request_callback(path: String) -> void:
	project_path = path
	_project_path_changed.emit()


static func from_path(path: String) -> MonologueProject:
	if not path.ends_with(".%s" % FILE_FORMAT) or not FileAccess.file_exists(path):
		Log.error("Can't load project from an invalid path.")
		return
	
	var reader: ZIPReader = ZIPReader.new()
	reader.open(path)
	var files: PackedStringArray = reader.get_files()
	
	var project: MonologueProject = MonologueProject.new()
	await project.ready
	
	project.project_path = path
	project.is_dirty = false
	
	if reader.file_exists("manifest.json"):
		var manifest_content: String = reader.read_file("manifest.json").get_string_from_utf8()
		var manifest_data: Dictionary = JSON.parse_string(manifest_content)
		project.manifest._from_dict(manifest_data)
	
	for file: String in files:
		var paths: Array = file.split("/") as Array
		if paths.size() <= 1:
			continue
		
		var file_name: String = paths.back().get_basename()
		var extension: String = paths.back().get_extension()
		if extension != "json":
			Log.error("Attempt to load an non-JSON file.")
			continue
		
		if paths[0] == "collections":
			var collection_content: String = reader.read_file(file).get_string_from_utf8()
			_load_collection_from_file(project, file_name, collection_content)
		
		project.storylines.clear()
		if paths[0] == "storylines":
			var storyline_content: String = reader.read_file(file).get_string_from_utf8()
			_load_storyline_from_file(project, file_name, storyline_content)

	return project


static func _load_collection_from_file(project: MonologueProject, collection_name: String, file_content: String) -> void:
	for collection: CollectionDocument in project.collections:
		if collection.name != collection_name:
			continue
		
		var collection_data: Dictionary = JSON.parse_string(file_content)
		collection._from_dict(collection_data)
		return
	
	Log.error("Can't find the collection '%s' inside the project.")


static func _load_storyline_from_file(project: MonologueProject, storyline_name: String, file_content: String) -> void:
	var storyline: StorylineDocument = StorylineDocument.new(storyline_name, project.command_manager)
	var storyline_data: Dictionary = JSON.parse_string(file_content)
		
	storyline._from_dict(storyline_data)
	project.storylines.append(storyline)
