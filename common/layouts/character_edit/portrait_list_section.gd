class_name PortraitListSection extends CharacterEditSection


signal portrait_selected

const DEFAULT_PORTRAIT_NAME = "new portrait %s"

var portraits := Property.new(MonologueGraphNode.LIST, {}, [])
var default_portrait := Property.new(MonologueGraphNode.LINE, {}, "")

var selected: int = -1
var references: Array[AbstractPortraitOption] = []

@onready var portrait_settings_section := %PortraitSettingsSection
@onready var timeline_section := %TimelineSection
@onready var preview_section := %PreviewSection


func _ready() -> void:
	portraits.setters["add_callback"] = add_portrait
	portraits.setters["get_callback"] = get_portraits
	portraits.setters["flat"] = true
	portraits.connect("preview", load_portraits)
	default_portrait.visible = false
	super._ready()


func add_portrait(option_dict: Dictionary = {}) -> AbstractPortraitOption:
	var new_portrait := AbstractPortraitOption.new(self)
	if option_dict:
		new_portrait._from_dict(option_dict)
	else:
		new_portrait.portrait_name.value = DEFAULT_PORTRAIT_NAME % (references.size() + 1)
	new_portrait.portrait.callers["set_option_name"] = [new_portrait.portrait_name.value]
	new_portrait.idx.value = references.size()
	new_portrait.portrait.connecters[_on_portrait_option_pressed] = "pressed"
	new_portrait.portrait.connecters[_on_portrait_option_set_to_default] = "set_to_default"
	references.append(new_portrait)
	
	if new_portrait.idx.value == selected:
		new_portrait.portrait.callers["set_active"] = []
	else:
		new_portrait.portrait.callers["release_active"] = []
	return new_portrait


func get_portraits() -> Array:
	return references


func get_portrait_options() -> Array:
	return get_portraits().map(func(i: AbstractPortraitOption): return i.portrait.field)


## Perform loading of speakers and set indexes correctly.
func load_portraits(new_portrait_list: Array) -> void:
	references.clear()
	var ascending = func(a, b): return a.get("EditorIndex") < b.get("EditorIndex")
	new_portrait_list.sort_custom(ascending)
	
	for portrait_data in new_portrait_list:
		var abstract_option = add_portrait(portrait_data)
		if new_portrait_list.size() <= 1:
			default_portrait.value = abstract_option.id.value
		if default_portrait.value == abstract_option.id.value:
			abstract_option.portrait.callers["set_default"] = []
	
	portraits.value = new_portrait_list


func _from_dict(dict: Dictionary) -> void:
	super._from_dict(dict)
	_update_portrait()


func _on_portrait_option_pressed(portrait_option: PortraitOption) -> void:
	var all_options: Array = get_portrait_options()
	selected = all_options.find(portrait_option)
	
	for option: PortraitOption in all_options:
		if option == portrait_option:
			option.set_active()
			for section in linked_sections:
				section.portrait_index = selected
		else:
			option.release_active()
	
	portrait_selected.emit()
	_update_portrait()


func _on_portrait_option_set_to_default(portrait_option: PortraitOption) -> void:
	var all_options: Array = get_portrait_options()
	for option: PortraitOption in all_options:
		if option == portrait_option:
			var index = all_options.find(option)
			default_portrait.value = references[index].id.value
		else:
			option.release_default()


func _update_portrait() -> void:
	var show_portrait_sections: bool = selected >= 0
	portrait_settings_section.visible = show_portrait_sections
	preview_section.visible = show_portrait_sections
	if not show_portrait_sections:
		timeline_section.hide()
