# Autoload
extends Bucket

const DEFAULT_COLLECTIONS_LOCATION: String = "res://common/collections/"


func register_descriptor(descriptor: BucketDescriptor) -> void:
	if descriptor == null or descriptor is not CollectionDescriptor:
		push_warning("Attempted to register a null CollectionDescriptor.")
		return
	if not descriptor.default_settings:
		descriptor.default_settings = {}
	super.register_descriptor(descriptor)


func create_item(descriptor_name: String, history: CommandManager) -> ListItem:
	var descriptor: CollectionDescriptor = get_descriptor(descriptor_name) as CollectionDescriptor
	if descriptor:
		return descriptor.instantiate_item(history)
	push_warning("No collection descriptor registered for '%s'." % descriptor_name)
	return null


func _search_types() -> void:
	var directories: Array = DirAccess.get_directories_at(DEFAULT_COLLECTIONS_LOCATION)
	for dir_path: String in directories:
		var index_path: String = DEFAULT_COLLECTIONS_LOCATION.path_join(dir_path).path_join("index.gd")
		if not FileAccess.file_exists(index_path):
			continue
		var index_script: GDScript = load(index_path)
		if index_script == null:
			push_warning("Failed to load collection indexer at %s" % index_path)
			continue
		var indexer: MonologueIndexer = index_script.new()
		var descriptor: CollectionDescriptor = _descriptor_from_indexer(indexer)
		if descriptor:
			register_descriptor(descriptor)


func _descriptor_from_indexer(indexer: MonologueIndexer) -> CollectionDescriptor:
	var metadata: Dictionary = indexer.get_metadata()
	if metadata.get("type") != MonologueIndexer.ObjectType.COLLECTION:
		return null
	var descriptor_name: String = metadata.get("name", "")
	if descriptor_name.is_empty():
		return null
	var script_resource: Script
	if indexer.has_method("get_collection_item_script"):
		script_resource = indexer.call("get_collection_item_script")
	if script_resource == null:
		push_warning("Indexer for '%s' missing script reference." % descriptor_name)
		return null
	return CollectionDescriptor.new(descriptor_name, script_resource, metadata)
