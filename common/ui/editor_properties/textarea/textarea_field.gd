extends Field

@onready var text_edit: TextEdit = %TextEdit


func _ready() -> void:
	text_edit.text_changed.connect(signal_changed)


func set_value(value: Variant) -> void:
	text_edit.text = str(value)


func get_value() -> Variant:
	return text_edit.text
