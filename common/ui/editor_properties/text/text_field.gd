extends Field

@onready var line_edit: LineEdit = %LineEdit


func _ready() -> void:
	super._ready()
	line_edit.text_changed.connect(_on_text_changed)
	line_edit.text_submitted.connect(_on_text_submitted)
	line_edit.focus_exited.connect(_on_focus_exited)


func set_value(value: Variant) -> void:
	line_edit.text = str(value)


func get_value() -> Variant:
	return line_edit.text


func set_editable(is_editable: bool) -> void:
	line_edit.editable = is_editable


func display_error(message: String) -> void:
	super.display_error(message)
	if message.is_empty():
		line_edit.remove_theme_color_override("font_color")
	else:
		line_edit.add_theme_color_override("font_color", Color(0.8, 0.1, 0.1))


func _on_text_changed(new_text: String) -> void:
	emit_value_changed(new_text)


func _on_text_submitted(submitted_text: String) -> void:
	emit_value_committed(submitted_text)


func _on_focus_exited() -> void:
	emit_value_committed(line_edit.text)
