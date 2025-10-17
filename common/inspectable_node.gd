@abstract
class_name InspectableNode extends InspectableObject


func _init() -> void:
	super._init()
	define_property("position", Vector2.ZERO, "vector2", {})
	define_property("notes", "", "string", {}, "Extra")


@abstract func get_type() -> String

@abstract func get_title() -> String
@abstract func get_color() -> Color
@abstract func get_icon() -> Texture2D

@abstract func get_rows() -> Array[GraphNodeRow]
