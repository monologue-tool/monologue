class_name MonologueWindow extends Window


func _ready() -> void:
	EventBus.window_out.connect(_on_window_out)
	
	get_parent().connect("resized", _on_resized)
	update_size.call_deferred()
	visibility_changed.connect(_on_visibility_changed)
	_on_visibility_changed()
	
	App._update_window(get_window(), false)


func update_size() -> void:
	size.x = size.x
	App._update_window(get_window(), false)


func _on_resized() -> void:
	update_size()


func _on_visibility_changed() -> void:
	if visible:
		EventBus.show_dimmer.emit()
		return
	EventBus.hide_dimmer.emit()


func _on_window_out() -> void:
	hide()
