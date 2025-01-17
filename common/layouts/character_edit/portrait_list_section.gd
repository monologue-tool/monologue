class_name PortraitListSection extends CharacterEditSection


signal portrait_selected

@onready var character_edit := $"../../../../../.."
@onready var portrait_settings_section := %PortraitSettingsSection
@onready var timeline_section := %TimelineSection

@onready var field_vbox := $ScrollContainer/FieldVBox

var portraits := Property.new(MonologueGraphNode.LIST, {}, [])
var default_portrait := Property.new(MonologueGraphNode.LINE, {}, "")

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


func add_portrait(_option_dict: Dictionary = {}) -> AbstractPortraitOption:
	var new_portrait := AbstractPortraitOption.new(self)
	var portrait_id: String = IDGen.generate(5)
	var option_name: String = ""
	
	new_portrait.id.setters["value"] = portrait_id
	new_portrait.portrait.callers["set_option_name"] = [option_name if option_name != "" else "new portrait %s" % (_portrait_references.size() + 1)]
	new_portrait.portrait.connecters[_on_portrait_option_pressed] = "pressed"
	new_portrait.portrait.connecters[_on_portrait_option_set_to_default] = "set_to_default"
	
	
	_portrait_references.append(new_portrait)
	
	if _portrait_references.size() <= 1 or default_portrait.value == portrait_id:
		new_portrait.portrait.callers["set_default"] = []
		default_portrait.value = portrait_id
	
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


func get_portrait_options() -> Array:
	return get_portraits().map(func(i: AbstractPortraitOption): return i.portrait.field)


func _on_portrait_option_pressed(portrait_option: PortraitOption) -> void:
	var all_options: Array = get_portrait_options()
	selected = all_options.find(portrait_option)
	
	for portrait: PortraitOption in all_options:
		if portrait == portrait_option:
			portrait.set_active()
			trickle()
			#portrait_settings_section._from_dict(portraits.value)
			continue
		
		portrait.release_active()
	portrait_selected.emit()


func _on_portrait_option_set_to_default(portrait_option: PortraitOption) -> void:
	var all_options: Array = get_portrait_options()
	
	for portrait in all_options:
		if portrait == portrait_option:
			default_portrait.value = portrait.id
			continue
		
		portrait.release_default()
	pass


func _get_all_fields() -> Array:
	return ["portraits"]


func _from_dict(dict: Dictionary) -> void:
	load_portraits(dict.get("Portraits", []))
	super._from_dict(dict)
