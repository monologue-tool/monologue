@tool
extends Button
class_name ColorSwatch

@onready var color_rect: ColorRect = %ColorRect

@export var color: Color = Color("ffffff"):
	set = _set_color


func _set_color(value: Color) -> void:
	color = value
	if not color_rect:
		return
	color_rect.color = value


func _ready() -> void:
	self.color = color
