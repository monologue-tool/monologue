extends CharacterEditSection


@onready var main_section := %MainSettingsSection
@onready var portrait_list_section := %PortraitListSection
@onready var portrait_settings_section := %PortraitSettingsSection
@onready var preview_section := %PreviewSection
@onready var timeline_section := %TimelineSection
@onready var field_vbox := %FieldVBox

var nicknames := Property.new(MonologueGraphNode.LINE)
var display_name := Property.new(MonologueGraphNode.LINE)
var description := Property.new(MonologueGraphNode.TEXT)

var current_character_field: MonologueCharacterField
var base_path: String
var graph_edit: MonologueGraphEdit :
	get: return current_character_field.graph_edit


func _ready() -> void:
	hide()
	GlobalSignal.add_listener("open_character_edit", _on_open_character_edit)
	
	portrait_list_section.connect("portrait_selected", _update_portrait)
	_update_portrait()


func propagate() -> void:
	pass


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
	current_character_field.character_edit_dict = _to_dict()
	
	hide()
	current_character_field = null


func _from_dict(dict: Dictionary = {}) -> void:
	super._from_dict(dict)
	_update_portrait()
	
