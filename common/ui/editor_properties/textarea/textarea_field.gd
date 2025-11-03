extends Field

@onready var text_edit: TextEdit = %TextEdit


func _ready() -> void:
	super._ready()
	text_edit.text_changed.connect(_on_text_changed)
	text_edit.focus_exited.connect(_on_focus_exited)


func set_value(value: Variant) -> void:
	text_edit.text = str(value)


func get_value() -> Variant:
	return text_edit.text


func set_editable(is_editable: bool) -> void:
	text_edit.editable = is_editable


func display_error(message: String) -> void:
	super.display_error(message)
	if message.is_empty():
		text_edit.remove_theme_color_override("font_color")
	else:
		text_edit.add_theme_color_override("font_color", Color(0.8, 0.1, 0.1))


func _on_text_changed(new_text: String) -> void:
	emit_value_changed(new_text)


func _on_focus_exited() -> void:
	emit_value_committed(text_edit.text)
