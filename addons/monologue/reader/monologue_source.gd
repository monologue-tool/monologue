## A project's documents, parsed and named, wherever they came from.
##
## The one place that knows what a Monologue project looks like. Which four kinds of document
## there are, where they sit, and how to read them out of an archive, a folder or memory.
## Everything downstream asks this and never touches a file.
class_name MonologueSource extends RefCounted

const ARCHIVE_EXTENSION: String = "mnlp"
## What one document inside a project is called. The content is JSON either way. The
## extension says whose it is, so a folder project does not read as a pile of loose data.
const DOCUMENT_EXTENSION: String = "mnlf"
const MANIFEST: String = "manifest.%s" % DOCUMENT_EXTENSION
const SETTINGS: String = "settings.%s" % DOCUMENT_EXTENSION
const COLLECTIONS: String = "collections"
const STORYLINES: String = "storylines"
const SUPPORTED_FORMAT_VERSION: int = 1

var problems: Array[MonologueProblem] = []
## The folder or archive this came from. Empty for documents held in memory.
var path: String = ""
var is_archive: bool = false
## False only when there was nothing to open at all. One document failing to parse is
## reported and skipped, so a damaged storyline does not cost the reader the rest.
var is_readable: bool = true

## entry path -> parsed document
var _documents: Dictionary = {}


## An archive, a folder, or any file inside one. A file dialog lets the user point at a file,
## which means the folder it sits in.
static func open(project_path: String) -> MonologueSource:
	var source: MonologueSource = MonologueSource.new()
	source.path = project_path

	if project_path.is_empty():
		return source._cannot_open(&"no_path", "No story to read.")

	if FileAccess.file_exists(project_path):
		if project_path.get_extension().to_lower() == ARCHIVE_EXTENSION:
			source.is_archive = true
			source._read_archive()
			return source._checked()
		source.path = project_path.get_base_dir()

	if not DirAccess.dir_exists_absolute(source.path):
		return source._cannot_open(&"story_not_found", "Nothing to read at '%s'." % project_path)

	source._walk("")
	return source._checked()


## Documents already in memory, keyed by entry path the way an archive lists them. Lets a
## story play straight out of an editor, before it has ever been saved.
static func of(documents: Dictionary) -> MonologueSource:
	var source: MonologueSource = MonologueSource.new()
	source._documents = documents
	return source._checked()


## Where one document sits inside a project, archive and folder alike. The only place the
## layout is spelled out, so writing and reading cannot drift apart.
static func document_path(directory: String, document_name: String) -> String:
	return "%s/%s.%s" % [directory, document_name, DOCUMENT_EXTENSION]


func manifest() -> Dictionary:
	return _documents.get(MANIFEST, {})


func settings() -> Dictionary:
	return _documents.get(SETTINGS, {})


## Collection name -> its document.
func collections() -> Dictionary:
	return _under(COLLECTIONS)


func storylines() -> Dictionary:
	return _under(STORYLINES)


## A collection document holds its records under its own name. Unwrapped here, so nothing
## downstream has to know that.
func records(collection_name: String) -> Array:
	var document: Dictionary = collections().get(collection_name, {})
	var found: Variant = document.get(collection_name, [])
	return found if found is Array else []


## What a story says it begins with.
func entry_point() -> String:
	return str(manifest().get("entry_point", ""))


## Absent means the file predates the field, which is the version this reads.
func format_version() -> int:
	return int(manifest().get("format_version", SUPPORTED_FORMAT_VERSION))


func _fault(code: StringName, message: String, document: String = "") -> void:
	var problem: MonologueProblem = MonologueProblem.error(code, message)
	problems.append(problem.in_document(document) if not document.is_empty() else problem)


func _cannot_open(code: StringName, message: String) -> MonologueSource:
	is_readable = false
	_fault(code, message)
	return self


## A manifest is what makes a pile of documents a story. A format from the future is one this
## cannot be trusted to read. Both are refusals, not damage.
func _checked() -> MonologueSource:
	if not is_readable:
		return self

	if manifest().is_empty():
		return _cannot_open(&"missing_manifest", "The story has no %s." % MANIFEST)

	var version: int = format_version()
	if version > SUPPORTED_FORMAT_VERSION:
		return _cannot_open(
			&"future_format",
			"This story was written by a newer Monologue (format %d, this reads up to %d)."
			% [version, SUPPORTED_FORMAT_VERSION]
		)
	return self


func _under(directory: String) -> Dictionary:
	var found: Dictionary = {}
	var prefix: String = directory + "/"
	for entry_path: String in _documents:
		if entry_path.begins_with(prefix):
			found[entry_path.get_file().get_basename()] = _documents[entry_path]
	return found


func _read_archive() -> void:
	var archive: ZIPReader = ZIPReader.new()
	if archive.open(path) != OK:
		_cannot_open(&"unreadable_story", "Could not open '%s'." % path)
		return

	for entry_path: String in archive.get_files():
		# An archive lists its folders too, as entries ending in a slash.
		if not entry_path.ends_with("/"):
			_take(entry_path, archive.read_file(entry_path).get_string_from_utf8())

	archive.close()


func _walk(relative: String) -> void:
	var directory: DirAccess = DirAccess.open(path.path_join(relative))
	if directory == null:
		return

	for file_name: String in directory.get_files():
		var entry_path: String = relative.path_join(file_name)
		var file: FileAccess = FileAccess.open(path.path_join(entry_path), FileAccess.READ)
		if file == null:
			problems.append(
				MonologueProblem.warning(&"unreadable_file", "Could not read '%s'." % entry_path)
			)
			continue
		_take(entry_path, file.get_as_text())

	for directory_name: String in directory.get_directories():
		_walk(relative.path_join(directory_name))


## A truncated file and a file holding a list are different mistakes, and are reported as
## such rather than guessed at.
func _take(entry_path: String, raw: String) -> void:
	if entry_path.get_extension().to_lower() != DOCUMENT_EXTENSION:
		return

	var parsed: Variant = JSON.parse_string(raw)
	if parsed is Dictionary:
		_documents[entry_path] = parsed
		return

	if parsed == null:
		_fault(&"unreadable_json", "Not valid JSON.", entry_path)
		return
	_fault(
		&"unexpected_json_shape",
		"Should contain a JSON object, found %s." % type_string(typeof(parsed)),
		entry_path
	)
