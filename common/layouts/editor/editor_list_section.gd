extends PanelContainer

@export var section_icon: Texture2D

@onready var vbox := %VBox
@onready var search_bar: LineEdit = %SearchLine
@onready var add_button: Button = $VBox/ToolBar/AddButton

var _property: Property
var _list_field: Field
var _property_owner: InspectableObject


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
	if _list_field and is_instance_valid(_list_field) and _list_field.has_method("_on_add_button_pressed"):
		# Ensure the list field is ready before calling its method
		if _list_field.is_node_ready():
			_list_field._on_add_button_pressed()
		else:
			await _list_field.ready
			_list_field._on_add_button_pressed()
