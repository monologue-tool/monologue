extends VBoxContainer


signal portrait_selected

@onready var character_edit := $"../../../../../.."
@onready var portrait_option_obj := preload("res://common/layouts/character_edit/portrait_option.tscn")
@onready var portrait_vbox := %PortraitVBox
@onready var portrait_settings_section := %PortraitSettingsSection

var selected: int = -1
var portraits: Dictionary = {}


func _on_add_button_pressed() -> void:
	var new_portrait = add_option()
	portraits[new_portrait.id] = {
		"Name": new_portrait.line_edit.text
	}


func add_option(option_name: String = "") -> PortraitOption:
	var new_portrait := portrait_option_obj.instantiate()
	portrait_vbox.add_child(new_portrait)
	new_portrait.connect("pressed", _on_portrait_option_pressed.bind(new_portrait))
	new_portrait.connect("set_to_default", _on_portrait_option_set_to_default.bind(new_portrait))
	new_portrait.line_edit.text = option_name if option_name != "" else "new portrait %s" % portrait_vbox.get_child_count()
	new_portrait.id = IDGen.generate(5)
	
	if portrait_vbox.get_child_count() <= 1:
		new_portrait.set_default()
	
	return new_portrait


func clear() -> void:
	for portrait in portrait_vbox.get_children():
		portrait.queue_free()


func get_default_portrait() -> String:
	for portrait in portrait_vbox.get_children():
		if portrait.is_default:
			return portrait.id
	return ""


func _on_portrait_option_pressed(portrait_option: PortraitOption) -> void:
	save_current_portrait()
	
	selected = portrait_option.get_index()
	
	for portrait in portrait_vbox.get_children():
		if portrait is not PortraitOption:
			continue
		
		if portrait == portrait_option:
			portrait.set_active()
			portrait_settings_section._from_dict(portraits.get(portrait.id, {}))
			continue
		
		portrait.release_active()
	portrait_selected.emit()


func save_current_portrait() -> void:
	if selected >= 0:
		var portrait: PortraitOption = portrait_vbox.get_child(selected)
		portraits[portrait.id] = portrait_settings_section._to_dict()
		portraits[portrait.id]["Name"] = portrait.line_edit.text


func _on_portrait_option_set_to_default(portrait_option: PortraitOption) -> void:
	for portrait in portrait_vbox.get_children():
		if portrait is not PortraitOption:
			continue
		
		if portrait == portrait_option:
			continue
		
		portrait.release_default()


func _to_dict() -> Dictionary:
	save_current_portrait()
	return portraits


func _from_dict(dict: Dictionary) -> void:
	selected = -1
	clear()
	var data: Dictionary = dict.get("Portraits", {})
	portraits = data
	
	for portrait_id in data.keys():
		var portrait_data = data[portrait_id]
		var portrait_node := add_option(portrait_data["Name"])
		portrait_node.id = portrait_id
		if portrait_id == dict.get("DefaultPortrait"):
			portrait_node.set_default()
