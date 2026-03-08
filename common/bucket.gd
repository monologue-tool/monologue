## Abstract base class for all descriptor-registry autoload nodes
## (FieldBucket, NodeBucket, CollectionBucket).
## Handles registration, lazy initialization, listing, categorization, and sorting.
## Subclasses must implement _search_types() to populate _descriptors.
@abstract
class_name Bucket extends Node

var _descriptors: Dictionary = {}
var _is_initialized: bool = false


## Register a descriptor. Subclasses may override to perform extra setup
## (e.g. assigning a sequential type_id) before calling super.
func register_descriptor(descriptor: BucketDescriptor) -> void:
	if descriptor == null:
		push_warning("Attempted to register a null descriptor.")
		return
	if descriptor.name.is_empty():
		push_warning("Descriptor missing required 'name'.")
		return
	if _descriptors.has(descriptor.name):
		push_warning("Descriptor '%s' already registered." % descriptor.name)
		return
	_descriptors[descriptor.name] = descriptor


## Returns the descriptor for the given name, or null if not found.
func get_descriptor(descriptor_name: String) -> BucketDescriptor:
	_ensure_initialized()
	return _descriptors.get(descriptor_name)


## Returns all registered descriptors sorted alphabetically by display_name.
func list_descriptors() -> Array:
	_ensure_initialized()
	var values: Array = _descriptors.values()
	values.sort_custom(_sort_descriptors)
	return values


## Returns metadata dictionaries for all registered descriptors.
func list_metadata() -> Array[Dictionary]:
	return list_descriptors().map(func(d: BucketDescriptor) -> Dictionary: return d.to_metadata())


## Returns a sorted list of unique category names across all descriptors.
func get_categories() -> PackedStringArray:
	_ensure_initialized()
	var categories: PackedStringArray = []
	for descriptor: BucketDescriptor in _descriptors.values():
		if descriptor.category in categories:
			continue
		categories.append(descriptor.category)
	categories.sort()
	return categories


## Returns descriptors belonging to the given category, sorted by display_name.
func get_descriptors_by_category(category: String) -> Array:
	_ensure_initialized()
	var result: Array = []
	for descriptor: BucketDescriptor in _descriptors.values():
		if descriptor.category == category:
			result.append(descriptor)
	result.sort_custom(_sort_descriptors)
	return result


## Clears and re-discovers all descriptors.
func refresh_registry() -> void:
	_is_initialized = false
	_descriptors.clear()
	_on_refresh()
	_ensure_initialized()


## Called during refresh before re-initialization. Override for custom teardown.
func _on_refresh() -> void:
	pass


func _ensure_initialized() -> void:
	if _is_initialized:
		return
	_search_types()
	_is_initialized = true


## Implement this to discover and register all descriptors from the file system.
@abstract func _search_types() -> void


static func _sort_descriptors(a: BucketDescriptor, b: BucketDescriptor) -> bool:
	return a.display_name.naturalnocasecmp_to(b.display_name) < 0
