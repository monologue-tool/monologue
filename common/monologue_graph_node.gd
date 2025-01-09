## Abstract graph node class for Monologue dialogue nodes. This should not
## be used on its own, it should be overridden to replace [member node_type].
class_name MonologueGraphNode extends GraphNode


static var subclasses = []

@export_group("Appearance")
@export var titlebar_color: Color = Color("ff0000")
@export var show_close_button: bool = true
@export var show_titlebar: bool = true

# field UI scene definitions that a graph node can have
const CHECKBOX = preload("res://common/ui/fields/check_box/monologue_check_box.tscn")
const DROPDOWN = preload("res://common/ui/fields/dropdown/monologue_dropdown.tscn")
const FILE = preload("res://common/ui/fields/file_picker/monologue_file_picker.tscn")
const LINE = preload("res://common/ui/fields/line_edit/monologue_line_edit.tscn")
const LIST = preload("res://common/ui/fields/list/monologue_list.tscn")
const SLIDER = preload("res://common/ui/fields/slider/monologue_slider.tscn")
const SPINBOX = preload("res://common/ui/fields/spin_box/monologue_spin_box.tscn")
const TEXT = preload("res://common/ui/fields/text/monologue_text.tscn")
const TOGGLE = preload("res://common/ui/fields/toggle/monologue_toggle.tscn")

const LEFT_SLOT = preload("res://ui/assets/icons/slot.svg")
const RIGHT_SLOT = preload("res://ui/assets/icons/slot.svg")

var id := Property.new(LINE, {}, IDGen.generate())
var node_type: String = "NodeUnknown"


func _ready() -> void:
	if show_titlebar:
		_set_titlebar_color(titlebar_color)

	title = node_type
	id.setters["copyable"] = true
	id.setters["validator"] = _validate_id
	id.callers["set_label_visible"] = [false]
	for property_name in get_property_names():
		get(property_name).connect("change", change.bind(property_name))
		get(property_name).connect("display", display)
	
	_update_slot_icons()
	_harmonize_size.call_deferred()


func _update_slot_icons() -> void:
	for slot_idx in get_child_count():
		if is_slot_enabled_left(slot_idx):
			set_slot_custom_icon_left(slot_idx, LEFT_SLOT)
		if is_slot_enabled_right(slot_idx):
			set_slot_custom_icon_right(slot_idx, RIGHT_SLOT)


func _harmonize_size() -> void:
	set_deferred("size", Vector2(ceil(size.x/30)*30, ceil(size.y/30)*30))


func _set_titlebar_color(val: Color):
	var is_dark = val.get_luminance() < 0.5
	var stylebox: StyleBoxFlat = get_theme_stylebox("titlebar", "GraphNode").duplicate()
	stylebox.bg_color = val
	stylebox.corner_radius_top_left = 5
	stylebox.corner_radius_top_right = 5
	
	stylebox.border_color = Color("4d4d4d")
	stylebox.set_border_width_all(1)
	stylebox.border_width_bottom = 0
	
	var stylebox_selected = get_theme_stylebox("titlebar_selected", "GraphNode").duplicate()
	stylebox_selected.bg_color = val
	
	remove_theme_stylebox_override("titlebar")
	remove_theme_stylebox_override("titlebar_selected")
	add_theme_stylebox_override("titlebar", stylebox)
	add_theme_stylebox_override("titlebar_selected", stylebox_selected)
	
	var titlebar: HBoxContainer = get_titlebar_hbox()
	var title_label: Label = titlebar.get_children().filter(func(c) -> bool: return c is Label)[0]
	title_label.add_theme_color_override("font_color", Color.WHITE if is_dark else Color.BLACK)


func add_to(graph: MonologueGraphEdit) -> Array[MonologueGraphNode]:
	graph.add_child(self, true)
	var all_ids := graph.get_nodes().map(func(n) -> String: return n.id.value)
	id.setters["value"] = IDGen.generate(10, all_ids)
	return [self]


## Commits a given property's value into undo/redo history.
## Order of parameters is important due to how bind() works.
func change(old_value: Variant, new_value: Variant, property: String) -> void:
	var changes: Array[PropertyChange] = []
	changes.append(PropertyChange.new(property, old_value, new_value))
	
	var graph = get_graph_edit()
	var undo_redo = graph.undo_redo
	undo_redo.create_action("%s: %s => %s" % [property, old_value, new_value])
	var history = PropertyHistory.new(graph, graph.get_path_to(self), changes)
	undo_redo.add_prepared_history(history)
	undo_redo.commit_action()


func display() -> void:
	get_graph_edit().set_selected(self)


func get_graph_edit() -> MonologueGraphEdit:
	return get_parent()


func get_property_names() -> PackedStringArray:
	var names = PackedStringArray()
	for property in get_property_list():
		if property.class_name == "Property":
			names.append(property.name)
	return names


func is_editable() -> bool:
	var ignorable := ["id"]
	
	for property in get_property_names():
		if property in ignorable:
			continue
		return true
	return false


func _from_dict(dict: Dictionary) -> void:
	for key in dict.keys():
		var property = get(key.to_snake_case())
		if property is Property:
			property.value = dict.get(key)
		var private_property = get("_" + key.to_snake_case())
		if private_property is Property:
			private_property.value = dict.get(key)
	
	_load_position(dict)
	_update()  # refresh node UI after loading properties


func _load_connections(data: Dictionary, key: String = "NextID") -> void:
	var next_id = data.get(key)
	if next_id is String:
		var next_node = get_graph_edit().get_node_by_id(next_id)
		if next_node:
			get_graph_edit().connect_node(name, 0, next_node.name, 0)


func _load_position(data: Dictionary) -> void:
	var editor_position = data.get("EditorPosition")
	if editor_position:
		position_offset.x = editor_position.get("x", randi_range(-400, 400))
		position_offset.y = editor_position.get("y", randi_range(-200, 200))


func _to_dict() -> Dictionary:
	var base_dict = { "$type": node_type, "ID": id.value }
	_to_next(base_dict)
	_to_fields(base_dict)
	
	base_dict["EditorPosition"] = {
			"x": int(position_offset.x),
			"y": int(position_offset.y)
	}
	return base_dict


func _to_fields(dict: Dictionary) -> void:
	for property_name in get_property_names():
		if get(property_name).visible:
			dict[Util.to_key_name(property_name)] = get(property_name).value


func _to_next(dict: Dictionary, key: String = "NextID") -> void:
	var next_id_node = get_graph_edit().get_all_connections_from_slot(name, 0)
	dict[key] = next_id_node[0].id.value if next_id_node else -1


func _update() -> void:
	set_deferred("size", Vector2(size.x, 0))
	_harmonize_size()


func _validate_id(text: String) -> bool:
	return get_graph_edit().get_node_by_id(text) == null


func _get_field_groups() -> Array:
	return []
