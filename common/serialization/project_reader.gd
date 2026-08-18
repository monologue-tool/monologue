## Fills a project from documents a [MonologueSource] already read and parsed.
##
## Every failure is reported rather than raised: a truncated file, a corrupt document, a node
## type this build does not know about. The project still loads, missing the parts that could
## not be read, and the caller decides what to tell the user.
class_name ProjectReader


## Parses [param raw] and checks it really is a JSON object, recording why when it is not.
## A project's own documents come parsed from the source; this is for everything else the
## editor reads, such as its configuration file.
static func parse_object(raw: String, source: String, result: ValidationResult) -> Dictionary:
	var parsed: Variant = JSON.parse_string(raw)
	# The document name goes in the issue's location, not in its message, or it reads back
	# as "'main.mnlf' is not valid JSON. (main.mnlf)".
	if parsed == null:
		result.add(ValidationIssue.error("Not valid JSON.", &"unreadable_json").in_document(source))
		return {}
	if parsed is not Dictionary:
		result.add(
			ValidationIssue.error(
				"Should contain a JSON object, found %s." % type_string(typeof(parsed)),
				&"unexpected_json_shape"
			).in_document(source)
		)
		return {}
	return parsed


## Reads the format version out of a manifest, defaulting to the current one when the file
## predates the field.
static func read_format_version(manifest_data: Dictionary) -> int:
	return int(manifest_data.get("format_version", ManifestDocument.FORMAT_VERSION))


## False when the manifest is missing, unreadable, or from a version this build cannot open.
static func read_into(
	project: MonologueProject, source: MonologueSource, result: ValidationResult
) -> bool:
	for problem: MonologueProblem in source.problems:
		result.add(_as_issue(problem))

	# A missing manifest or a format from the future are the source's refusals, already
	# reported above. Nothing here can improve on them.
	if not source.is_readable:
		return false

	if not _read_manifest(project, source, result):
		return false

	var settings_data: Dictionary = source.settings()
	if not settings_data.is_empty():
		project.settings._from_dict(settings_data)

	var collections: Dictionary = source.collections()
	for collection_name: String in collections:
		_read_collection(project, collection_name, collections[collection_name], result)

	project.storylines.clear()
	var storylines: Dictionary = source.storylines()
	for storyline_name: String in storylines:
		_read_storyline(project, storyline_name, storylines[storyline_name], result)

	if project.storylines.is_empty():
		result.add_warning("This project has no readable storyline.", &"no_storyline")
	return true


## The addon reports in its own currency, since it knows nothing of the editor. This is the
## exchange, and the only place the two vocabularies meet.
## One of the runtime's problems as one of the editor's issues. The two say the same thing
## in two vocabularies, and this is the only place they are translated.
static func _as_issue(problem: MonologueProblem) -> ValidationIssue:
	var issue: ValidationIssue = (
		ValidationIssue.error(problem.message, problem.code)
		if problem.is_error()
		else ValidationIssue.warning(problem.message, problem.code)
	)
	return issue.in_document(problem.document) if not problem.document.is_empty() else issue


static func _read_manifest(
	project: MonologueProject, source: MonologueSource, result: ValidationResult
) -> bool:
	var manifest_data: Dictionary = source.manifest()
	var version: int = read_format_version(manifest_data)

	# Only a format too old to open is left to judge: the source already refused one too new.
	if not ProjectMigrator.can_migrate(version):
		ProjectMigrator.migrate(manifest_data, version, result)
		return false

	project.manifest._from_dict(manifest_data)
	# The manifest now describes a project in the current format, whatever it said on disk, so
	# the next save writes the version this build actually produces.
	project.manifest.get_property("format_version").set_value(ManifestDocument.FORMAT_VERSION)
	return true


static func _read_collection(
	project: MonologueProject,
	collection_name: String,
	data: Dictionary,
	result: ValidationResult
) -> void:
	var collection: CollectionDocument = project.get_collection(collection_name)
	if collection == null:
		result.add_warning(
			"The project file has a collection named '%s', which this build does not know."
			% collection_name,
			&"unknown_collection"
		)
		return
	collection._from_dict(data)


static func _read_storyline(
	project: MonologueProject,
	storyline_name: String,
	data: Dictionary,
	result: ValidationResult
) -> void:
	var storyline: StorylineDocument = StorylineDocument.new(
		storyline_name, project.command_manager
	)
	storyline._from_dict(data)
	for issue: ValidationIssue in storyline.load_issues:
		result.add(issue.in_document(storyline_name))
	project.storylines.append(storyline)
