## Field bucket singleton for managing editor field types.
##
## Autoload that discovers and indexes all available field editor types
## from the editor properties directory. Provides access to field scenes
## and metadata by field name.
## Autoload
extends Node

## Default location where field editor properties are stored.
const DEFAULT_FIELDS_LOCATION: String = "res://common/ui/editor_properties/"

## Dictionary storing field data indexed by field name.
var _bucket: Dictionary = {}


## Initializes the field bucket by searching for available fields.
func _ready() -> void:
	_search_fields()


## Searches for and indexes all field editor types.
##
## Scans the DEFAULT_FIELDS_LOCATION directory for index.gd files
## and registers their metadata in the bucket.
func _search_fields() -> void:
	var directories: Array = DirAccess.get_directories_at(DEFAULT_FIELDS_LOCATION)
	for dir: String in directories:
		var dir_path: String = DEFAULT_FIELDS_LOCATION.path_join(dir)
		var files: Array = DirAccess.get_files_at(dir_path)
		for file: String in files:
			if not file == "index.gd":
				continue

			var script_path: String = dir_path.path_join(file)
			var script: MonologueIndexer = load(script_path).new()

			var fmeta: Dictionary = script.call("get_metadata")
			var fname: String = fmeta.get("name")
			var fdata: Dictionary = {"indexer": script, "type": _bucket.size()}

			_bucket.set(fname, fdata)


## Retrieves field data for a given field name.
##
## [param field_name] The name of the field type.
## [br][br]
## Returns the field data dictionary, or empty dictionary if not found.
func _get_field_data(field_name: String) -> Dictionary:
	return _bucket.get(field_name, {})


## Gets the scene for a field editor type.
##
## [param field_name] The name of the field type.
## [br][br]
## Returns the PackedScene for the field editor, or null if not found.
func get_scene(field_name: String) -> PackedScene:
	var indexer: RefCounted = _get_field_data(field_name).get("indexer")
	if indexer:
		return indexer.call("get_scene")
	return null


## Gets metadata for a field editor type.
##
## [param field_name] The name of the field type.
## [br][br]
## Returns the metadata dictionary for the field, or empty dictionary if not found.
func get_metadata(field_name: String) -> Dictionary:
	var indexer: RefCounted = _get_field_data(field_name).get("indexer")
	if indexer:
		return indexer.call("get_metadata")
	return {}


## Gets the numeric type ID for a field editor type.
##
## [param field_name] The name of the field type.
## [br][br]
## Returns the type ID, or -1 if not found.
func get_type_id(field_name: String) -> int:
	return _get_field_data(field_name).get("type", -1)
