# Autoload
extends Node

const DEFAULT_FIELDS_LOCATION: String = "res://common/ui/editor_properties/"

var _bucket: Dictionary = {}


func _ready() -> void:
	_search_fields()


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


func _get_field_data(field_name: String) -> Dictionary:
	return _bucket.get(field_name, {})


func get_scene(field_name: String) -> PackedScene:
	var indexer: RefCounted = _get_field_data(field_name).get("indexer")
	if indexer:
		return indexer.call("get_scene")
	return null


func get_metadata(field_name: String) -> Dictionary:
	var indexer: RefCounted = _get_field_data(field_name).get("indexer")
	if indexer:
		return indexer.call("get_metadata")
	return {}


func get_type_id(field_name: String) -> int:
	return _get_field_data(field_name).get("type", -1)
