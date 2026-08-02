class_name MonologueProject extends Resource

const FILE_FORMAT: String = "mnlp"
const FORMAT_FILTER: Array = [
	"*.mnlp;Monologue Project", "*.%s;Monologue File" % InspectableDocument.FILE_FORMAT
]

signal ready
signal content_changed
signal undo_redo_changed
signal project_path_changed

var manifest: ManifestDocument
var settings: ProjectSettingsDocument
var collections: Array[CollectionDocument]
var storylines: Array[StorylineDocument]
var compact: bool = true

var command_manager: CommandManager = CommandManager.new()
var name: String = "unsaved"
var project_path: String = ""
var is_dirty: bool = false
var active_language_code: String = "en"
## Whatever went wrong while reading this project from disk. Empty for a new project.
var load_issues: ValidationResult = ValidationResult.ok()

var _object_registry: ProjectObjectRegistry = ProjectObjectRegistry.new()
var _object_registry_is_stale: bool = true


func _init() -> void:
	_init_documents.call_deferred()

	command_manager.command_executed.connect(_on_command_executed)
	command_manager.undone.connect(_on_undo)
	command_manager.redone.connect(_on_redo)
	content_changed.connect(_on_content_changed)


func _init_documents() -> void:
	manifest = ManifestDocument.new(command_manager)
	settings = ProjectSettingsDocument.new(command_manager)
	storylines.append(StorylineDocument.new("main", command_manager))
	_init_collections()
	observe_storylines()

	ready.emit()


## Subscribes to every storyline so that adding a node, removing one, or rewiring the
## graph marks the reference index for a rebuild. Safe to call again after storylines
## are loaded or added.
func observe_storylines() -> void:
	for storyline: StorylineDocument in storylines:
		for signal_name: String in ["node_added", "node_removed", "connections_changed"]:
			var storyline_signal: Signal = storyline.get(signal_name)
			if not storyline_signal.is_connected(_on_content_changed):
				storyline_signal.connect(_on_content_changed)
	_object_registry_is_stale = true


func get_all_documents() -> Array[InspectableDocument]:
	var documents: Array[InspectableDocument] = []
	documents.append(manifest)
	documents.append(settings)
	documents.append_array(collections)
	documents.append_array(storylines)
	return documents


func get_documents() -> Array[InspectableDocument]:
	var documents: Array[InspectableDocument] = []
	documents.append(manifest)
	documents.append_array(collections)
	documents.append_array(storylines)
	return documents


func get_project_structure() -> Dictionary[String, Variant]:
	var structure: Dictionary[String, Variant] = {}
	structure["manifest.json"] = manifest
	structure["settings.json"] = settings

	var collections_map: Dictionary = {}
	for collection: CollectionDocument in collections:
		collections_map["%s.json" % collection.name] = collection
	structure["collections"] = collections_map

	var storylines_map: Dictionary = {}
	for storyline: StorylineDocument in storylines:
		storylines_map["%s.json" % storyline.name] = storyline
	structure["storylines"] = storylines_map

	return structure


func _init_collections() -> void:
	var default_narrator: CollectionItem = MonologueRegistry.get_instance().create_collection_item(
		"characters", command_manager
	)
	default_narrator.set_property_value("name", "Narrator")
	default_narrator.set_property_value("protected", true)

	var default_language: CollectionItem = MonologueRegistry.get_instance().create_collection_item(
		"languages", command_manager
	)
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
		var bezier_item: CollectionItem = MonologueRegistry.get_instance().create_collection_item(
			"beziers", command_manager
		)
		bezier_item.set_property_value("name", bezier_name)
		bezier_item.set_property_value("bezier", default_beziers.get(bezier_name))
		beziers_data.append(bezier_item._to_dict())

	collections.append(
		CollectionDocument.new("characters", [default_narrator._to_dict()], command_manager)
	)
	collections.append(CollectionDocument.new("variables", [], command_manager))
	collections.append(CollectionDocument.new("items", [], command_manager))
	collections.append(CollectionDocument.new("locations", [], command_manager))
	collections.append(
		CollectionDocument.new("languages", [default_language._to_dict()], command_manager)
	)
	collections.append(CollectionDocument.new("beziers", beziers_data, command_manager))


## Sweeps the whole project for problems: broken values, suspicious combinations, and
## whatever went wrong the last time it was read from disk.
##
## Nothing here stops the user working; it is what the problems panel lists.
func validate() -> ValidationResult:
	return ValidationService.validate_project(self)


## The project's identity map and reverse reference index, walked again whenever the
## project has changed since it was last asked for.
func get_object_registry() -> ProjectObjectRegistry:
	if _object_registry_is_stale:
		_object_registry_is_stale = false
		_object_registry.rebuild(self)
	return _object_registry


