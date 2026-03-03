extends PanelContainer

@export var section_icon: Texture2D

var _property: Property
var _list_field: ListField
var _property_owner: InspectableObject

@onready var vbox := %VBox
@onready var search_bar: LineEdit = %SearchLine
@onready var add_button: Button = $VBox/ToolBar/AddButton


func _ready() -> void:
	search_bar.placeholder_text = "Filter %s" % name.to_lower()
	if add_button:
		add_button.pressed.connect(_on_add_button_pressed)


func clear() -> void:
	for child in vbox.get_children():
		child.queue_free()


func load_items(property: Property, property_owner: InspectableObject = null) -> void:
	clear()
	_property = property
	_property_owner = property_owner

	if not _property:
		return

	_list_field = FieldBucket.safe_create_field(_property.type)
	if _list_field is ListField:
		_property.bind_field(_list_field, _property_owner)
	vbox.add_child(_list_field)


func _on_add_button_pressed() -> void:
	if not (_property and _property_owner and _list_field):
		return

	var collection_name = _list_field._collection_name
	if collection_name == "":
		return

	var item_object: ListItem = CollectionBucket.create_item(collection_name, _list_field._command_manager)
	if not item_object:
		return
		
	# make sure name is valid
	var name_prop = item_object.get_property("name")
	if name_prop:
		var base_name = name_prop.value
		var attempt = 1
		# A quick uniqueness check for new items if list is not empty
		while _value_exists_in_list("name", name_prop.value):
			name_prop.value = "%s %d" % [base_name, attempt]
			attempt += 1

	var new_item_list: Array = _property.get_value().duplicate(true)
	new_item_list.append(item_object._to_dict())
	_property_owner.set_property_value(_property.name, new_item_list)


func _value_exists_in_list(pname: String, pvalue: Variant) -> bool:
	for item in _list_field._list_items:
		var prop = item.get_property(pname)
		if prop and prop.value == pvalue:
			return true
	return false


func _on_search_line_text_changed(new_text: String) -> void:
	_list_field.show_all_items()
	if new_text.is_empty():
		return

	var search_keys: Array[String] = ["name", "display_name", "nicknames", "description"]
	var item_list: Array = _list_field._list_items

	for item: ListItem in item_list:
		var hide_item: bool = true
		var item_idx: int = item_list.find(item)
		for prop: Property in item.get_properties():
			if not prop.name in search_keys:
				continue

			var value: Variant = prop.get_value()
			if value is not String:
				continue

			if new_text.to_lower() in value.to_lower():
				hide_item = false
		if hide_item:
			_list_field.hide_item(item_idx)
