@abstract
class_name InspectableStorylineObject extends InspectableObject


func _init(command_manager: CommandManager = null) -> void:
	define_property("position", Vector2.ZERO, "vector2", {})
	super._init(command_manager)


@abstract func build_graph_preview() -> Array[Control]
