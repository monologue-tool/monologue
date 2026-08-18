class_name MonologueWindow extends Window


func _ready() -> void:
	EventBus.window_out.connect(_on_window_out)

	get_parent().connect("resized", _on_resized)
	visibility_changed.connect(_on_visibility_changed)
	# wrap_controls settles the size after initial_position has already placed the window, so
	# whatever it grew by has to be given back on both sides.
	size_changed.connect(_recenter)
	_on_visibility_changed()
	update_size.call_deferred()


func update_size() -> void:
	if popup_window: # FIXME I'm not sure it's right test
		App._update_window(self, false)
	size.x = size.x
	_recenter()


## Only for a window that asked to be centred. A picker placing itself at the mouse says
## ABSOLUTE, and must be left where it put itself.
func _recenter() -> void:
	if initial_position != Window.WINDOW_INITIAL_POSITION_ABSOLUTE:
		move_to_center()


func _on_resized() -> void:
	update_size()


func _on_visibility_changed() -> void:
	if visible:
		_recenter()
		EventBus.show_dimmer.emit()
		return
	EventBus.hide_dimmer.emit()


func _on_window_out() -> void:
	hide()
