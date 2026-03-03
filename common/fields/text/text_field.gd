class_name TextField
extends Field

var _is_multiline: bool = false

@onready var line_edit: LineEdit = %LineEdit
@onready var text_edit: TextEdit = %TextEdit


func _ready() -> void:
	super._ready()
	line_edit.text_changed.connect(_on_text_changed)
	line_edit.text_submitted.connect(_on_text_submitted)
	line_edit.focus_exited.connect(_on_focus_exited)
	text_edit.text_changed.connect(_on_textarea_changed)
	text_edit.focus_exited.connect(_on_textarea_focus_exited)


func _on_initialize() -> void:
	_is_multiline = settings.get(PropertySettings.KEY_MULTILINE, false)
	var placeholder: String = settings.get(PropertySettings.KEY_PLACEHOLDER, 
		settings.get("placeholder", ""))

	if _is_multiline:
		line_edit.hide()
		text_edit.show()
		text_edit.placeholder_text = placeholder
		var rows: int = settings.get(PropertySettings.KEY_ROWS, settings.get("rows", 3))
		_apply_textarea_height.call_deferred(text_edit, rows)
	else:
		line_edit.placeholder_text = placeholder
		text_edit.hide()


func _apply_textarea_height(te: TextEdit, rows: int) -> void:
	var sb: StyleBox = te.get_theme_stylebox("normal")
	var padding: float = (sb.content_margin_bottom + sb.content_margin_top) if sb else 8.0
	te.custom_minimum_size.y = te.get_line_height() * rows + padding


func set_value(value: Variant) -> void:
	if not is_node_ready():
		await ready
	if _is_multiline:
		text_edit.text = str(value)
	else:
		line_edit.text = str(value)


func get_value() -> Variant:
	return text_edit.text if _is_multiline else line_edit.text


func set_editable(is_editable: bool) -> void:
	line_edit.editable = is_editable
	text_edit.editable = is_editable


func display_error(message: String) -> void:
	super.display_error(message)
	if message.is_empty():
		line_edit.remove_theme_color_override("font_color")
		text_edit.remove_theme_color_override("font_color")
	else:
		var color := Color(0.8, 0.1, 0.1)
		line_edit.add_theme_color_override("font_color", color)
		text_edit.add_theme_color_override("font_color", color)


func _on_text_changed(new_text: String) -> void:
	emit_value_changed(new_text)


func _on_text_submitted(submitted_text: String) -> void:
	emit_value_committed(submitted_text)


func _on_focus_exited() -> void:
	if not is_inside_tree():
		return
	emit_value_committed(line_edit.text)


func _on_textarea_changed() -> void:
	emit_value_changed(text_edit.text)


func _on_textarea_focus_exited() -> void:
	if not is_inside_tree():
		return
	emit_value_committed(text_edit.text)
