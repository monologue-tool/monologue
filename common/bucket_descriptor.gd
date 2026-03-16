## Abstract base class for all descriptor objects
## (FieldDescriptor, GraphNodeDescriptor, CollectionDescriptor).
## Provides shared name, display_name, category, tags, and description.
@abstract
class_name BucketDescriptor extends RefCounted

var name: String = ""
var display_name: String = ""
var category: String = "General"
var tags: Array[String] = []
var description: String = ""


func _init(p_name: String = "", metadata: Dictionary = {}) -> void:
	name = p_name
	display_name = metadata.get("display_name", Util.to_readable_name(name))
	category = metadata.get("category", category)
	description = metadata.get("description", "")
	if metadata.has("tags") and metadata["tags"] is Array:
		tags = metadata["tags"].duplicate(true)


## Returns a serializable Dictionary of common descriptor metadata.
## Subclasses should call super.to_metadata() and merge their own fields.
func to_metadata() -> Dictionary:
	return {
		"name": name,
		"display_name": display_name,
		"category": category,
		"description": description,
		"tags": tags.duplicate(true),
	}
