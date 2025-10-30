## A button representing a language option in the language switcher.
##
## Allows editing the language name inline and provides delete functionality.
## Emits signals when the language name changes or is removed.
class_name LanguageOption extends Button

## Emitted when the language name is changed.
signal language_name_changed(old_name: String, new_name: String, option: LanguageOption)

## Emitted when this language option is removed.
signal language_removed(option: LanguageOption)

## The name of this language option.
var language_name: String:
	set = set_language_name

## Reference to the delete button.
@onready var del_button: TextureButton = $MarginContainer/HBoxContainer/ControlsContainer/btnDelete

## Reference to the editable line edit for the language name.
@onready var line_edit: LineEdit = $MarginContainer/HBoxContainer/LineEdit


## Initializes the language option in unfocused state.
func _ready() -> void:
	line_edit_unfocus()


## Returns a string representation of the language option.
func _to_string() -> String:
	return line_edit.text


## Disables editing mode for the line edit.
##
## Makes the line edit read-only and flat-styled.
func line_edit_unfocus() -> void:
	line_edit.editable = false
	line_edit.selecting_enabled = false
	line_edit.flat = true
	line_edit.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line_edit.theme_type_variation = "LineEdit_Flat"


## Sets the language name and updates the line edit text.
##
## [param new_name] The new language name.
func set_language_name(new_name: String) -> void:
	language_name = new_name
	line_edit.text = new_name


## Shows or hides the delete button.
##
## [param can_see] Whether the delete button should be visible. Default is true.
func show_delete_button(can_see: bool = true) -> void:
	del_button.visible = can_see


## Handles edit button press by enabling line edit editing.
func _on_btn_edit_pressed() -> void:
	line_edit.editable = true
	line_edit.selecting_enabled = true
	line_edit.flat = false
	line_edit.mouse_filter = Control.MOUSE_FILTER_STOP

	line_edit.theme_type_variation = ""


## Handles delete button press by emitting signal and freeing the node.
func _on_btn_delete_pressed() -> void:
	language_removed.emit(self)
	queue_free()
	theme_type_variation = ""


## Handles line edit losing focus by submitting the text.
func _on_line_edit_focus_exited() -> void:
	_on_line_edit_text_submitted(line_edit.text)


## Handles text submission from the line edit.
##
## Emits language_name_changed signal if the name changed.
## [br][br]
## [param new_text] The submitted text.
func _on_line_edit_text_submitted(new_text: String) -> void:
	if language_name != new_text:
		language_name_changed.emit(language_name, new_text, self)
		language_name = new_text
	line_edit_unfocus()


## Selects this language option with accent styling.
func select() -> void:
	theme_type_variation = "ButtonAccent"


## Unselects this language option, removing accent styling.
func unselect() -> void:
	theme_type_variation = ""
