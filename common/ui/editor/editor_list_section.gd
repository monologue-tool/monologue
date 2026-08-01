extends PanelContainer

@export var section_icon: Texture2D

var _property: Property
var _list_field: BaseListField
var _property_owner: InspectableObject

@onready var vbox := %VBox
@onready var search_bar: LineEdit = %SearchLine
@onready var add_button: Button = $VBox/ToolBar/AddButton


func _ready() -> void:
	search_bar.placeholder_text = "Filter %s" % name.to_lower()
	if add_button:
		add_button.pressed.connect(_on_add_button_pressed)


func clear() -> void:
	for child: Node in vbox.get_children():
		child.queue_free()


func load_items(property: Property, property_owner: InspectableObject = null) -> void:
	clear()
	_property = property
	_property_owner = property_owner

	if not _property:
		return

	_list_field = FieldWidgetFactory.create_or_placeholder(_property.type)
	if _list_field is BaseListField:
		_property.bind_field(_list_field, _property_owner)
	vbox.add_child(_list_field)


func _on_add_button_pressed() -> void:
	if _list_field is BaseListField:
		_list_field.add_item()


func _on_search_line_text_changed(new_text: String) -> void:
	_list_field.show_all_items()
	if new_text.is_empty():
		return

	var search_keys: Array[String] = ["name", "display_name", "nicknames", "description"]
	var item_list: Array = _list_field.get_items()

	for item: Variant in item_list:
		var hide_item: bool = true
		var item_idx: int = item_list.find(item)
		if item is InspectableObject:
			for prop: Property in item.get_properties():
				if not prop.name in search_keys:
					continue

				var value: Variant = prop.get_value()
				if value is not String:
					continue

				if new_text.to_lower() in value.to_lower():
					hide_item = false
		elif item is Property:
			var value: Variant = (item as Property).get_value()
			if new_text.to_lower() in str(value).to_lower():
				hide_item = false
		if hide_item:
			_list_field.hide_item(item_idx)
