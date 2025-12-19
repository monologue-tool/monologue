extends Field

var _case_property: String = ""
var _cases: Dictionary = {}

@onready var field_container: HBoxContainer = %FieldContainer


func _ready() -> void:
	super._ready()


func set_value(value: Variant) -> void:
	if not is_node_ready():
		await ready


func get_value() -> Variant:
	return ""


func set_editable(is_editable: bool) -> void:
	pass


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
	for child in field_container.get_children():
		child.queue_free()

	var field_owner: InspectableObject = _binding.owner
	var case_property: Property = field_owner.get_property(_case_property)
	if case_property == null:
		return

	var actual_case: String = case_property.get_value()
	var case_data: Dictionary = _cases[actual_case]
	var case_type: String = case_data.get("type")
	var _case_default: Variant = case_data.get("default")  # TODO: Support default value
	var _case_coerce: Variant = case_data.get("coerce")  # TODO: Coerce value

	var p_field: Control
	var new_field: Field = FieldBucket.create_field(case_type)
	if new_field:
		_binding.property.call_deferred("bind_field", new_field, _binding.owner)
		p_field = new_field
	else:
		p_field = Label.new()
		p_field.theme_type_variation = "WarnLabel"
		p_field.text = "Unknown property type"
	field_container.add_child(p_field)


func _on_property_case_changed(_old_value: Variant, _new_value: Variant) -> void:
	_update_case_field()
