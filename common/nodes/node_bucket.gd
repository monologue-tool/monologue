extends Node

const DEFAULT_NODES_LOCATION := "res://common/nodes/"

var _descriptors: Dictionary = {}
var _is_initialized: bool = false


func register_descriptor(descriptor) -> void:
	if descriptor == null:
		push_warning("Attempted to register a null GraphNodeDescriptor.")
		return
	if descriptor.name.is_empty():
		push_warning("GraphNodeDescriptor missing name.")
		return
	if _descriptors.has(descriptor.name):
		push_warning("GraphNodeDescriptor '%s' already registered." % descriptor.name)
		return
	_descriptors[descriptor.name] = descriptor


func get_descriptor(descriptor_name: String):
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


func create_node(descriptor_name: String, history: CommandManager) -> InspectableNode:
	var descriptor = get_descriptor(descriptor_name)
	if descriptor:
		return descriptor.instantiate_node(history)
	push_warning("No node descriptor registered for '%s'." % descriptor_name)
	return null


func refresh_registry() -> void:
	_is_initialized = false
	_descriptors.clear()
	_ensure_initialized()


func _ensure_initialized() -> void:
	if _is_initialized:
		return
	_search_nodes()
	_is_initialized = true


func _search_nodes() -> void:
	var directories: Array = DirAccess.get_directories_at(DEFAULT_NODES_LOCATION)
	for dir_path: String in directories:
		var index_path := DEFAULT_NODES_LOCATION.path_join(dir_path).path_join("index.gd")
		if not FileAccess.file_exists(index_path):
			continue
		var index_script: Script = load(index_path)
		if index_script == null:
			push_warning("Failed to load node indexer at %s" % index_path)
			continue
		var indexer = index_script.new()
		var descriptor = _descriptor_from_indexer(indexer)
		if descriptor:
			register_descriptor(descriptor)


func _descriptor_from_indexer(indexer):
	if not indexer:
		return null
	if indexer.has_method("get_metadata"):
		var metadata: Dictionary = indexer.call("get_metadata")
		if metadata.get("type") != MonologueIndexer.ObjectType.NODE:
			return null
		var descriptor_name: String = metadata.get("name", "")
		if descriptor_name.is_empty():
			return null
		var script_resource: Script
		if indexer.has_method("get_node_script"):
			script_resource = indexer.call("get_node_script")
		elif metadata.has("script"):
			var raw_script = metadata.get("script")
			if raw_script is Script:
				script_resource = raw_script
			elif raw_script is String and not raw_script.is_empty():
				script_resource = load(raw_script)
		if script_resource == null:
			push_warning("Indexer for '%s' missing script reference." % descriptor_name)
			return null
		return GraphNodeDescriptor.new(descriptor_name, script_resource, metadata)
	return null


static func _sort_descriptors(a, b) -> bool:
	return a.display_name.naturalnocasecmp_to(b.display_name) < 0
