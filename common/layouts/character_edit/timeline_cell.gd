class_name TimelineCell extends PanelContainer


signal button_down
signal button_up

@onready var single_cell_texture := preload("res://ui/assets/icons/cell_single.svg")
@onready var empty_cell_texture := preload("res://ui/assets/icons/cell_empty.svg")
@onready var left_cell_texture := preload("res://ui/assets/icons/cell_left.svg")
@onready var right_cell_texture := preload("res://ui/assets/icons/cell_right.svg")
@onready var middle_cell_texture := preload("res://ui/assets/icons/cell_middle.svg")

@onready var texture_rect := $TextureRect

var image_path: String


func _ready() -> void:
	texture_rect.texture = empty_cell_texture


func _on_button_button_down() -> void: button_down.emit()
func _on_button_button_up() -> void: button_up.emit()
