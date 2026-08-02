## Reads a project back from a .mnlp archive or an unpacked directory.
##
## Every failure is reported rather than raised: a truncated file, a corrupt document,
## a node type this build does not know about. The project still loads, missing the
## parts that could not be read, and the caller decides what to tell the user.
class_name ProjectReader

const MANIFEST_FILE: String = "manifest.json"
const SETTINGS_FILE: String = "settings.json"
const COLLECTIONS_DIR: String = "collections"
const STORYLINES_DIR: String = "storylines"


## Parses [param raw] and checks it really is a JSON object.
## Returns an empty Dictionary and records an issue when it is not.
static func parse_object(raw: String, source: String, result: ValidationResult) -> Dictionary:
	var parsed: Variant = JSON.parse_string(raw)
	# The document name goes in the issue's location, not in its message, or it reads
	# back as "'main.json' is not valid JSON. (main.json)".
	if parsed == null:
		result.add(
			ValidationIssue.error("Not valid JSON.", &"unreadable_json").in_document(source)
		)
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


## Reads the format version out of a manifest, defaulting to the current one when the
## file predates the field.
static func read_format_version(manifest_data: Dictionary) -> int:
	var raw: Variant = manifest_data.get("format_version", {})
	if raw is Dictionary:
		return int((raw as Dictionary).get("value", ManifestDocument.FORMAT_VERSION))
	return int(raw)


## Fills [param project] from [param reader], which is a [ZIPReader] or a [DirAccess].
## Both expose get_files() / file_exists() / read_file().
static func read_into(
	project: MonologueProject, reader: Variant, result: ValidationResult
) -> bool:
	if not _read_manifest(project, reader, result):
		return false

	if reader.file_exists(SETTINGS_FILE):
		var settings_data: Dictionary = parse_object(
			_read_text(reader, SETTINGS_FILE), SETTINGS_FILE, result
		)
		if not settings_data.is_empty():
			project.settings._from_dict(settings_data)

	project.storylines.clear()

	for file: String in reader.get_files():
		# An archive lists its directories too, as entries ending in a slash. They are
		# not files that failed to be JSON, so they are not worth reporting.
		if file.ends_with("/"):
			continue

		var segments: PackedStringArray = file.split("/")
		if segments.size() <= 1:
			continue
		if segments[-1].get_extension() != "json":
			result.add_warning("Skipped non-JSON file '%s'." % file, &"unexpected_file")
			continue

		var document_name: String = segments[-1].get_basename()
		var content: String = _read_text(reader, file)

		match segments[0]:
			COLLECTIONS_DIR:
				_read_collection(project, document_name, content, result)
			STORYLINES_DIR:
				_read_storyline(project, document_name, content, result)

	if project.storylines.is_empty():
		result.add_warning(
			"This project has no readable storyline.", &"no_storyline"
		)
	return true


static func _read_manifest(
	project: MonologueProject, reader: Variant, result: ValidationResult
) -> bool:
	if not reader.file_exists(MANIFEST_FILE):
		result.add_error("The project has no %s." % MANIFEST_FILE, &"missing_manifest")
		return false

	var manifest_data: Dictionary = parse_object(
		_read_text(reader, MANIFEST_FILE), MANIFEST_FILE, result
	)
	if manifest_data.is_empty():
		return false

	var version: int = read_format_version(manifest_data)
	if version > ManifestDocument.FORMAT_VERSION:
		result.add_error(
			(
				"This project was made with a newer version of Monologue (file format %d, "
				+ "this build reads up to %d)."
			) % [version, ManifestDocument.FORMAT_VERSION],
			&"future_format"
		)
		return false

	if not ProjectMigrator.can_migrate(version):
		ProjectMigrator.migrate(manifest_data, version, result)
		return false

	project.manifest._from_dict(manifest_data)
	# The manifest now describes a project in the current format, whatever it said on
	# disk, so the next save writes the version this build actually produces.
	project.manifest.get_property("format_version").set_value(ManifestDocument.FORMAT_VERSION)
	return true


static func _read_collection(
	project: MonologueProject, collection_name: String, content: String, result: ValidationResult
) -> void:
	var collection: CollectionDocument = project.get_collection(collection_name)
	if not collection:
		result.add_warning(
			"The project file has a collection named '%s', which this build does not know."
			% collection_name,
			&"unknown_collection"
		)
		return

	var data: Dictionary = parse_object(content, "%s.json" % collection_name, result)
	if not data.is_empty():
		collection._from_dict(data)


static func _read_storyline(
	project: MonologueProject, storyline_name: String, content: String, result: ValidationResult
) -> void:
	var data: Dictionary = parse_object(content, "%s.json" % storyline_name, result)
	if data.is_empty():
		return

	var storyline: StorylineDocument = StorylineDocument.new(
		storyline_name, project.command_manager
	)
	storyline._from_dict(data)
	for issue: ValidationIssue in storyline.load_issues:
		result.add(issue.in_document(storyline_name))
	project.storylines.append(storyline)


static func _read_text(reader: Variant, path: String) -> String:
	return reader.read_file(path).get_string_from_utf8()
