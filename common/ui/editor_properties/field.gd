@abstract
class_name Field extends VBoxContainer

signal field_changed


func signal_changed(..._args) -> void:
	field_changed.emit()


@abstract func set_value(value: Variant) -> void
@abstract func get_value() -> Variant
