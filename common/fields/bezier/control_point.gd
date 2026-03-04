class_name BezierControlPoint extends Button

signal moved


func _input(event: InputEvent) -> void:
	if not button_pressed or not event is InputEventMouseMotion:
		return
	
	global_position = get_global_mouse_position() - size/2
	moved.emit()
