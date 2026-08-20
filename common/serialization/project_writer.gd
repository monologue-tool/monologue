## Writes a project to a .mnlp archive, or to a folder of documents.
##
## The archive write is atomic: everything goes into a temporary file first, and the
## real archive is only replaced once that succeeded. Two things fall out of that.
class_name ProjectWriter

const TEMP_SUFFIX: String = ".saving"
const BACKUP_SUFFIX: String = ".previous"

# Aliases, not a second definition: what a project looks like on disk is MonologueSource's.
const MANIFEST: String = MonologueSource.MANIFEST
const SETTINGS: String = MonologueSource.SETTINGS
const COLLECTIONS: String = MonologueSource.COLLECTIONS
const STORYLINES: String = MonologueSource.STORYLINES
const SECTIONS: String = MonologueSource.SECTIONS


## Writes [param project] to [param path], as an archive or as a folder depending on
## [member MonologueProject.compact]. The returned result carries an error issue when
## nothing was written. An archive on disk is untouched in that case.
static func write_project(project: MonologueProject, path: String) -> ValidationResult:
	var result: ValidationResult = ValidationResult.ok()
	if project == null:
		return result.add_error("No project to save.", &"no_project")
	if path.is_empty():
		return result.add_error("No path to save to.", &"no_path")

	if not project.compact:
		return result.merge(_write_tree(project, path))

	var temp_path: String = path + TEMP_SUFFIX
	var pack_result: ValidationResult = _pack_documents(project, temp_path)
	if not pack_result.is_valid():
		DirAccess.remove_absolute(temp_path)
		return result.merge(pack_result)

	return result.merge(_swap_into_place(temp_path, path))


## The documents a project would be written as, laid out the way an archive is, without
## writing anything. What lets the editor play a story that has never been saved.
static func documents_of(project: MonologueProject) -> Dictionary:
	var documents: Dictionary = {
		MANIFEST: project.manifest._to_dict(),
		SETTINGS: project.settings._to_dict(),
	}
	for collection: CollectionDocument in project.collections:
		documents[MonologueSource.document_path(COLLECTIONS, collection.name)] = (
			collection._to_dict()
		)
	for storyline: StorylineDocument in project.top_level_storylines():
		documents[MonologueSource.document_path(STORYLINES, storyline.name)] = written_with_sections(
			project, storyline
		)
	return documents


## A storyline with its sections, at any depth, as the one document they are written as.
static func written_with_sections(
	project: MonologueProject, storyline: StorylineDocument
) -> Dictionary:
	var data: Dictionary = storyline._to_dict()
	var nested: Array = []
	var pending: Array[String] = [storyline.id]

	while not pending.is_empty():
		for section: StorylineDocument in project.get_sections_of(pending.pop_front()):
			nested.append(section._to_dict())
			pending.append(section.id)

	data[SECTIONS] = nested
	return data


## Serializes one document into an already-open archive.
static func pack_document(
	writer: ZIPPacker, document: InspectableDocument, path: String
) -> void:
	pack_data(writer, document._to_dict(), path)


static func pack_data(writer: ZIPPacker, data: Dictionary, path: String) -> void:
	writer.start_file(path)
	writer.write_file(JSON.stringify(data, "\t").to_utf8_buffer())
	writer.close_file()


## Writes the project as a folder, one file per document, laid out the way the archive
## is so that either form reads back through the same reader.
##
## Written in place rather than swapped: with the documents in separate files there is
## no single thing to move, and no old copy to roll back to.
static func _write_tree(project: MonologueProject, path: String) -> ValidationResult:
	var result: ValidationResult = ValidationResult.ok()
	var folders: Array[String] = [
		path,
		path.path_join(COLLECTIONS),
		path.path_join(STORYLINES),
	]
	for directory: String in folders:
		if DirAccess.make_dir_recursive_absolute(directory) != OK:
			return result.add_error("Could not create '%s'." % directory, &"write_failed")

	_write_document(project.manifest, path.path_join(MANIFEST), result)
	_write_document(project.settings, path.path_join(SETTINGS), result)

	# Collected as they are written rather than walked again: what was written is exactly
	# what may stay, and one list cannot fall behind the other.
	var written_collections: PackedStringArray = []
	for collection: CollectionDocument in project.collections:
		var entry: String = MonologueSource.document_path(COLLECTIONS, collection.name)
		written_collections.append(entry.get_file())
		_write_document(collection, path.path_join(entry), result)

	var written_storylines: PackedStringArray = []
	for storyline: StorylineDocument in project.top_level_storylines():
		var entry: String = MonologueSource.document_path(STORYLINES, storyline.name)
		written_storylines.append(entry.get_file())
		_write_data(
			written_with_sections(project, storyline), path.path_join(entry), result
		)

	_remove_stale_documents(path.path_join(COLLECTIONS), written_collections)
	_remove_stale_documents(path.path_join(STORYLINES), written_storylines)
	return result


## A folder is written in place, so a renamed storyline would leave the file it used to be
## behind and the next read would find it twice.
##
## Only the project's own kind of file, and only in the folders it manages.
static func _remove_stale_documents(directory: String, written: PackedStringArray) -> void:
	for file_name: String in DirAccess.get_files_at(directory):
		if file_name.get_extension().to_lower() != MonologueSource.DOCUMENT_EXTENSION:
			continue
		if file_name not in written:
			DirAccess.remove_absolute(directory.path_join(file_name))


static func _write_document(
	document: InspectableDocument, path: String, result: ValidationResult
) -> void:
	_write_data(document._to_dict(), path, result)


static func _write_data(data: Dictionary, path: String, result: ValidationResult) -> void:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		result.add_error("Could not write '%s'." % path, &"write_failed")
		return
	file.store_string(JSON.stringify(data, "\t"))
	file.close()


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

	pack_document(writer, project.manifest, MANIFEST)
	pack_document(writer, project.settings, SETTINGS)
	for collection: CollectionDocument in project.collections:
		pack_document(
			writer, collection, MonologueSource.document_path(COLLECTIONS, collection.name)
		)
	for storyline: StorylineDocument in project.top_level_storylines():
		pack_data(
			writer,
			written_with_sections(project, storyline),
			MonologueSource.document_path(STORYLINES, storyline.name)
		)

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
