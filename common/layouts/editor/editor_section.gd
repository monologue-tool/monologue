@tool
class_name EditorSection extends TabContainer

@export var default_size: int = 0 :
	set(value):
		var parent: Node = get_parent()
		if not parent is SplitContainer: return
		
		if parent.get_children().find(self) == 0:
			parent.split_offset = value
		else:
			parent.split_offset = -value
		
		default_size = value
@export var lock_size: bool = false :
	set(value):
		var parent: Node = get_parent()
		if not parent is SplitContainer: return
		if value:
			parent.dragging_enabled = false
		
		lock_size = value

var have_focus: bool = false


func _ready() -> void:
	set_process_input(true)
	update_style(false)
	get_viewport().gui_focus_changed.connect(_on_gui_focus_changed)
	
	for child in get_children():
		var icon: Variant = child.get("section_icon")
		var child_idx: int = get_children().find(child)
		if icon is Texture2D:
			set_tab_icon(child_idx, icon)
		


func _on_gui_focus_changed(node: Control) -> void:
	if Engine.is_editor_hint():
		return
	
	update_style(_is_child(node))


func update_style(focus: bool) -> void:
	var child_count := get_child_count()
	visible = child_count > 0
	tabs_visible = child_count != 1
	
	var panel_style_name: String = "panel"
	var tabbar_style_name: String = "tabbar_background"
	have_focus = focus
	if focus:
		panel_style_name += "_focus"
		tabbar_style_name += "_focus"
	else:
		panel_style_name += "_unfocus"
		tabbar_style_name += "_unfocus"
	
	if tabs_visible:
		panel_style_name = "tab_" + panel_style_name
		
	add_theme_stylebox_override("panel", get_theme_stylebox(panel_style_name, "EditorSection"))
	add_theme_stylebox_override("tabbar_background", get_theme_stylebox(tabbar_style_name, "EditorSection"))


func _is_child(node: Control) -> bool:
	var parent: Node = node
	for i in range(256):
		var next_parent = parent.get_parent()
		if next_parent == null:
			return false
		elif parent == self:
			return true
		parent = next_parent
	return false


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed():
		var mouse_hovering: bool = is_mouse_on_section()
		update_style(mouse_hovering)


func is_mouse_on_section() -> bool:
	var local_mouse_pos := get_global_mouse_position() - global_position
	return not (local_mouse_pos.x < 0 or local_mouse_pos.y < 0 or \
		local_mouse_pos.x > size.x or local_mouse_pos.y > size.y)


func _on_child_entered_tree(_node: Node) -> void:
	update_style(have_focus)


func _on_child_exiting_tree(_node: Node) -> void:
	update_style(have_focus)
