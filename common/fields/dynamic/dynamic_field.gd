class_name DynamicField extends Field

var _case_property: String = ""
var _cases: Dictionary = {}

@onready var field_container: HBoxContainer = %FieldContainer
var _field: Field


func set_value(value: Variant) -> void:
	if not is_node_ready():
		await ready

	if _field:
		_field.set_value(value)


func get_value() -> Variant:
	if _field:
		return _field.get_value()
	return null


func set_editable(is_editable: bool) -> void:
	if _field:
		_field.set_editable(is_editable)


func _on_initialize() -> void:
	super._on_initialize()

	_case_property = settings.get("case_property", "")
	_cases = settings.get("cases", {})

	_setup_property_case_listener()
	_update_case_field()


func _setup_property_case_listener() -> void:
	if not _binding or not _binding.property:
		return

	var field_owner: InspectableObject = _binding.owner
	var case_property: Property = field_owner.get_property(_case_property)
	if case_property == null:
		return

	case_property.value_changed.connect(_on_property_case_changed)


func _update_case_field() -> void:
	for child: Node in field_container.get_children():
		child.queue_free()

	var field_owner: InspectableObject = _binding.owner
	var case_property: Property = field_owner.get_property(_case_property)
	if case_property == null:
		return

	var actual_case: String = case_property.get_value()
	if not _cases.has(actual_case):
		push_warning("Unknown case '%s' for dynamic field" % actual_case)
		return
	var case_data: Dictionary = _cases[actual_case]
	var case_type: String = case_data.get("type")
	# TODO: honour case_data["default"] when the case has no stored value yet.
	# TODO: honour case_data["coerce"] to convert the value when the case changes.

	var new_field: Control = FieldWidgetFactory.create_or_placeholder(case_type)
	field_container.add_child(new_field)
	_field = null
	if new_field is Field:
		_field = new_field
		FieldWidgetFactory.bind_deferred(_binding.property, new_field, _binding.owner)


func _on_property_case_changed(_old_value: Variant, _new_value: Variant) -> void:
	_update_case_field()


func _exit_tree() -> void:
	if not _binding or not _binding.owner:
		return
	var field_owner: InspectableObject = _binding.owner
	var case_property: Property = field_owner.get_property(_case_property)
	if case_property and case_property.value_changed.is_connected(_on_property_case_changed):
		case_property.value_changed.disconnect(_on_property_case_changed)
