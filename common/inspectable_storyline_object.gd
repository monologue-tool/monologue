@abstract
class_name InspectableStorylineObject extends InspectableObject


func _init() -> void:
	define_property("position", Vector2.ZERO, "vector2", {})
	super._init()


@abstract func build_graph_preview() -> Array[Control]
