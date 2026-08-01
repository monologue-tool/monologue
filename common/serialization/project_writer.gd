## Writes a project to a .mnlp archive.
##
## The write is atomic: everything goes into a temporary file first, and the real
## archive is only replaced once that succeeded. Two things fall out of that.
class_name ProjectWriter

const TEMP_SUFFIX: String = ".saving"
const BACKUP_SUFFIX: String = ".previous"


## Writes [param project] to [param path]. The returned result carries an error issue
## when nothing was written; the file on disk is untouched in that case.
static func write_project(project: MonologueProject, path: String) -> ValidationResult:
	var result: ValidationResult = ValidationResult.ok()
	if project == null:
		return result.add_error("No project to save.", &"no_project")
	if path.is_empty():
		return result.add_error("No path to save to.", &"no_path")

	var temp_path: String = path + TEMP_SUFFIX
	var pack_result: ValidationResult = _pack_documents(project, temp_path)
	if not pack_result.is_valid():
		DirAccess.remove_absolute(temp_path)
		return result.merge(pack_result)

	return result.merge(_swap_into_place(temp_path, path))


## Serializes one document into an already-open archive.
static func pack_document(
	writer: ZIPPacker, document: InspectableDocument, path: String
) -> void:
	var data: String = JSON.stringify(document._to_dict(), "\t")
	writer.start_file(path)
	writer.write_file(data.to_utf8_buffer())
	writer.close_file()


static func _pack_documents(project: MonologueProject, temp_path: String) -> ValidationResult:
	var result: ValidationResult = ValidationResult.ok()
	DirAccess.remove_absolute(temp_path)

	var writer: ZIPPacker = ZIPPacker.new()
	writer.compression_level = 0
	var error: Error = writer.open(temp_path, ZIPPacker.APPEND_CREATE)
	if error != OK:
		return result.add_error(
			"Could not open '%s' for writing (error %d)." % [temp_path, error], &"write_failed"
		)

	pack_document(writer, project.manifest, "manifest.json")
	pack_document(writer, project.settings, "settings.json")
	for collection: CollectionDocument in project.collections:
		pack_document(writer, collection, "collections/%s.json" % collection.name)
	for storyline: StorylineDocument in project.storylines:
		pack_document(writer, storyline, "storylines/%s.json" % storyline.name)

	writer.close()
	return result


## Moves the freshly written archive over the old one, keeping the old one aside until
## the move has succeeded so a failure can be rolled back.
static func _swap_into_place(temp_path: String, path: String) -> ValidationResult:
	var result: ValidationResult = ValidationResult.ok()

	if not FileAccess.file_exists(path):
		if DirAccess.rename_absolute(temp_path, path) != OK:
			DirAccess.remove_absolute(temp_path)
			return result.add_error("Could not write '%s'." % path, &"write_failed")
		return result

	var backup_path: String = path + BACKUP_SUFFIX
	DirAccess.remove_absolute(backup_path)
	if DirAccess.rename_absolute(path, backup_path) != OK:
		DirAccess.remove_absolute(temp_path)
		return result.add_error("Could not replace '%s'." % path, &"write_failed")

	if DirAccess.rename_absolute(temp_path, path) != OK:
		DirAccess.rename_absolute(backup_path, path)
		DirAccess.remove_absolute(temp_path)
		return result.add_error("Could not write '%s'; kept the previous version." % path,
			&"write_failed")

	DirAccess.remove_absolute(backup_path)
	return result
