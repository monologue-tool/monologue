class_name CollectionDescriptor extends RefCounted

var name: String
var collection_script: Script
var display_name: String
var category: String = "General"
var tags: Array[String] = []
var description: String = ""
var default_settings: Dictionary = {}


func _init(p_name: String = "", p_script: Script = null, metadata: Dictionary = {}) -> void:
	name = p_name
	collection_script = p_script
	display_name = metadata.get("display_name", Util.to_readable_name(name))
	category = metadata.get("category", category)
	description = metadata.get("description", "")

	if metadata.has("tags") and metadata["tags"] is Array:
		tags = metadata["tags"].duplicate(true)


func instantiate_item(history: CommandManager) -> ListItem:
	if collection_script == null:
		push_warning("Descriptor '%s' missing script for instantiation." % name)
		return null
	var instance = collection_script.new(history)
	if instance is ListItem:
		return instance
	push_error("Descriptor '%s' does not create an InspectableNode." % name)
	return null


func to_metadata() -> Dictionary:
	return {
		"name": name,
		"display_name": display_name,
		"category": category,
		"description": description,
		"tags": tags.duplicate(true)
	}
