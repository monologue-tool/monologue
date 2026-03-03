class_name FieldBinding extends RefCounted

var property: Property
var field: Field
var descriptor: FieldDescriptor
var owner: InspectableObject

var _is_syncing: bool = false
var _is_released: bool = false


func _init(
	p_property: Property,
	p_field: Field,
	p_descriptor: FieldDescriptor,
	p_owner: InspectableObject = null
) -> void:
	property = p_property
	field = p_field
	descriptor = p_descriptor
	owner = p_owner


func initialize() -> void:
	if _is_released:
		return
	if not is_instance_valid(field):
		push_warning("Attempted to initialize a binding with an invalid field instance.")
		return
	if descriptor == null:
		push_warning("Field binding missing descriptor instance.")
		return
	field.initialize(self)
	field.value_changed.connect(_on_field_value_changed)
	if field.has_signal("value_committed"):
		field.value_committed.connect(_on_field_value_committed)
	if field.has_signal("preview_changed"):
		field.preview_changed.connect(_on_field_preview_changed)
	if property:
		property.value_changed.connect(_on_property_value_changed)
	field.tree_exiting.connect(_on_field_tree_exiting)
	_sync_from_property()
	_update_editable_state()
	field.clear_error()


func release() -> void:
	if _is_released:
		return
	_is_released = true
	if is_instance_valid(field):
		if field.value_changed.is_connected(_on_field_value_changed):
			field.value_changed.disconnect(_on_field_value_changed)
		if (
			field.has_signal("value_committed")
			and field.value_committed.is_connected(_on_field_value_committed)
		):
			field.value_committed.disconnect(_on_field_value_committed)
		if field.tree_exiting.is_connected(_on_field_tree_exiting):
			field.tree_exiting.disconnect(_on_field_tree_exiting)
	if property and property.value_changed.is_connected(_on_property_value_changed):
		property.value_changed.disconnect(_on_property_value_changed)


func refresh() -> void:
	_sync_from_property()
	_update_editable_state()


func is_active() -> bool:
	return not _is_released


func _sync_from_property() -> void:
	if not property or not is_instance_valid(field):
		return
	_is_syncing = true
	field.set_value(property.get_value())
	field.clear_error()
	_is_syncing = false


func _update_editable_state() -> void:
	if not is_instance_valid(field) or not property:
		return
	var is_editable: bool = property.get_settings_value("editable", true)
	if property.is_input_connected():
		is_editable = false
	field.set_editable(is_editable)


func _on_field_value_changed(value: Variant) -> void:
	if _is_syncing:
		return
	_process_field_value(value, false)


func _on_field_value_committed(value: Variant) -> void:
	if _is_syncing:
		return
	_process_field_value(value, true)


func _on_field_preview_changed() -> void:
	owner.rebuild_preview()


func _process_field_value(value: Variant, is_commit: bool) -> void:
	if not property or descriptor == null:
		return
	var validation_result = descriptor.validate(value)
	if not validation_result.is_valid:
		field.display_error(validation_result.message)
		return
	field.clear_error()
	var formatted_value = descriptor.format(value)
	if owner and not is_commit:
		return
	_is_syncing = true
	if owner:
		owner.set_property_value(property.name, formatted_value)
	else:
		property.set_value(formatted_value)
	_is_syncing = false
	_sync_from_property()
	if is_commit:
		field.after_commit(property.get_value())


func _on_property_value_changed(_old_value: Variant, new_value: Variant) -> void:
	if _is_released or _is_syncing or not field.is_node_ready():
		return
	_is_syncing = true
	field.set_value(new_value)
	field.clear_error()
	_is_syncing = false


func _on_field_tree_exiting() -> void:
	release()
