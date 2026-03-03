# Autoload
extends Node

const DEFAULT_COLLECTIONS_LOCATION := "res://common/collections/"

var _descriptors: Dictionary = {}
var _is_initialized: bool = false


func register_descriptor(descriptor: CollectionDescriptor) -> void:
	if descriptor == null:
		push_warning("Attempted to register a null CollectionDescriptor.")
		return
	if descriptor.name.is_empty():
		push_warning("CollectionDescriptor missing name property.")
		return
	if _descriptors.has(descriptor.name):
		push_warning("CollectionDescriptor '%s' already registered." % descriptor.name)
		return
	if descriptor.default_settings == null:
		descriptor.default_settings = {}
	_descriptors[descriptor.name] = descriptor


func get_descriptor(descriptor_name: String) -> CollectionDescriptor:
	_ensure_initialized()
	return _descriptors.get(descriptor_name)


func list_descriptors() -> Array:
	_ensure_initialized()
	var values: Array = _descriptors.values()
	values.sort_custom(_sort_descriptors)
	return values
func list_metadata() -> Array[Dictionary]:
	return list_descriptors().map(func(desc) -> Dictionary: return desc.to_metadata())


func get_categories() -> PackedStringArray:
	_ensure_initialized()
	var categories: PackedStringArray = []
	for descriptor in _descriptors.values():
		if descriptor.category in categories:
			continue
		categories.append(descriptor.category)
	categories.sort()
	return categories


func get_descriptors_by_category(category: String) -> Array:
	_ensure_initialized()
	var result: Array = []
	for descriptor in _descriptors.values():
		if descriptor.category == category:
			result.append(descriptor)
	result.sort_custom(_sort_descriptors)
	return result


func create_item(descriptor_name: String, history: CommandManager) -> ListItem:
	_ensure_initialized()
	var descriptor: CollectionDescriptor = get_descriptor(descriptor_name)
	if descriptor:
		return descriptor.instantiate_item(history)
	push_warning("No collection descriptor registered for '%s'." % descriptor_name)
	return null


func refresh_registry() -> void:
	_is_initialized = false
	_descriptors.clear()
	_ensure_initialized()


func _ensure_initialized() -> void:
	if _is_initialized:
		return
	_search_collections()
	_is_initialized = true


func _search_collections() -> void:
	var directories: Array = DirAccess.get_directories_at(DEFAULT_COLLECTIONS_LOCATION)
	for dir_path: String in directories:
		var index_path := DEFAULT_COLLECTIONS_LOCATION.path_join(dir_path).path_join("index.gd")
		if not FileAccess.file_exists(index_path):
			continue
		var index_script: Script = load(index_path)
		if index_script == null:
			push_warning("Failed to load collection indexer at %s" % index_path)
			continue
		var indexer = index_script.new()
		var descriptor = _descriptor_from_indexer(indexer)
		if descriptor:
			register_descriptor(descriptor)


func _descriptor_from_indexer(indexer):
	if not indexer:
		return
		
	if not indexer.has_method("get_metadata"):
		return
	
	var metadata: Dictionary = indexer.call("get_metadata")
	if metadata.get("type") != MonologueIndexer.ObjectType.COLLECTION:
		return
		
	var descriptor_name: String = metadata.get("name", "")
	if descriptor_name.is_empty():
		return
		
	var script_resource: Script
	if indexer.has_method("get_collection_item_script"):
		script_resource = indexer.call("get_collection_item_script")
		
	if script_resource == null:
		push_warning("Indexer for '%s' missing script reference." % descriptor_name)
		return null
	return CollectionDescriptor.new(descriptor_name, script_resource, metadata)


static func _sort_descriptors(a, b) -> bool:
	return a.display_name.naturalnocasecmp_to(b.display_name) < 0
