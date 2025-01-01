extends VBoxContainer


signal portrait_selected

@onready var character_edit := $"../../../../../.."
@onready var portrait_option_obj := preload("res://common/layouts/character_edit/portrait_option.tscn")
@onready var portrait_vbox := %PortraitVBox

var selected: int = -1


func _on_add_button_pressed() -> void:
	add_option()


func add_option(option_name: String = "") -> CharacterEditPortraitOption:
	var new_portrait := portrait_option_obj.instantiate()
	portrait_vbox.add_child(new_portrait)
	new_portrait.connect("pressed", _on_portrait_option_pressed.bind(new_portrait))
	new_portrait.connect("set_to_default", _on_portrait_option_set_to_default.bind(new_portrait))
	new_portrait.line_edit.text = option_name if option_name != "" else "new portrait %s" % portrait_vbox.get_child_count()
	
	if portrait_vbox.get_child_count() <= 1:
		new_portrait.set_default()
	
	return new_portrait


func clear() -> void:
	for portrait in portrait_vbox.get_children():
		portrait.queue_free()


func get_default_portrait() -> String:
	for portrait in portrait_vbox.get_children():
		if portrait.is_default:
			return portrait.line_edit.text
	return ""


func _on_portrait_option_pressed(portrait_option: CharacterEditPortraitOption) -> void:
	selected = portrait_option.get_index()
	
	for portrait in portrait_vbox.get_children():
		if portrait is not CharacterEditPortraitOption:
			continue
		
		if portrait == portrait_option:
			portrait.set_active()
			continue
		
		portrait.release_active()
	portrait_selected.emit()


func _on_portrait_option_set_to_default(portrait_option: CharacterEditPortraitOption) -> void:
	for portrait in portrait_vbox.get_children():
		if portrait is not CharacterEditPortraitOption:
			continue
		
		if portrait == portrait_option:
			continue
		
		portrait.release_default()


func _to_dict() -> Dictionary:
	var portraits: Dictionary = {}
	
	for portrait: CharacterEditPortraitOption in portrait_vbox.get_children():
		var portrait_name: String = portrait.line_edit.text
		portraits[portrait_name] = {}
	
	return portraits


func _from_dict(dict: Dictionary) -> void:
	clear()
	var data: Dictionary = dict.get("Portraits", {})
	
	for portrait in data.keys():
		var portrait_data: Dictionary = data[portrait]
		var portrait_node := add_option(portrait)
	
		if portrait == dict.get("DefaultPortrait"):
			portrait_node.set_default()
