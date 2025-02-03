## Represents a graph node property and its UI controls in Monologue.
class_name Property extends RefCounted


## Emitted when property change is to be commited to undo/redo history.
signal change(old_value: Variant, new_value: Variant)
## Emitted if the graph node of this property should be displayed in panel.
signal display
## Emitted when the field's value is being changed and is requesting a preview.
signal preview(value: Variant)
## Emitted on show() and only if the field is visible to the user.
signal shown

## Dictionary of field method names to argument list values.
var callers: Dictionary = {}
## Reference to UI instance.
var field: Control
## Reference to the field container.
var field_container: Control
## Scene used to instantiate the field's UI control.
var scene: PackedScene
## Dictionary of field property names to set values.
var setters: Dictionary
## Temporary boolean to uncollapse the field when first shown if set to true.
var uncollapse: bool
## Actual value of the property.
var value: Variant : set = set_value, get = get_value
## Toggles visibility of the field instance.
var visible: bool : set = set_visible


func _init(ui_scene: PackedScene, ui_setters: Dictionary = {},
			default: Variant = "") -> void:
	scene = ui_scene
	setters = ui_setters
	value = default
	visible = true


func get_value() -> Variant:
	return value


## Invokes a given method with the given arguments on the field if present.
func invoke(method_name: String, argument_list: Array) -> Variant:
	if is_instance_valid(field):
		return field.callv(method_name, argument_list)
	return null


## Change the property's UI scene and replace the active field instance.
func morph(new_scene: PackedScene) -> void:
	scene = new_scene
	if is_instance_valid(field):
		var panel = field.get_parent()
		var child_index = field.get_index()
		field_container.queue_free()
		show(panel, child_index)


func propagate(new_value: Variant, can_display: bool = true) -> void:
	preview.emit(new_value)
	if is_instance_valid(field):
		field.propagate(new_value)
	elif can_display:
		uncollapse = true
		display.emit()


## Trigger a property value change only when valeus are different.
func save_value(new_value: Variant) -> void:
	if not Util.is_equal(value, new_value):
		change.emit(value, new_value)


## Setter for value which does not trigger change signals.
func set_value(new_value: Variant) -> void:
	value = new_value


func set_visible(can_see: bool) -> void:
	visible = can_see
	_check_visibility()


func show(panel: Control, child_index: int = -1, auto_margin: bool = true) -> MonologueField:
	field = scene.instantiate()
	
	field_container = MarginContainer.new()
	field_container.theme_type_variation = "MarginContainer_Medium"
	field_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	field_container.add_theme_constant_override("margin_right", 0)
	field_container.add_theme_constant_override("margin_bottom", 0)
	if field is CollapsibleField or field is MonologueList or not auto_margin:
		field_container.add_theme_constant_override("margin_left", 0)
		field_container.add_theme_constant_override("margin_top", 0)
	
	for property in setters.keys():
		field.set(property, setters.get(property))
	
	field_container.add_child(field)
	
	panel.add_child(field_container)
	if child_index >= 0:
		panel.move_child(field_container, child_index)
	
	for method in callers.keys():
		field.callv(method, callers.get(method, []))
	
	field.propagate(value)
	field.connect("field_changed", preview.emit)
	field.connect("field_updated", save_value)
	_check_visibility()
	if visible:
		shown.emit()
	return field


func _check_visibility():
	if is_instance_valid(field):
		field.visible = visible
