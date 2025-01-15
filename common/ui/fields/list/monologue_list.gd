## A list field that represents a [MonologueGraphEdit] data item.
class_name MonologueList extends MonologueField


var delete_scene = preload("res://common/ui/buttons/delete_button.tscn")
var stylebox = preload("res://ui/theme_default/list_item.stylebox")

var add_callback: Callable = Constants.empty_callback
var delete_callback: Callable = func(list): return list
var get_callback: Callable = Constants.empty_callback
var data_list: Array = []


func _ready() -> void:
	collapsible_field = $CollapsibleField
	collapsible_field.add_pressed.connect(_on_add_button_pressed)
	post_ready.call_deferred()


func post_ready() -> void:
	if get_parent().get_child_count() <= 1:
		collapsible_field.open()


## Add a new option node into the list and show its fields in the vbox.
func append_list_item(item) -> void:
	var panel = create_item_container()
	var field_box = create_item_vbox(panel)
	collapsible_field.add_item(panel, true)
	for property_name in item.get_property_names():
		var field = item.get(property_name).show(field_box)
		field.set_label_text(Util.to_key_name(property_name, " "))
	var identifier = item.id.value if "id" in item else item.name.value
	create_delete_button(field_box, identifier)


func clear_list():
	collapsible_field.clear()
	data_list = []


func create_item_container() -> PanelContainer:
	var item_container = PanelContainer.new()
	item_container.add_theme_stylebox_override("panel", stylebox)
	return item_container


func create_item_vbox(panel: PanelContainer) -> VBoxContainer:
	var item_vbox = VBoxContainer.new()
	panel.add_child(item_vbox, true)
	return item_vbox


func create_delete_button(field_box: VBoxContainer, id: Variant) -> void:
	var delete_container = MarginContainer.new()
	delete_container.add_theme_constant_override("margin_top", 5)
	var delete_button = delete_scene.instantiate()
	delete_button.connect("pressed", _on_delete_button_pressed.bind(id))
	delete_container.add_child(delete_button, true)
	
	var first_hbox = _find_first_hbox(field_box)
	if first_hbox:
		first_hbox.add_child(delete_container, true)
	else:
		delete_container.queue_free()


func set_label_text(text: String) -> void:
	collapsible_field.set_title(text)


func set_label_visible(_can_see: bool) -> void:
	#list_label.visible = can_see
	pass


func propagate(data: Variant) -> void:
	super.propagate(data)
	clear_list()
	data_list = get_callback.call()
	for reference in data_list:
		append_list_item(reference)
	data_list = data_list.map(func(r): return r._to_dict())


func _find_first_hbox(control: Control) -> HBoxContainer:
	for child in control.get_children():
		if child is HBoxContainer:
			return child
		else:
			var recursive = _find_first_hbox(child)
			if recursive:
				return recursive
	return null


func _on_add_button_pressed() -> void:
	# the add_callback creates the actual instance in its source node
	var new_item = add_callback.call()
	data_list.append(new_item._to_dict())
	append_list_item(new_item)
	field_updated.emit(data_list)


func _on_delete_button_pressed(id: Variant) -> void:
	for reference in data_list:
		if reference.get("ID") == id or reference.get("Name") == id:
			data_list.erase(reference)
			break
	var modified_list = delete_callback.call(data_list)
	field_updated.emit(modified_list)
