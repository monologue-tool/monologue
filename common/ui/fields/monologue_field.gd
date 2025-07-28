## UI control which allow the user to edit a graph node [MonologueProperty].
class_name MonologueField extends Control

## Emitted when the field's value is changed but not yet committed.
@warning_ignore("unused_signal")
signal field_changed(value: Variant)

## Emitted when the field's value is updated/comitted by user input.
@warning_ignore("unused_signal")
signal field_updated(value: Variant)

var collapsible_field: CollapsibleField:
	set = set_collapsible_field
var field_label: Label


## Set the collapsible control that this MonologueField belongs to.
func set_collapsible_field(collapsible: CollapsibleField):
	collapsible_field = collapsible


## Called by node panel to set field label text, if applicable.
func set_label_text(text: String) -> void:
	if not field_label: return
	field_label.text = text


## Set the field's label visibility.
func set_label_visible(can_see: bool) -> void:
	field_label.visible = can_see


## Meant to propagate the value set in [MonologueProperty] to this Field.
## This method does not emit [signal field_updated].
func propagate(_value: Variant) -> void:
	if collapsible_field:
		collapsible_field.open()

func use_custom_field_label() -> bool:
	return false
