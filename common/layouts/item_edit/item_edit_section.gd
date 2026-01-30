class_name ItemEditSection extends Control

## Item index that is being edited in the graph_edit.
var item_index: int = -1:
	set = set_index
## Container which will house all the fields for this section.
var field_vbox: Control
var list_name: String = "":
	set = set_list_name
var list_owner: InspectableObject:
	set = set_list_owner
## List of other sections that are linked to this section.
var linked_sections: Array[ItemEditSection]


func _ready() -> void:
	for entry in get_property_list():
		if Constants.PROPERTY_CLASSES.has(entry.class_name):
			get(entry.name).connect("change", change.bind(entry.name))


## Deletes all field controls in the field_vbox.
func flush() -> void:
	for field in field_vbox.get_children():
		field.queue_free()


func set_list_name(new_name: String) -> void:
	list_name = new_name
	for section in linked_sections:
		section.list_name = list_name


func set_list_owner(new_owner: InspectableObject) -> void:
	list_owner = new_owner
	for section in linked_sections:
		section.list_owner = list_owner


func set_index(index: int) -> void:
	item_index = index
	for section in linked_sections:
		section.item_index = index


func change(old_value: Variant, new_value: Variant, property: String) -> void:
	pass
