class_name GraphNodeDescriptor extends RefCounted

var name: String
var node_script: Script
var display_name: String
var category: String = "General"
var icon: Texture2D
var color: Color = Color.WHITE
var tags: Array[String] = []
var description: String = ""


func _init(p_name: String = "", p_script: Script = null, metadata: Dictionary = {}) -> void:
	name = p_name
	node_script = p_script
	display_name = metadata.get("display_name", Util.to_readable_name(name))
	category = metadata.get("category", category)
	description = metadata.get("description", "")

	var raw_icon = metadata.get("icon")
	if raw_icon is Texture2D:
		icon = raw_icon
	elif raw_icon is String and not raw_icon.is_empty():
		var loaded_icon = load(raw_icon)
		if loaded_icon is Texture2D:
			icon = loaded_icon

	var raw_color = metadata.get("color")
	if raw_color is Color:
		color = raw_color
	elif raw_color is String and not raw_color.is_empty():
		color = Color(raw_color)

	if metadata.has("tags") and metadata["tags"] is Array:
		tags = metadata["tags"].duplicate(true)


func instantiate_node(history: CommandManager) -> InspectableNode:
	if node_script == null:
		push_warning("Descriptor '%s' missing script for instantiation." % name)
		return null
	var instance = node_script.new(history)
	if instance is InspectableNode:
		return instance
	push_error("Descriptor '%s' does not create an InspectableNode." % name)
	return null


func to_metadata() -> Dictionary:
	return {
		"name": name,
		"display_name": display_name,
		"category": category,
		"description": description,
		"color": color,
		"icon": icon,
		"tags": tags.duplicate(true)
	}
