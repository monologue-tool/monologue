class_name FieldBinding extends RefCounted

var property: Property
var field: Field
var indexer: FieldIndexer
var owner: InspectableObject

var _is_syncing: bool = false
var _is_released: bool = false


func _init(
	p_property: Property, p_field: Field, p_indexer: FieldIndexer, p_owner: InspectableObject = null
) -> void:
	property = p_property
	field = p_field
	indexer = p_indexer
	owner = p_owner


func initialize() -> void:
	if _is_released:
		return
	if not is_instance_valid(field):
		push_warning("Attempted to initialize a binding with an invalid field instance.")
		return
	if indexer == null:
		push_warning("Field binding missing indexer instance.")
		return
	field.initialize(self)
	field.value_changed.connect(_on_field_value_changed)
	field.value_committed.connect(_on_field_value_committed)
	if property:
		property.value_changed.connect(_on_property_value_changed)
		# The model no longer holds widget references; a binding subscribes instead.
		property.settings_changed.connect(refresh)
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
	if property:
		if property.value_changed.is_connected(_on_property_value_changed):
			property.value_changed.disconnect(_on_property_value_changed)
		if property.settings_changed.is_connected(refresh):
			property.settings_changed.disconnect(refresh)


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
	_is_syncing = true
	# No null fallback needed: define_property already resolved the field type's
	# default into the property when it was declared.
	field.set_value(property.get_value())
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
	if _is_syncing or _is_released or value == property.get_value():
		return
	# FIXME: changing a variable's type and then its value crashes here. The binding
	# survives the DynamicField swapping its inner field, so `field` is stale.
	if not is_instance_valid(field) or not field.is_inside_tree():
		return
	_process_field_value(value, false)


func _on_field_value_committed(value: Variant) -> void:
	if _is_syncing or _is_released or value == property.get_value():
		return
	if not is_instance_valid(field) or not field.is_inside_tree():
		return
	_process_field_value(value, true)
	_refresh_owner_preview_from_change()


func _refresh_owner_preview_from_change() -> void:
	if _is_syncing or _is_released:
		return
	if not owner or not is_instance_valid(owner):
		return
	owner.rebuild_preview()


func _process_field_value(value: Variant, is_commit: bool) -> void:
	if not property or indexer == null:
		return
	var validation_result: FieldValidationResult = indexer.validate(value)
	if not validation_result.is_valid:
		if is_commit:
			_sync_from_property()
		else:
			field.display_error(validation_result.message)
		return

	var settings_result: FieldValidationResult = _validate_property_settings(value)
	if not settings_result.is_valid:
		if is_commit:
			_sync_from_property()
		else:
			field.display_error(settings_result.message)
		return
	field.clear_error()
	var formatted_value: Variant = indexer.format(value)

	if not is_commit:
		return

	# If we update through owner, it triggers an Undo/Redo command and emits property value_changed,
	# which in turn will automatically trigger _sync_from_property().
	# However, we'll manually call it below if we just set the property directly.
	if owner:
		owner.set_property_value(property.name, formatted_value)
	else:
		property.set_value(formatted_value)
		_sync_from_property()


func _on_property_value_changed(_old_value: Variant, _new_value: Variant) -> void:
	if _is_released or _is_syncing:
		return
	if not is_instance_valid(field) or not field.is_node_ready():
		return
	_is_syncing = true
	# Disabled to prevent useless ui rebuild. Re-enabled in the validation rework,
	# once commits no longer round-trip through _sync_from_property().
	# field.set_value(property.get_value())
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

	# Unique check
	if property.get_settings_value(PropertySettings.KEY_UNIQUE, false) and is_instance_valid(owner):
		var parent_obj: InspectableObject = (
			owner.get_parent_object() if owner.has_method("get_parent_object") else null
		)
		if parent_obj:
			var parent_prop: String = owner.get_parent_property_name()
			var siblings: Array = parent_obj.get_property_children(parent_prop)

			for sibling: InspectableObject in siblings:
				if sibling == owner:
					continue
				var sib_prop: Property = sibling.get_property(property.name)
				if sib_prop and sib_prop.value == value:
					return FieldValidationResult.failure("This value must be unique.")

	# Validation dict: min_length, max_length, min, max
	var rules: Variant = property.get_settings_value(PropertySettings.KEY_VALIDATION, {})
	if typeof(rules) != TYPE_DICTIONARY or rules.is_empty():
		return FieldValidationResult.success()

	var str_value: String = str(value) if value != null else ""

	if rules.has("min_length"):
		var min_len: int = int(rules["min_length"])
		if str_value.length() < min_len:
			return FieldValidationResult.failure("Must be at least %d character(s)." % min_len)

	if rules.has("max_length"):
		var max_len: int = int(rules["max_length"])
		if str_value.length() > max_len:
			return FieldValidationResult.failure("Must be at most %d character(s)." % max_len)

	if rules.has("min") and value != null:
		if str(value).is_valid_float() or value is int or value is float:
			if float(value) < float(rules["min"]):
				return FieldValidationResult.failure("Must be at least %s." % str(rules["min"]))

	if rules.has("max") and value != null:
		if str(value).is_valid_float() or value is int or value is float:
			if float(value) > float(rules["max"]):
				return FieldValidationResult.failure("Must be at most %s." % str(rules["max"]))

	return FieldValidationResult.success()
