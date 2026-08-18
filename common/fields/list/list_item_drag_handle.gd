class_name ListItemDragHandle extends Button

signal grabbed
signal released

var grabbed_position: Vector2 = Vector2.ZERO


func _ready() -> void:
	button_down.connect(_on_button_down)
	button_up.connect(_on_button_up)


func _on_button_down() -> void:
	grabbed_position = get_global_mouse_position()
	grabbed.emit()


func _on_button_up() -> void:
	released.emit()
