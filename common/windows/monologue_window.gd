class_name MonologueWindow extends Window


func _ready() -> void:
	get_parent().connect("resized", _on_resized)
	update_size.call_deferred()
	visibility_changed.connect(_on_visibility_changed)
	_on_visibility_changed()


func update_size() -> void:
	move_to_center()
	size.x = size.x


func _on_resized():
	update_size()


func _on_visibility_changed():
	if visible:
		GlobalSignal.emit("show_dimmer", [self])
		return
	GlobalSignal.emit("hide_dimmer", [self])
