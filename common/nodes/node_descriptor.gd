class_name GraphNodeDescriptor extends BucketDescriptor

var node_script: Script
var icon: Texture2D
var color: Color = Color.WHITE


func _init(p_name: String = "", p_script: Script = null, metadata: Dictionary = {}) -> void:
	super._init(p_name, metadata)
	node_script = p_script

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
	var base: Dictionary = super.to_metadata()
	base["color"] = color
	base["icon"] = icon
	return base
