class_name TimelineCell extends PanelContainer


@onready var single_cell_texture := preload("res://ui/assets/icons/cell_single.svg")
@onready var empty_cell_texture := preload("res://ui/assets/icons/cell_empty.svg")
@onready var left_cell_texture := preload("res://ui/assets/icons/cell_left.svg")
@onready var right_cell_texture := preload("res://ui/assets/icons/cell_right.svg")
@onready var middle_cell_texture := preload("res://ui/assets/icons/cell_middle.svg")

@onready var texture_rect := $TextureRect


func _ready() -> void:
	texture_rect.texture = empty_cell_texture
