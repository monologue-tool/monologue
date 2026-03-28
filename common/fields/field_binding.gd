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
	field.value_committed.connect(_on_field_value_committed)
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
		if field.value_committed.is_connected(_on_field_value_committed):
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
	if not field.is_inside_tree():
		return
	# Guard: don't clobber a field that is broadcasting its own snapshot
	# the field data is already the source of truth during that call.
	if field.is_emitting_snapshot:
		return
	_is_syncing = true
	var _sync_value: Variant = property.get_value()
	if _sync_value == null and descriptor != null and descriptor.default_value != null:
		var _dv: Variant = descriptor.default_value
		_sync_value = _dv.duplicate(true) if _dv is Dictionary or _dv is Array else _dv
	field.set_value(_sync_value)
	field.clear_error()
	_is_syncing = false


func _update_editable_state() -> void:
	if not is_instance_valid(field) or not property:
		return
	var is_editable: bool = (
		property.get_settings_value(PropertySettings.KEY_EDITABLE, true)
		and not property.get_settings_value(PropertySettings.KEY_READ_ONLY, false)
		and not property.is_input_connected()
	)
	field.set_editable(is_editable)


func _on_field_value_changed(value: Variant) -> void:
	if _is_syncing or _is_released:
		return
	if not is_instance_valid(field) or not field.is_inside_tree():
		return
	_process_field_value(value, false)


func _on_field_value_committed(value: Variant) -> void:
	if _is_syncing or _is_released:
		return
	if not is_instance_valid(field) or not field.is_inside_tree():
		return
	_process_field_value(value, true)


func _refresh_owner_preview_from_change() -> void:
	if _is_syncing or _is_released:
		return
	if not owner or not is_instance_valid(owner):
		return
	owner.rebuild_preview()


func _process_field_value(value: Variant, is_commit: bool) -> void:
	if not property or descriptor == null:
		return
	var validation_result: FieldValidationResult = descriptor.validate(value)
	if not validation_result.is_valid:
		field.display_error(validation_result.message)
		return
	# Per-property settings: required + validation dict (min_length, max_length, …)
	var settings_result: FieldValidationResult = _validate_property_settings(value)
	if not settings_result.is_valid:
		field.display_error(settings_result.message)
		return
	field.clear_error()
	var formatted_value: Variant = descriptor.format(value)
	if owner and not is_commit:
		return
	# Unique constraint check — only makes sense when the owner is a ListItem
	# embedded inside a ListField. We use the stored siblings array (not the
	# ListField node itself, which may have been freed if the inspector switched).
	if is_commit and property.get_settings_value(PropertySettings.KEY_UNIQUE, false):
		if owner is ListItem and owner.has_meta("list_siblings"):
			var siblings: Array = owner.get_meta("list_siblings")
			for sibling: ListItem in siblings:
				if not is_instance_valid(sibling):
					continue
				if sibling.get_instance_id() == owner.get_instance_id():
					continue
				var sibling_prop: Property = sibling.get_property(property.name)
				if sibling_prop and sibling_prop.get_value() == formatted_value:
					if is_instance_valid(field):
						field.display_error("Value already exists.")
					return
	_is_syncing = true
	if owner:
		owner.set_property_value(property.name, formatted_value)
		# When a ListItem is inspected directly, its parent ListField may already be
		# freed. In that case the normal _on_item_changed → _emit_snapshot() path is
		# gone, so we push the snapshot to the parent property ourselves.
		if owner is ListItem and owner.has_meta("_list_field_ref"):
			var lf_ref: WeakRef = owner.get_meta("_list_field_ref")
			if lf_ref.get_ref() == null:  # ListField has been freed
				var parent_owner: InspectableObject = owner.get_meta("_parent_owner", null)
				var parent_prop_name: String = owner.get_meta("_parent_prop_name", "")
				if is_instance_valid(parent_owner) and not parent_prop_name.is_empty():
					var siblings: Array = owner.get_meta("list_siblings", [])
					var snapshot: Array = []
					for s: ListItem in siblings:
						if is_instance_valid(s):
							snapshot.append(s._to_dict())
					parent_owner.set_property_value(parent_prop_name, snapshot)
	else:
		property.set_value(formatted_value)
	_is_syncing = false
	_sync_from_property()
	if is_commit:
		field.after_commit(property.get_value())


func _on_property_value_changed(_old_value: Variant, _new_value: Variant) -> void:
	if _is_released or _is_syncing:
		return
	if not is_instance_valid(field) or not field.is_node_ready():
		return
	_is_syncing = true
	var _sync_value: Variant = property.get_value()
	if _sync_value == null and descriptor != null and descriptor.default_value != null:
		var _dv: Variant = descriptor.default_value
		_sync_value = _dv.duplicate(true) if _dv is Dictionary or _dv is Array else _dv
	field.set_value(_sync_value)
	field.clear_error()
	_is_syncing = false


func _on_field_tree_exiting() -> void:
	release()


func _validate_property_settings(value: Variant) -> FieldValidationResult:
	# Required check
	if property.get_settings_value(PropertySettings.KEY_REQUIRED, false):
		var str_val: String = str(value).strip_edges() if value != null else ""
		if str_val.is_empty():
			return FieldValidationResult.failure("This field is required.")

	# Validation dict: min_length, max_length, min, max
	var rules: Dictionary = property.get_settings_value(PropertySettings.KEY_VALIDATION, {})
	if rules.is_empty():
		return FieldValidationResult.success()

	var str_value: String = str(value) if value != null else ""

	if rules.has("min_length"):
		var min_len: int = str(rules["min_length"]).to_int()
		if str_value.length() < min_len:
			return FieldValidationResult.failure(
				"Must be at least %d character(s)." % min_len
			)

	if rules.has("max_length"):
		var max_len: int = str(rules["max_length"]).to_int()
		if str_value.length() > max_len:
			return FieldValidationResult.failure(
				"Must be at most %d character(s)." % max_len
			)

	if rules.has("min") and value != null:
		if float(str(value)) < float(str(rules["min"])):
			return FieldValidationResult.failure("Must be at least %s." % str(rules["min"]))

	if rules.has("max") and value != null:
		if float(str(value)) > float(str(rules["max"])):
			return FieldValidationResult.failure("Must be at most %s." % str(rules["max"]))

	return FieldValidationResult.success()
