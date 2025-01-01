extends HBoxContainer


@onready var option_button := $OptionButton

@onready var file_picker := $"../FilePickerLineEdit"
@onready var timeline_section := %TimelineSection


func _ready() -> void:
	_update()


func _update() -> void:
	var item_idx: int = option_button.selected
	var item_name: String = option_button.get_item_text(item_idx)
	
	match item_name:
		"Image":
			timeline_section.hide()
			file_picker.show()
		"Animation":
			timeline_section.show()
			file_picker.hide()


func _on_option_button_item_selected(_index: int) -> void:
	_update()
