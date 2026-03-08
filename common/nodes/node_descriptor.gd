class_name GraphNodeDescriptor extends BucketDescriptor

var node_script: GDScript
var icon: Texture2D
var color: Color = Color.WHITE


func _init(p_name: String = "", p_script: Script = null, metadata: Dictionary = {}) -> void:
	super._init(p_name, metadata)
	node_script = p_script

	var raw_icon: Variant = metadata.get("icon")
	if raw_icon is Texture2D:
		icon = raw_icon

	var raw_color: Variant = metadata.get("color")
	if raw_color is Color:
		color = raw_color


func instantiate_node(history: CommandManager) -> InspectableNode:
	if node_script == null:
		push_warning("Descriptor '%s' missing script for instantiation." % name)
		return null
	var instance: InspectableNode = node_script.new(history)
	return instance


func to_metadata() -> Dictionary:
	var base: Dictionary = super.to_metadata()
	base["color"] = color
	base["icon"] = icon
	return base
