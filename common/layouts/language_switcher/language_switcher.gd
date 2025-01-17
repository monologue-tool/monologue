class_name LanguageSwitcher extends Button


const DEFAULT_LOCALE = "English"

## Current graph edit which has the loaded languages.
@export var graph_edit: MonologueGraphEdit
## Currently selected index from the dropdown of languages.
@export var selected_index: int

var arrow_left := preload("res://ui/assets/icons/arrow_left.svg")
var arrow_down := preload("res://ui/assets/icons/arrow_down.svg")
var option_scene := preload("res://common/layouts/language_switcher/language_option.tscn")

@onready var dropdown_container: Control = $Dropdown
@onready var vbox: VBoxContainer = $Dropdown/PanelContainer/MarginContainer/VBox/Scroll/Options


func _ready() -> void:
	dropdown_container.hide()
	GlobalVariables.language_switcher = self
	GlobalSignal.add_listener("load_languages", load_languages)
	GlobalSignal.add_listener("show_languages", show_dropdown)
	tree_exiting.connect(GlobalSignal.remove_listener.bind("load_languages", load_languages))
	tree_exiting.connect(GlobalSignal.remove_listener.bind("show_languages", show_dropdown))
	load_languages()


func add_language(locale_name: String = "") -> LanguageOption:
	var new_option: LanguageOption = option_scene.instantiate()
	vbox.add_child(new_option, true)
	new_option.language_name = locale_name
	new_option.language_name_changed.connect(_on_option_rename)
	new_option.language_removed.connect(_on_option_removed)
	new_option.pressed.connect(_on_option_selected.bind(new_option))
	return new_option


func get_current_language() -> LanguageOption:
	return vbox.get_child(selected_index)


## Returns language options in Dictionary format, where key = language string name.
func get_languages() -> Dictionary:
	var option_dictionary = {}
	for option in vbox.get_children():
		if is_instance_valid(option) and not option.is_queued_for_deletion():
			option_dictionary[str(option)] = option
	return option_dictionary


func load_languages(list: PackedStringArray = [], graph: MonologueGraphEdit = null) -> void:
	graph_edit = graph
	for child in vbox.get_children():
		vbox.remove_child(child)
		child.queue_free()
	
	if graph:
		selected_index = graph.current_language_index
	selected_index = 0 if selected_index >= list.size() else selected_index
	
	if list.is_empty():
		list.append(DEFAULT_LOCALE)
	
	var already_added: PackedStringArray = []
	for i in range(list.size()):
		if not already_added.has(list[i]):
			var new_option = add_language(list[i])
			if i == 0:
				new_option.show_delete_button(false)
			already_added.append(list[i])


func show_dropdown(can_see: bool = true) -> void:
	dropdown_container.visible = can_see
	icon = arrow_down if can_see else arrow_left


func _on_option_removed(option: LanguageOption) -> void:
	var act_text = [option.language_name, graph_edit.file_path]
	graph_edit.undo_redo.create_action("Delete %s language from %s" % act_text)
	var deletion = DeleteLanguageHistory.new(graph_edit, option.language_name, option.name)
	graph_edit.undo_redo.add_prepared_history(deletion)
	graph_edit.undo_redo.commit_action()


func _on_option_rename(old: String, new: String, option: LanguageOption) -> void:
	var act_text = [option.language_name, new]
	graph_edit.undo_redo.create_action("Change %s language to %s" % [act_text])
	var change = ModifyLanguageHistory.new(graph_edit, option.name, option.language_name, new)
	graph_edit.undo_redo.add_prepared_history(change)
	graph_edit.undo_redo.commit_action()


func _on_option_selected(option: LanguageOption) -> void:
	selected_index = option.get_index()
	graph_edit.current_language_index = selected_index


func _on_pressed() -> void:
	show_dropdown(!dropdown_container.visible)


func _on_btn_add_pressed() -> void:
	graph_edit.undo_redo.create_action("Add language to %s" % graph_edit.file_path)
	graph_edit.undo_redo.add_prepared_history(AddLanguageHistory.new(graph_edit))
	graph_edit.undo_redo.commit_action()
