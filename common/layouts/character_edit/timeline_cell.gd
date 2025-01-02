class_name TimelineCell extends PanelContainer


signal button_down
signal button_up
signal button_focus_exited

@onready var single_cell_texture := preload("res://ui/assets/icons/cell_single.svg")
@onready var empty_cell_texture := preload("res://ui/assets/icons/cell_empty.svg")
@onready var left_cell_texture := preload("res://ui/assets/icons/cell_left.svg")
@onready var right_cell_texture := preload("res://ui/assets/icons/cell_right.svg")
@onready var middle_cell_texture := preload("res://ui/assets/icons/cell_middle.svg")

@onready var button := $Button
@onready var texture_rect := $TextureRect

var image_path: String : set = _set_image_path


func _set_image_path(value: String) -> void:
	image_path = value
	_update()


func _ready() -> void:
	texture_rect.texture = empty_cell_texture


func _update() -> void:
	texture_rect.texture = empty_cell_texture
	
	if not image_path.is_empty():
		texture_rect.texture = single_cell_texture


func lose_focus() -> void:
	button.button_pressed = false


func _on_button_button_down() -> void: button_down.emit()
func _on_button_button_up() -> void: button_up.emit()
func _on_button_toggled(toggled_on: bool) -> void:
	if toggled_on == false: button_focus_exited.emit()
