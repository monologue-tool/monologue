class_name BoolField extends Field

@onready var check_box: CheckBox = %CheckBox


func _ready() -> void:
	super._ready()
	check_box.pressed.connect(_on_check_box_pressed)


# Read here rather than in _ready(): binding is deferred, so the per-property label
# is not available yet when _ready() runs.
func _on_initialize() -> void:
	check_box.text = settings.get(PropertySettings.KEY_LABEL, " ")


func set_value(value: Variant) -> void:
	if value is bool:
		check_box.button_pressed = value


func get_value() -> Variant:
	return check_box.button_pressed


func set_editable(is_editable: bool) -> void:
	check_box.disabled = not is_editable


func _on_check_box_pressed() -> void:
	emit_value_committed(get_value())
