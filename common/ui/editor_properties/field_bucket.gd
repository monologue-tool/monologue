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

			var fdata: Dictionary = script.call("get_metadata")
			var fname: String = fdata.get("name")

			_bucket.set(fname, script)


func get_field_indexer(field_name: String) -> RefCounted:
	return _bucket.get(field_name)


func get_scene(field_name: String) -> PackedScene:
	var indexer: RefCounted = get_field_indexer(field_name)
	if indexer:
		return indexer.call("get_scene")
	return null


func get_metadata(field_name: String) -> Dictionary:
	var indexer: RefCounted = get_field_indexer(field_name)
	if indexer:
		return indexer.call("get_metadata")
	return {}
