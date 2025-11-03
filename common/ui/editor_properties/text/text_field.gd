extends Field

@onready var line_edit: LineEdit = %LineEdit


func _ready() -> void:
	line_edit.text_changed.connect(signal_changed)


func set_value(value: Variant) -> void:
	line_edit.text = str(value)


func get_value() -> Variant:
	return line_edit.text
