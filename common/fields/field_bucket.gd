# Autoload
extends Bucket

const DEFAULT_FIELDS_LOCATION: String = "res://common/fields/"

var _next_type_id: int = 1


func register_descriptor(descriptor: BucketDescriptor) -> void:
	if descriptor == null or descriptor is not FieldDescriptor:
		push_warning("Attempted to register a null FieldDescriptor.")
		return
	if not descriptor.default_settings:
		descriptor.default_settings = {}
	descriptor.type_id = _next_type_id
	_next_type_id += 1
	super.register_descriptor(descriptor)


func bind(
	property: Property, field: Field, property_owner: InspectableObject = null
) -> FieldBinding:
	if not property or not is_instance_valid(field):
		return null
	var descriptor: FieldDescriptor = get_field_descriptor(property.type)
	if descriptor == null:
		push_warning("No field descriptor found for type '%s'." % property.type)
		return null
	var binding: FieldBinding = FieldBinding.new(property, field, descriptor, property_owner)
	binding.initialize()
	return binding


func create_field(field_name: String) -> Field:
	var descriptor: FieldDescriptor = get_field_descriptor(field_name)
	if not descriptor:
		return null
	var field: Field = descriptor.instantiate_field()
	field.settings = descriptor.default_settings
	return field


func safe_create_field(field_name: String) -> Control:
	var new_field: Field = create_field(field_name)
	if new_field:
		return new_field
	var warn_label: Label = Label.new()
	warn_label.theme_type_variation = "WarnLabel"
	warn_label.text = "Unknown property type"
	return warn_label


func get_field_descriptor(field_name: String) -> FieldDescriptor:
	return get_descriptor(field_name) as FieldDescriptor


func get_scene(field_name: String) -> PackedScene:
	var descriptor: FieldDescriptor = get_field_descriptor(field_name)
	if descriptor:
		return descriptor.scene
	return null


func get_type_id(field_name: String) -> int:
	var descriptor: FieldDescriptor = get_field_descriptor(field_name)
	return descriptor.type_id if descriptor else -1


## Returns the metadata dictionary for a registered field type.
func get_metadata(field_name: String) -> Dictionary:
	var descriptor: FieldDescriptor = get_field_descriptor(field_name)
	if descriptor:
		return descriptor.to_metadata()
	return {}


func _on_refresh() -> void:
	_next_type_id = 1


func _search_types() -> void:
	var directories: Array = DirAccess.get_directories_at(DEFAULT_FIELDS_LOCATION)
	for dir: String in directories:
		var script_path: String = DEFAULT_FIELDS_LOCATION.path_join(dir).path_join("index.gd")
		if not FileAccess.file_exists(script_path):
			continue
		var script: GDScript = load(script_path)
		if script == null:
			push_warning("Failed to load field indexer at %s" % script_path)
			continue
		var indexer: MonologueIndexer = script.new()
		var descriptor: FieldDescriptor = _descriptor_from_indexer(indexer)
		if descriptor:
			descriptor.default_settings = (
				descriptor.default_settings.duplicate(true) if descriptor.default_settings else {}
			)
			register_descriptor(descriptor)


func is_compatible(type_id_a: int, type_id_b: int) -> bool:
	if type_id_a == type_id_b:
		return true
	for descriptor: FieldDescriptor in list_descriptors():
		if descriptor.type_id != type_id_a and descriptor.type_id != type_id_b:
			continue
		var other_id: int = type_id_b if descriptor.type_id == type_id_a else type_id_a
		for compat_name: String in descriptor.compatible_types:
			if get_type_id(compat_name) == other_id:
				return true
	return false


func _descriptor_from_indexer(indexer: MonologueIndexer) -> FieldDescriptor:
	var descriptor: FieldDescriptor
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
	var new_descriptor: FieldDescriptor = FieldDescriptor.new(descriptor_name, scene, metadata)
	var compat_raw: Variant = metadata.get("compatible_types", [])
	if compat_raw is Array:
		for item: Variant in compat_raw:
			if item is String:
				new_descriptor.compatible_types.append(item)
	return new_descriptor
