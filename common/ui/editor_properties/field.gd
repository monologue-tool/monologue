@abstract
class_name Field extends VBoxContainer

signal value_changed(new_value: Variant)
signal value_committed(new_value: Variant)

var _binding: FieldBinding
var _default_modulate: Color = Color(1, 1, 1, 1)

var settings: Dictionary = {}


func _ready() -> void:
	_default_modulate = modulate


func initialize(binding: FieldBinding = null) -> void:
	if not is_node_ready():
		await ready

	if binding:
		_binding = binding

	if _binding and _binding.property:
		var property: Property = _binding.property
		settings = property.settings
	_on_initialize()


func _on_initialize() -> void:
	pass


func emit_value_changed(value: Variant) -> void:
	value_changed.emit(value)


func emit_value_committed(value: Variant) -> void:
	if settings.get("unique"):
		var field_owner: InspectableObject = _binding.owner
		var property_name: String = _binding.property.name

		if field_owner is ListItemObject:
			var list_field: ListField = field_owner.list_field
			var list_field_value: Array = list_field.get_value()

			for fvalue: Dictionary in list_field_value:
				if fvalue.has(property_name) and fvalue.get(property_name) == value:
					set_value(_binding.property.value)
					return

	value_committed.emit(value)


func set_editable(_is_editable: bool) -> void:
	pass


func display_error(message: String) -> void:
	tooltip_text = message
	modulate = _default_modulate if message.is_empty() else Color(1, 0.85, 0.85, 1)


func clear_error() -> void:
	display_error("")


func after_commit(_value: Variant) -> void:
	pass


@abstract func set_value(value: Variant) -> void
@abstract func get_value() -> Variant
