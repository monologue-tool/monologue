extends MarginContainer


@onready var main_section := %MainSettingsSection
@onready var portrait_list_section := %PortraitListSection
@onready var portrait_settings_section := %PortraitSettingsSection
@onready var preview_section := %PreviewSection
@onready var timeline_section := %TimelineSection

@onready var nicknames_le := %NicknamesLineEdit
@onready var display_name_le := %DisplayNameLineEdit
@onready var description_te := %DescriptionTextEdit
@onready var image_picker_le := %ImagePickerLineEdit

var current_character_field: MonologueCharacterField
var base_path: String


func _ready() -> void:
	hide()
	GlobalSignal.add_listener("open_character_edit", _on_open_character_edit)
	
	portrait_list_section.connect("portrait_selected", _update_portrait)
	_update_portrait()


func _on_open_character_edit(character_field: MonologueCharacterField) -> void:
	current_character_field = character_field
	_from_dict(character_field._to_dict())
	show()


func _update_portrait() -> void:
	var selected_idx: int = portrait_list_section.selected
	
	var show_portrait_sections: bool = selected_idx >= 0
	portrait_settings_section.visible = show_portrait_sections
	preview_section.visible = show_portrait_sections
	if show_portrait_sections == false:
		timeline_section.hide()


# Done button
func _on_button_pressed() -> void:
	current_character_field.nicknames = nicknames_le.text
	current_character_field.display_name = display_name_le.text
	current_character_field.description = description_te.text
	current_character_field.default_portrait = portrait_list_section.get_default_portrait()
	current_character_field.portraits = portrait_list_section._to_dict()
	
	hide()
	current_character_field = null


func _from_dict(dict: Dictionary = {}) -> void:
	nicknames_le.text = dict.get("Nicknames", "")
	display_name_le.text = dict.get("DefaultDisplayName", "")
	description_te.text = dict.get("EditorDescription", "")
	
	portrait_list_section._from_dict(dict)
	
	base_path = current_character_field.base_path
	portrait_settings_section.base_path = base_path
	image_picker_le.base_path = base_path
	_update_portrait()
	


 #{
	#"Nicknames": "",
	#"DefaultDisplayName": "",
	#"EditorDescription": "",
	#"DefaultPortrait": "Idle",
	#"Portraits": {
		#"Idle": {
			#"PortraitType": "Image",
			#"ImagePath": "./assets/idle.png",
			#"Offset": [0, 0],
			#"Mirror": false
		#},
		#"Run": {
			#"PortraitType": "Animation",
			#"Offset": [0, 0],
			#"Mirror": false,
			#"Animation": {
				#"Fps": 25,
				#"FrameCount": 7,
				#"Layers": [
					#{
						#"LayerName": "Layer 1",
						#"Visible": true,
						#"EditorLock": false,
						#"Frames": {
							#0: {
								#"ImagePath": "./assets/run/01.png",
								#"Exposure": 1
							#},
							#1: {
								#"ImagePath": "./assets/run/02.png",
								#"Exposure": 3
							#},
							#5: {
								#"ImagePath": "./assets/run/03.png",
								#"Exposure": 1
							#}
						#}
					#}
				#]
			#}
		#}
	#}
#}
