class_name MonologueProject extends Resource

const FILE_FORMAT: String = MonologueSource.ARCHIVE_EXTENSION
const DOCUMENT_FORMAT: String = MonologueSource.DOCUMENT_EXTENSION
const FORMAT_FILTER: Array = [
	"*.%s;Monologue Project" % FILE_FORMAT, "*.%s;Monologue File" % DOCUMENT_FORMAT
]
## Name of the save dialog's checkbox, and the key its answer comes back under.
const COMPACT_OPTION: String = "Compact"

signal ready
signal content_changed
signal undo_redo_changed
signal project_path_changed

var manifest: ManifestDocument
var settings: ProjectSettingsDocument
var collections: Array[CollectionDocument]
var storylines: Array[StorylineDocument]
## True for a single .mnlp archive, false for a folder that can be diffed like source.
var compact: bool = true

var command_manager: CommandManager = CommandManager.new()
var name: String = "unsaved"
var project_path: String = ""
var is_dirty: bool = false
var active_language_code: String = "en"
## Whatever went wrong while reading this project from disk. Empty for a new project.
var load_issues: ValidationResult = ValidationResult.ok()
var default_template: ProjectTemplate = DefaultTemplate.new()
var empty_template: ProjectTemplate = EmptyTemplate.new()
var project_template: ProjectTemplate

var _object_registry: ProjectObjectRegistry = ProjectObjectRegistry.new()
var _object_registry_is_stale: bool = true


func _init(template: ProjectTemplate = default_template) -> void:
	project_template = template
	_init_documents.call_deferred()
	content_changed.connect(_on_content_changed)


## Builds the project out of its template, and only then starts listening to itself.
##
## A template writes through the same commands an edit does, so listening any earlier reports
## changes nobody made. The undo history is cleared separately, since UndoRedo records
## whether anyone listens or not.
func _init_documents() -> void:
	manifest = ManifestDocument.new(command_manager)
	settings = ProjectSettingsDocument.new(command_manager)
	storylines.append(_create_storyline("main", project_template))
	project_template.setup_collection(self)
	observe_storylines()

	command_manager.clear()
	command_manager.command_executed.connect(_on_command_executed)
	command_manager.undone.connect(_on_undo)
	command_manager.redone.connect(_on_redo)

	ready.emit()


func _create_storyline(
	sname: String, template: ProjectTemplate = default_template
) -> StorylineDocument:
	var storyline: StorylineDocument = StorylineDocument.new(sname, command_manager)
	template.setup_default_storyline(storyline)
	return storyline


## Marks the reference index for a rebuild on every graph change. Safe to call again.
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
	structure[MonologueSource.MANIFEST] = manifest
	structure[MonologueSource.SETTINGS] = settings

	var collections_map: Dictionary = {}
	for collection: CollectionDocument in collections:
		collections_map["%s.%s" % [collection.name, DOCUMENT_FORMAT]] = collection
	structure[MonologueSource.COLLECTIONS] = collections_map

	var storylines_map: Dictionary = {}
	for storyline: StorylineDocument in storylines:
		storylines_map["%s.%s" % [storyline.name, DOCUMENT_FORMAT]] = storyline
	structure[MonologueSource.STORYLINES] = storylines_map

	return structure


## Broken values, suspicious combinations, and whatever went wrong reading it from disk.
## Nothing here stops the user working.
func validate() -> ValidationResult:
	return ValidationService.validate_project(self)


## Walked again whenever the project has changed since it was last asked for.
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


## False when the name is taken or empty, and nothing is changed.
##
## A document's name is the file it is written to, so two of one name would leave only
## whichever was written second.
func rename_storyline(storyline: StorylineDocument, new_name: String) -> bool:
	var wanted: String = new_name.strip_edges()
	if wanted.is_empty() or wanted == storyline.name:
		return false

	var taken: Array[String] = _get_all_document_names(storylines)
	taken.append_array(_get_all_document_names(collections))
	if wanted in taken:
		Log.warn("'%s' is already the name of a document in this project." % wanted)
		return false

	storyline.name = wanted
	is_dirty = true
	content_changed.emit()
	ProjectManager._update_window_title()
	return true


func add_new_storyline() -> void:
	var base_name: String = "new_storyline"
	var attempt: int = 1
	var storyline_name: String = base_name
	var existing_names: Array[String] = _get_all_document_names(storylines)

	while storyline_name in existing_names:
		storyline_name = "%s_%d" % [base_name, attempt]
		attempt += 1

	storylines.append(_create_storyline(storyline_name, empty_template))
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
			[{"name": COMPACT_OPTION, "values": [], "default_value_index": 1}]
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
	# A project saved for the first time was opened before it had a path, so this is the
	# only moment it can be remembered as one to reopen.
	ProjectManager.add_path_to_history(project_path)
	ProjectManager._update_window_title()


## Takes what the save dialog came back with. An unpacked project is a folder rather
## than a file, so the extension the dialog insisted on is dropped from its path.
func _open_file_request_callback(path: String, options: Dictionary = {}) -> void:
	if options.has(COMPACT_OPTION):
		compact = options[COMPACT_OPTION] == true

	project_path = path if compact else path.get_basename()
	project_path_changed.emit()


## An archive, the folder an unpacked project lives in, or any file inside that folder --
## [method MonologueSource.open] is what tells the three apart.
static func from_path(path: String) -> MonologueProject:
	var source: MonologueSource = MonologueSource.open(path)
	if not source.is_readable:
		for problem: MonologueProblem in source.problems:
			Log.error(problem.message)
		return null

	var project: MonologueProject = MonologueProject.new()
	await project.ready

	project.compact = source.is_archive
	project.project_path = source.path
	project.name = source.path.get_file()
	project.is_dirty = false

	var result: ValidationResult = ValidationResult.ok()
	var is_usable: bool = ProjectReader.read_into(project, source, result)
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
