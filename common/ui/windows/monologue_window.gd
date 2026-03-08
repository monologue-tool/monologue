class_name MonologueWindow extends Window


func _ready() -> void:
	get_parent().connect("resized", _on_resized)
	update_size.call_deferred()
	visibility_changed.connect(_on_visibility_changed)
	_on_visibility_changed()


func update_size() -> void:
	move_to_center()
	size.x = size.x


func _on_resized() -> void:
	update_size()


func _on_visibility_changed() -> void:
	if visible:
		EventBus.show_dimmer.emit()
		return
	EventBus.hide_dimmer.emit()
