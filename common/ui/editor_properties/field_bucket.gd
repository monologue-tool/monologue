# Autoload
extends Node

const DEFAULT_FIELDS_LOCATION := "res://common/ui/editor_properties/"

var _descriptors: Dictionary = {}
var _is_initialized: bool = false
var _next_type_id: int = 1


func register_descriptor(descriptor: FieldDescriptor) -> void:
	if descriptor == null:
		push_warning("Attempted to register a null FieldDescriptor.")
		return
	if descriptor.name.is_empty():
		push_warning("FieldDescriptor missing name property.")
		return
	if _descriptors.has(descriptor.name):
		push_warning("FieldDescriptor '%s' already registered." % descriptor.name)
		return
	if descriptor.default_settings == null:
		descriptor.default_settings = {}
	descriptor.type_id = _next_type_id
	_next_type_id += 1
	_descriptors[descriptor.name] = descriptor


func bind(
	property: Property, field: Field, property_owner: InspectableObject = null
) -> FieldBinding:
	if not property or not is_instance_valid(field):
		return null
	var descriptor := get_descriptor(property.type)
	if descriptor == null:
		push_warning("No field descriptor found for type '%s'." % property.type)
		return null
	var binding: FieldBinding = FieldBinding.new(property, field, descriptor, property_owner)
	binding.initialize()
	return binding


func create_field(field_name: String) -> Field:
	var descriptor := get_descriptor(field_name)
	if descriptor:
		return descriptor.instantiate_field()
	return null


func get_scene(field_name: String) -> PackedScene:
	var descriptor := get_descriptor(field_name)
	if descriptor:
		return descriptor.scene
	return null


func get_metadata(field_name: String) -> Dictionary:
	var descriptor := get_descriptor(field_name)
	if descriptor:
		return descriptor.to_metadata()
	return {}


func get_type_id(field_name: String) -> int:
	var descriptor := get_descriptor(field_name)
	return descriptor.type_id if descriptor else -1


func get_descriptor(field_name: String) -> FieldDescriptor:
	_ensure_initialized()
	return _descriptors.get(field_name)


func refresh_registry() -> void:
	_is_initialized = false
	_descriptors.clear()
	_next_type_id = 1
	_ensure_initialized()


func _ensure_initialized() -> void:
	if _is_initialized:
		return
	_search_fields()
	_is_initialized = true


func _search_fields() -> void:
	var directories: Array = DirAccess.get_directories_at(DEFAULT_FIELDS_LOCATION)
	for dir: String in directories:
		var script_path: String = DEFAULT_FIELDS_LOCATION.path_join(dir).path_join("index.gd")
		if not FileAccess.file_exists(script_path):
			continue
		var script = load(script_path)
		if script == null:
			push_warning("Failed to load field indexer at %s" % script_path)
			continue
		var indexer = script.new()
		var descriptor := _descriptor_from_indexer(indexer)
		if descriptor:
			descriptor.default_settings = (
				descriptor.default_settings.duplicate(true) if descriptor.default_settings else {}
			)
			register_descriptor(descriptor)


func _descriptor_from_indexer(indexer) -> FieldDescriptor:
	var descriptor
	if indexer and indexer.has_method("get_descriptor"):
		descriptor = indexer.call("get_descriptor")
		if descriptor is FieldDescriptor:
			return descriptor
	var metadata: Dictionary = {}
	if indexer and indexer.has_method("get_metadata"):
		metadata = indexer.call("get_metadata")
	var descriptor_name: String = metadata.get("name", "")
	var scene: PackedScene
	if indexer and indexer.has_method("get_scene"):
		scene = indexer.call("get_scene")
	if descriptor_name.is_empty():
		return null
	return FieldDescriptor.new(descriptor_name, scene, metadata)
