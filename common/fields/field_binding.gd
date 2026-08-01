class_name FieldBinding extends RefCounted

var property: Property
var field: Field
var indexer: FieldIndexer

## Every object this field writes to. One entry is the ordinary case; several means the
## user selected several objects and is editing them together.
##
## There is no separate multi-selection object: a selection of one is just an array of
## one, so nothing special-cases it.
var owners: Array[InspectableObject] = []

## The object the field reads its context from -- children, history, list sources.
## Those only ever make sense for a single object, so they use the first.
var owner: InspectableObject:
	get:
		return owners[0] if not owners.is_empty() else null

var _is_syncing: bool = false
var _is_released: bool = false


func _init(
	p_property: Property,
	p_field: Field,
	p_indexer: FieldIndexer,
	p_owners: Array[InspectableObject] = []
) -> void:
	property = p_property
	field = p_field
	indexer = p_indexer
	owners = p_owners.duplicate()


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
	field.clear_issues()


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
	field.clear_issues()
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


## The user is still typing: judge the candidate value without writing it, and never
## take the keystroke back.
func _on_field_value_changed(value: Variant) -> void:
	if _is_syncing or _is_released or value == property.get_value():
		return
	if not _is_field_live():
		return

	var result: ValidationResult = ValidationService.validate_value(
		ValidationContext.for_property(property, owner, value, ValidationContext.Phase.LIVE)
	)
	field.display_issues(result.issues)


## The user confirmed. The value is always written; validation only annotates it.
##
## This used to revert to the stored value when a rule failed, silently and with no
## message, so typing an empty name simply made the text reappear.
func _on_field_value_committed(value: Variant) -> void:
	if _is_syncing or _is_released or value == property.get_value():
		return
	if not _is_field_live():
		return

	var formatted: Variant = _format(value)
	if owners.is_empty():
		# Detached: no model behind the widget, its parent commits on its behalf.
		property.set_value(formatted)
		_sync_from_property()
	else:
		_write_to_owners(formatted)

	field.display_issues(
		ValidationService.validate_property(
			property, owner, ValidationContext.Phase.COMMIT, ProjectManager.current_project
		).issues
	)
	_refresh_owner_preview_from_change()


## Writes to every selected object. More than one becomes a single undo step, so
## editing a selection of twenty is one Ctrl+Z rather than twenty.
func _write_to_owners(value: Variant) -> void:
	if owners.size() == 1:
		owners[0].set_property_value(property.name, value)
		return

	var history: CommandManager = owner.history
	var transaction: CommandTransaction = null
	if history:
		transaction = history.begin(
			"Set %s on %d objects" % [property.get_display_name(), owners.size()]
		)

	for target: InspectableObject in owners:
		target.set_property_value(property.name, value)

	if transaction:
		transaction.commit()


## A DynamicField swapping its inner widget leaves bindings pointing at freed nodes.
## Releasing here is what stops the crash that the old FIXME described.
func _is_field_live() -> bool:
	if not is_instance_valid(field) or not field.is_inside_tree():
		release()
		return false
	return true


func _format(value: Variant) -> Variant:
	if indexer and indexer.formatter and indexer.formatter.is_valid():
		return indexer.formatter.call(value)
	return value


func _refresh_owner_preview_from_change() -> void:
	if _is_syncing or _is_released:
		return
	for target: InspectableObject in owners:
		if is_instance_valid(target):
			target.rebuild_preview()


## The model changed under us, typically an undo or a redo. Push it into the widget:
## commits no longer round-trip through _sync_from_property(), so this can no longer
## start the rebuild loop it was once disabled for.
func _on_property_value_changed(_old_value: Variant, _new_value: Variant) -> void:
	if _is_released or _is_syncing:
		return
	if not is_instance_valid(field) or not field.is_node_ready():
		return
	_is_syncing = true
	field.set_value(property.get_value())
	field.display_issues(property.issues)
	_is_syncing = false


func _on_field_tree_exiting() -> void:
	release()