func _on_content_changed() -> void:
	_object_registry_is_stale = true


func get_collection(collection_name: String) -> CollectionDocument:
	for collection: CollectionDocument in collections:
		if collection.name == collection_name:
			return collection
	return null


func get_collection_value(collection_name: String) -> Array:
	var collection: CollectionDocument = get_collection(collection_name)
	if collection:
		return collection.get_value()

	Log.error("Can't find collection '%s'" % collection_name)
	return []


func get_storyline(storyline_id: String) -> StorylineDocument:
	for storyline: StorylineDocument in storylines:
		if storyline.id == storyline_id:
			return storyline
	return null


func delete_storyline(storyline: StorylineDocument) -> void:
	if storylines.size() <= 1:
		Log.warn("The storyline couldn't be removed, it's the only one left.")
		return

	storylines.erase(storyline)
	EventBus.storyline_deleted.emit()


func add_new_storyline() -> void:
	var base_name: String = "new_storyline"
	var attempt: int = 1
	var storyline_name: String = base_name
	var existing_names: Array[String] = _get_all_document_names(storylines)

	while storyline_name in existing_names:
		storyline_name = "%s_%d" % [base_name, attempt]
		attempt += 1

	storylines.append(StorylineDocument.new(storyline_name, command_manager))
	observe_storylines()


func _get_all_document_names(documents: Array) -> Array[String]:
	var result: Array[String] = []
	for doc: InspectableDocument in documents:
		result.append(doc.name)
	return result


func _on_command_executed() -> void:
	is_dirty = true
	content_changed.emit()
	undo_redo_changed.emit()
	ProjectManager._update_window_title()


func _on_undo() -> void:
	is_dirty = true
	content_changed.emit()
	undo_redo_changed.emit()
	ProjectManager._update_window_title()


func _on_redo() -> void:
	is_dirty = true
	content_changed.emit()
	undo_redo_changed.emit()
	ProjectManager._update_window_title()


func save() -> void:
	if project_path.is_empty():
		EventBus.save_file_request.emit(
			_open_file_request_callback,
			FORMAT_FILTER,
			"",
			[{"name": "Compact", "values": [], "default_value_index": 1}]
		)
		await project_path_changed

	# Saving a project that only partly loaded writes the surviving parts over the
	# original, losing whatever could not be read. Say so loudly.
	# TODO: ask for confirmation instead, once there is a place to ask from.
	if not load_issues.is_valid():
		Log.warn(
			(
				"Saving over '%s', which had %d error(s) when it was opened. "
				+ "Anything that failed to load will be lost."
			) % [project_path, load_issues.errors().size()]
		)

	var result: ValidationResult = ProjectWriter.write_project(self, project_path)
	if not result.is_valid():
		for issue: ValidationIssue in result.errors():
			Log.error(str(issue))
		return

	is_dirty = false
	Log.info("Project saved at path '%s'" % project_path)
	ProjectManager._update_window_title()


func _open_file_request_callback(path: String) -> void:
	project_path = path
	project_path_changed.emit()


static func from_file_path(path: String) -> MonologueProject:
	if not path.ends_with(".%s" % FILE_FORMAT) or not FileAccess.file_exists(path):
		Log.error("Can't load project from an invalid path.")
		return null

	var reader: ZIPReader = ZIPReader.new()
	if reader.open(path) != OK:
		Log.error("Can't open '%s' as a Monologue project." % path)
		return null

	var project: MonologueProject = await _from_path_core(reader, path)
	reader.close()
	if project:
		project.compact = true
	return project


static func from_dir_path(path: String) -> MonologueProject:
	if not DirAccess.dir_exists_absolute(path):
		Log.error("Can't load project from an invalid path.")
		return null

	var reader: DirAccess = DirAccess.open(path)

	var project: MonologueProject = await _from_path_core(reader, path)
	if project:
		project.compact = false
	return project


## 'reader' can be either a 'ZIPReader' or a 'DirAccess'.
static func _from_path_core(reader: Variant, path: String) -> MonologueProject:
	var project: MonologueProject = MonologueProject.new()
	await project.ready

	project.project_path = path
	project.name = path.get_file()
	project.is_dirty = false

	var result: ValidationResult = ValidationResult.ok()
	var is_usable: bool = ProjectReader.read_into(project, reader, result)
	project.load_issues = result
	project.observe_storylines()

	for issue: ValidationIssue in result.issues:
		if issue.is_error():
			Log.error(str(issue))
		else:
			Log.warn(str(issue))

	# Only an unreadable manifest is fatal. Anything else loads partially, with the
	# damage listed, rather than throwing away the parts that were fine.
	return project if is_usable else null
