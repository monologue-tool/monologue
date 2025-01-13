class_name PortraitListSection extends CharacterEditSection


signal portrait_selected

@onready var character_edit := $"../../../../../.."
@onready var portrait_vbox := %PortraitVBox
@onready var portrait_settings_section := %PortraitSettingsSection
@onready var timeline_section := %TimelineSection

@onready var field_vbox := $FieldVBox

var portraits := Property.new(MonologueGraphNode.LIST, {}, [])

var selected: int = -1
var _portrait_references: Array = []


func _ready() -> void:
	portraits.setters["add_callback"] = add_portrait
	portraits.setters["get_callback"] = get_portraits
	portraits.setters["flat"] = true
	portraits.connect("preview", load_portraits)


## Trickle down the setting of portrait_index.
func trickle() -> void:
	var child_sections = [portrait_settings_section, timeline_section]
	for section in child_sections:
		section.portrait_index = selected


#func _on_add_button_pressed() -> void:
	#var new_portrait = add_option()
	#portraits[new_portrait.id] = {
		#"Name": new_portrait.line_edit.text
	#}


func add_portrait(option_dict: Dictionary = {}) -> AbstractPortraitOption:
	var new_portrait := AbstractPortraitOption.new(self)
	var portrait_id: String = IDGen.generate(5)
	#new_portrait.connect("pressed", _on_portrait_option_pressed.bind(new_portrait))
	#new_portrait.connect("set_to_default", _on_portrait_option_set_to_default.bind(new_portrait))
	#new_portrait.line_edit.text = option_name if option_name != "" else "new portrait %s" % (portraits.value.size() + 1)
	new_portrait.id.setters["value"] = portrait_id
	
	#if portrait_vbox.get_child_count() <= 1:
		#new_portrait.set_default()
	
	_portrait_references.append(new_portrait)
	return new_portrait


func _to_dict_portrait(_portrait_id: String) -> Dictionary:
	return {}


func get_portraits() -> Array:
	return _portrait_references


## Perform initial loading of speakers and set indexes correctly.
func load_portraits(new_portrait_list: Array) -> void:
	_portrait_references.clear()
	var ascending = func(a, b): return a.get("EditorIndex") < b.get("EditorIndex")
	new_portrait_list.sort_custom(ascending)
	for portrait_data in new_portrait_list:
		add_portrait(portrait_data)
	
	portraits.value = new_portrait_list


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
			trickle()
			portrait_settings_section._from_dict(portraits.value)
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
	return portraits.value


func _from_dict(dict: Dictionary) -> void:
	#selected = -1
	#clear()
	#var data: Dictionary = dict.get("Portraits", {})
	#portraits.value = data
	#
	#for portrait_id in data.keys():
		#var portrait_data = data[portrait_id]
		#var portrait_node := add_option(portrait_data["Name"])
		#portrait_node.id = portrait_id
		#if portrait_id == dict.get("DefaultPortrait"):
			#portrait_node.set_default()
	super._from_dict(dict)
