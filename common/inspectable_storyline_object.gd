@abstract
class_name InspectableStorylineObject extends InspectableObject


func _init(command_manager: CommandManager = null) -> void:
	super._init(command_manager)


@abstract func build_graph_preview() -> Array[Control]
