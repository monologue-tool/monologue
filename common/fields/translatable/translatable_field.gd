extends Field

var _values: Dictionary = {}

@onready var line_edit: LineEdit = %LineEdit
@onready var localization_option: OptionButton = %LocalizationOption


func _ready() -> void:
	super._ready()
	line_edit.text_changed.connect(_on_text_changed)
	line_edit.text_submitted.connect(_on_text_submitted)
	line_edit.focus_exited.connect(_on_focus_exited)


func _on_initialize() -> void:
	line_edit.placeholder_text = settings.get("placeholder", "")


func set_value(value: Variant) -> void:
	if not is_node_ready():
		await ready
	
	_values = value if value is Dictionary else {"en": value}
	line_edit.text = _values.get("en", "")


func get_value() -> Variant:
	return _values


func set_editable(is_editable: bool) -> void:
	line_edit.editable = is_editable


func display_error(message: String) -> void:
	super.display_error(message)
	if message.is_empty():
		line_edit.remove_theme_color_override("font_color")
	else:
		line_edit.add_theme_color_override("font_color", Color(0.8, 0.1, 0.1))


func _on_text_changed(new_text: String) -> void:
	_values["en"] = new_text
	emit_value_changed(_values)


func _on_text_submitted(submitted_text: String) -> void:
	_values["en"] = submitted_text
	emit_value_committed(_values)


func _on_focus_exited() -> void:
	_values["en"] = line_edit.text
	emit_value_committed(_values)
