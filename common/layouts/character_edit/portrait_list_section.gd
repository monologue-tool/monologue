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
@onready var scroll_container := $ScrollContainer


func _ready() -> void:
	GlobalSignal.add_listener("select_portrait_option", select_option)
	portraits.setters["add_callback"] = add_portrait
	portraits.setters["get_callback"] = get_portraits
	portraits.setters["flat"] = true
	portraits.setters["expand"] = true
	portraits.connect("preview", load_portraits)
	portraits.connect("change", _on_portraits_change)
	default_portrait.visible = false
	super._ready()


func add_portrait(option_dict: Dictionary = {}) -> AbstractPortraitOption:
	_sync_references()
	var new_portrait := AbstractPortraitOption.new(self)
	new_portrait.graph = graph_edit
	if option_dict:
		new_portrait._from_dict(option_dict)
	else:
		new_portrait.portrait_name.value = DEFAULT_PORTRAIT_NAME % (references.size() + 1)
	new_portrait.portrait.callers["set_option_name"] = [new_portrait.portrait_name.value]
	new_portrait.idx.value = references.size()
	new_portrait.portrait.connecters[_on_portrait_option_pressed] = "pressed"
	new_portrait.portrait.connecters[_on_portrait_option_set_to_default] = "set_to_default"
	new_portrait.portrait.connecters[_on_portrait_option_name_submitted] = "name_submitted"
	references.append(new_portrait)

	if new_portrait.idx.value == selected:
		new_portrait.portrait.callers["set_active"] = []
	else:
		new_portrait.portrait.callers["release_active"] = []
	return new_portrait


func get_portraits() -> Array:
	return references


func _on_portraits_change(old_value: Variant, new_value: Variant) -> void:
	if new_value.size() <= 0:
		select_option(-1)
	elif new_value.size() < old_value.size():
		select_option(0)
	elif new_value.size() > old_value.size() and false:
		select_option(references.size())
	_update_portrait()


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
	_update_portrait()


## Selects portrait option by index.
func select_option(index: int) -> void:
	if selected == index:
		return

	selected = index
	if index < 0:
		return

	var all_options := get_portrait_options()
	if index < all_options.size():
		_update_option(all_options[index])


func _from_dict(dict: Dictionary) -> void:
	super._from_dict(dict)
	# custom handling because the default_portrait property is a little special
	default_portrait.value = dict.get("DefaultPortrait", "")
	load_portraits(dict.get("Portraits", []))
	portraits.propagate(portraits.value)
	_update_portrait()


func _on_portrait_option_pressed(portrait_option: PortraitOption) -> void:
	var all_options := get_portrait_options()
	selected = all_options.find(portrait_option)
	_update_option(portrait_option)


func _on_portrait_option_set_to_default(portrait_option: PortraitOption) -> void:
	var all_options := get_portrait_options()
	for option: PortraitOption in all_options:
		if option == portrait_option:
			var index = all_options.find(option)
			default_portrait.save_value(references[index].id.value)
		else:
			option.release_default()


func _on_portrait_option_name_submitted(portrait_option: PortraitOption) -> void:
	var all_options := get_portrait_options()
	for option: PortraitOption in all_options:
		if option == portrait_option:
			var index = all_options.find(option)
			references[index].portrait_name.save_value(portrait_option.line_edit.text)
	_sync_references()


func _update_option(selected_option: PortraitOption) -> void:
	for option: PortraitOption in get_portrait_options():
		if option == selected_option:
			option.set_active()
			for section in linked_sections:
				section.portrait_index = selected
		else:
			option.release_active()
	portrait_selected.emit()
	_update_portrait()

	await get_tree().process_frame
	scroll_container.ensure_control_visible(selected_option)


func _sync_references() -> void:
	var data_list: Array = portraits.value
	for ref: AbstractPortraitOption in references:
		var ref_candidates: Array = data_list.filter(
			func(p: Dictionary): return p.get("EditorIndex", -1) == ref.idx.value
		)
		if ref_candidates.size() <= 0:
			continue

		var data: Dictionary = ref_candidates[0]
		ref._from_dict(data)


func _update_portrait() -> void:
	var show_portrait_sections: bool = selected >= 0
	portrait_settings_section.visible = show_portrait_sections
	preview_section.visible = show_portrait_sections
	timeline_section.visible = show_portrait_sections
	if show_portrait_sections:
		var character_dict = graph_edit.characters.value[character_index]["Character"]
		portrait_settings_section._from_dict(character_dict)
