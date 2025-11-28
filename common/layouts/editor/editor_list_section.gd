extends PanelContainer

@export var section_icon: Texture2D

var _property: Property
var _list_field: Field
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

	# Create a list field to display the property
	_list_field = FieldBucket.create_field(_property.type)
	if _list_field:
		_property.bind_field(_list_field, _property_owner)
		vbox.add_child(_list_field)
		# Wait for the field to be ready before it can be used
		if not _list_field.is_node_ready():
			await _list_field.ready


func _on_add_button_pressed() -> void:
	if _property and _property_owner:
		var source_value: Variant = _property.get_value()
		var current_list: Array = []
		if source_value is Array:
			current_list = (source_value as Array).duplicate(true)

		# Create new item with default values from template
		var item_template = _property.settings.get("item_template", {})
		var new_item: Dictionary = {}
		for prop_name in item_template.keys():
			var prop_config = item_template[prop_name]

			if prop_config.get("editor_only", false):
				continue

			new_item[prop_name] = prop_config.get("default", "")

		current_list.append(new_item)
		_property_owner.set_property_value(_property.name, current_list)
