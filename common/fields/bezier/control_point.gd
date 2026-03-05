class_name BezierControlPoint extends Button

signal moved

var movable: bool = true


func _input(event: InputEvent) -> void:
	if not movable or not button_pressed or not event is InputEventMouseMotion:
		return
	
	global_position = get_global_mouse_position() - size/2
	moved.emit()
