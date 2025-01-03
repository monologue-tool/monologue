extends HBoxContainer


@onready var option_button := $OptionButton

@onready var file_picker := $"../ImagePickerLineEdit"
@onready var timeline_section := %TimelineSection

var value: String : set = _set_value, get = _get_value


func _set_value(val: String) -> void:
	value = val
	for idx in option_button.item_count:
		if option_button.get_item_text(idx) == val:
			option_button.select(idx)
	_update()

func _get_value() -> String:
	return option_button.get_item_text(option_button.selected)


func _ready() -> void:
	_update()


func _update() -> void:
	var item_idx: int = option_button.selected
	var item_name: String = option_button.get_item_text(item_idx)
	
	match item_name:
		"Image":
			timeline_section.hide()
			file_picker.show()
			file_picker._update()
		"Animation":
			timeline_section.show()
			file_picker.hide()
			timeline_section._update_preview()


func _on_option_button_item_selected(_index: int) -> void:
	_update()
