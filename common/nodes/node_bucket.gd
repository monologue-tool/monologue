extends Bucket

const DEFAULT_NODES_LOCATION: String = "res://common/nodes/"


func create_node(descriptor_name: String, history: CommandManager) -> InspectableNode:
	var descriptor: GraphNodeDescriptor = get_descriptor(descriptor_name) as GraphNodeDescriptor
	if descriptor:
		return descriptor.instantiate_node(history)
	push_warning("No node descriptor registered for '%s'." % descriptor_name)
	return null


func _search_types() -> void:
	var directories: Array = DirAccess.get_directories_at(DEFAULT_NODES_LOCATION)
	for dir_path: String in directories:
		var index_path: String = DEFAULT_NODES_LOCATION.path_join(dir_path).path_join("index.gd")
		if not FileAccess.file_exists(index_path):
			continue
		var index_script: GDScript = load(index_path)
		if index_script == null:
			push_warning("Failed to load node indexer at %s" % index_path)
			continue
		var indexer: MonologueIndexer = index_script.new()
		var descriptor: GraphNodeDescriptor = _descriptor_from_indexer(indexer)
		if descriptor:
			register_descriptor(descriptor)


func _descriptor_from_indexer(indexer: MonologueIndexer) -> GraphNodeDescriptor:
	var metadata: Dictionary = indexer.get_metadata()
	if metadata.get("type") != MonologueIndexer.ObjectType.NODE:
		return null
	var descriptor_name: String = metadata.get("name", "")
	if descriptor_name.is_empty():
		return null
	var script_resource: Script
	if indexer.has_method("get_node_script"):
		script_resource = indexer.call("get_node_script")
	elif metadata.has("script"):
		var raw_script: GDScript = metadata.get("script")
		script_resource = raw_script
	if script_resource == null:
		push_warning("Indexer for '%s' missing script reference." % descriptor_name)
		return null
	return GraphNodeDescriptor.new(descriptor_name, script_resource, metadata)
