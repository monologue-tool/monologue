## Where playthroughs are kept between runs.
##
## Beside the user data and not in the project, one folder per story.
class_name MonologueSessionStore

const ROOT: String = "user://monologue/sessions"
const EXTENSION: String = "json"
## What a story with no path on disk is filed under.
const UNSAVED: String = "unsaved"
const SAFE_CHARACTERS: String = (
	"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_"
)


## Newest first, as the summary each was written with.
static func list(story_path: String) -> Array[Dictionary]:
	var folder: String = folder_for(story_path)
	var found: Array[Dictionary] = []

	for file_name: String in DirAccess.get_files_at(folder):
		if file_name.get_extension().to_lower() != EXTENSION:
			continue
		var saved: Dictionary = _read_file(folder.path_join(file_name))
		if saved.is_empty():
			continue
		found.append({
			"name": str(saved.get("name", file_name.get_basename())),
			"saved_at": int(saved.get("saved_at", 0)),
			"where": str(saved.get("where", "")),
		})

	found.sort_custom(
		func(a: Dictionary, b: Dictionary) -> bool: return a["saved_at"] > b["saved_at"]
	)
	return found


## False having said why.
static func write(story_path: String, session_name: String, saved: Dictionary) -> bool:
	var wanted: String = _file_name(session_name)
	if wanted.is_empty():
		push_error("Monologue: a session needs a name to be saved under.")
		return false

	var folder: String = folder_for(story_path)
	if DirAccess.make_dir_recursive_absolute(folder) != OK:
		push_error("Monologue: could not make '%s'." % folder)
		return false

	var file: FileAccess = FileAccess.open(
		folder.path_join("%s.%s" % [wanted, EXTENSION]), FileAccess.WRITE
	)
	if file == null:
		push_error("Monologue: could not write the session '%s'." % session_name)
		return false

	file.store_string(JSON.stringify(saved, "\t"))
	file.close()
	return true


## Empty for a session that is not there or cannot be read.
static func read(story_path: String, session_name: String) -> Dictionary:
	var wanted: String = _file_name(session_name)
	if wanted.is_empty():
		return {}
	return _read_file(folder_for(story_path).path_join("%s.%s" % [wanted, EXTENSION]))


static func erase(story_path: String, session_name: String) -> bool:
	var wanted: String = _file_name(session_name)
	if wanted.is_empty():
		return false

	var path: String = folder_for(story_path).path_join("%s.%s" % [wanted, EXTENSION])
	return FileAccess.file_exists(path) and DirAccess.remove_absolute(path) == OK


## The whole path decides the folder. The name only makes it readable.
static func folder_for(story_path: String) -> String:
	if story_path.is_empty():
		return ROOT.path_join(UNSAVED)

	var readable: String = _file_name(story_path.get_file().get_basename())
	return ROOT.path_join(
		"%s-%d" % [readable if not readable.is_empty() else UNSAVED, hash(story_path)]
	)


## A name as it can be written to disk.
static func _file_name(session_name: String) -> String:
	var written: String = ""
	for character: String in session_name.strip_edges():
		written += character if SAFE_CHARACTERS.contains(character) else "_"
	return written.lstrip("_").rstrip("_")


static func _read_file(path: String) -> Dictionary:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	return parsed if parsed is Dictionary else {}
