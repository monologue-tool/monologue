class_name MonologueWindow extends Window


func _ready() -> void:
	get_parent().connect("resized", _on_resized)
	update_size.call_deferred()


func update_size() -> void:
	move_to_center()
	size.x = size.x


func _on_resized():
	update_size()
