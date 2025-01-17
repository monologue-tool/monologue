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
var field: MonologueField
## Scene used to instantiate the field's UI control.
var scene: PackedScene
## Dictionary of field property names to set values.
var setters: Dictionary
## Dictionary of callables to connect to field signals.
var connecters: Dictionary
## Temporary boolean to uncollapse the field when first shown if set to true.
var uncollapse: bool
## Actual value of the property.
var value: Variant
## Initial value of the property.
var default_value: Variant
## Toggles visibility of the field instance.
var visible: bool : set = set_visible
## Overwrites the displayed property label
var custom_label: Variant


func _init(ui_scene: PackedScene, ui_setters: Dictionary = {},
			default: Variant = "", ui_custom_label: Variant = null) -> void:
	scene = ui_scene
	setters = ui_setters
	value = default
	default_value = default
	custom_label = ui_custom_label
	visible = true


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
		field.queue_free()
		show(panel, child_index)


func propagate(new_value: Variant, can_display: bool = true) -> void:
	preview.emit(new_value)
	if is_instance_valid(field):
		field.propagate(new_value)
	elif can_display:
		uncollapse = true
		display.emit()


func save_value(new_value: Variant) -> void:
	if not Util.is_equal(value, new_value):
		change.emit(value, new_value)


func set_visible(can_see: bool) -> void:
	visible = can_see
	_check_visibility()


func show(panel: Control, child_index: int = -1) -> MonologueField:
	field = scene.instantiate()
	for property in setters.keys():
		field.set(property, setters.get(property))
	
	panel.add_child(field)
	if child_index >= 0:
		panel.move_child(field, child_index)
	
	for method in callers.keys():
		field.callv(method, callers.get(method, []))
	
	for callable in connecters.keys():
		var signal_name: String = connecters.get(callable, "")
		if field.has_signal(signal_name):
			field.connect(connecters.get(callable), callable)
	
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
