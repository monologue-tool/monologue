@tool
class_name MonologueTheme extends Theme

var scale: float
var dark_theme: bool = true
var contrast: float = 0.15
# Colors
var text_color: Color = Color("e3e4eb")
var background_color: Color = Color("19191c")
var primary_color: Color = Color("a9a8c0")
var secondary_color: Color = Color("676278")
var accent_color: Color = Color("d15050")
var warn_color: Color = Color("c42e40")
# Constants
var base_spacing: int = 8
var corner_radius: int = 6
var relationship_line_opacity: float = 0.2
var border_width: int = 1

func _init() -> void:
	scale = 1.0
	var _use_high_ppi: bool = scale >= 1.0
	
	_generate_theme()

func _generate_theme() -> void:
	# Globals
	var base_margin: float = base_spacing
	var base_border_color: Color = _get_text_color(0.2)
	var outer_radius: float = base_spacing + corner_radius
	
	# Main stylebox
	var base_sb: StyleBoxFlat = StyleBoxFlat.new()
	base_sb.bg_color = background_color
	base_sb.set_content_margin_all(base_margin)
	base_sb.set_corner_radius_all(int(corner_radius))
	base_sb.border_color = base_border_color
	
	var base_empty_sb: StyleBoxFlat = base_sb.duplicate()
	base_empty_sb.draw_center = false
	
	var base_field_sb: StyleBoxFlat = base_sb.duplicate()
	base_field_sb.content_margin_top = base_spacing/2
	base_field_sb.content_margin_bottom = base_spacing/2
	base_field_sb.bg_color = _get_secondary_color(contrast)
	
	var button_sb: StyleBoxFlat = base_sb.duplicate()
	button_sb.bg_color = _get_secondary_color(contrast)
	button_sb.content_margin_left = base_margin
	button_sb.content_margin_top = base_margin * 0.5
	button_sb.content_margin_right = base_margin
	button_sb.content_margin_bottom = base_margin * 0.5
	
	var button_hover_sb: StyleBoxFlat = button_sb.duplicate()
	button_hover_sb.bg_color = _get_secondary_color(contrast + 0.05)
	
	var button_pressed_sb: StyleBoxFlat = button_sb.duplicate()
	button_pressed_sb.bg_color = _get_secondary_color(contrast + 0.1)
	
	var button_disabled_sb: StyleBoxFlat = button_sb.duplicate()
	button_disabled_sb.bg_color = _get_secondary_color(0.05)
	
	var flat_button_sb: StyleBoxFlat = base_sb.duplicate()
	flat_button_sb.bg_color = Color.TRANSPARENT
	flat_button_sb.set_border_width_all(border_width)
	_set_border(flat_button_sb, _get_text_color(contrast))
	
	var flat_button_hover_sb: StyleBoxFlat = flat_button_sb.duplicate()
	flat_button_hover_sb.bg_color = _get_secondary_color(0.1)
	_set_border(flat_button_hover_sb, _get_text_color(contrast + 0.05))
	
	var flat_button_pressed_sb: StyleBoxFlat = flat_button_sb.duplicate()
	button_pressed_sb.bg_color = _get_secondary_color(contrast/2)
	_set_border(flat_button_hover_sb, _get_text_color(contrast + 0.1))
	
	# Button
	
	set_color("font_color", "Button", _get_text_color(0.8))
	set_color("font_disabled_color", "Button", _get_text_color(0.3))
	set_color("font_focus_color", "Button", text_color)
	set_color("font_hover_color", "Button", text_color)
	set_color("font_hover_pressed_color", "Button", text_color)
	set_color("font_pressed_color", "Button", text_color)
	set_color("icon_disabled_color", "Button", _get_text_color(0.3))
	set_color("icon_normal_color", "Button", _get_text_color(0.8))
	set_constant("outline_size", "Button", 0)
	set_stylebox('disabled', 'Button', button_disabled_sb)
	set_stylebox('disabled_mirrored', 'Button', button_disabled_sb)
	set_stylebox('focus', 'Button', base_empty_sb)
	set_stylebox('hover', 'Button', button_hover_sb)
	set_stylebox('hover_mirrored', 'Button', button_hover_sb)
	set_stylebox('hover_pressed', 'Button', button_pressed_sb)
	set_stylebox('hover_pressed_mirrored', 'Button', button_pressed_sb)
	set_stylebox('normal', 'Button', button_sb)
	set_stylebox('normal_mirrored', 'Button', button_sb)
	set_stylebox('pressed', 'Button', button_pressed_sb)
	set_stylebox('pressed_mirrored', 'Button', button_pressed_sb)
	
	# ButtonAccent
	
	set_type_variation("ButtonAccent", "Button")
	
	var button_accent_base_sb: StyleBoxFlat = base_sb.duplicate()
	button_accent_base_sb.bg_color = accent_color
	
	set_stylebox('disabled', 'ButtonAccent', button_accent_base_sb)
	set_stylebox('disabled_mirrored', 'ButtonAccent', button_accent_base_sb)
	set_stylebox('focus', 'ButtonAccent', button_accent_base_sb)
	set_stylebox('hover', 'ButtonAccent', button_accent_base_sb)
	set_stylebox('hover_mirrored', 'ButtonAccent', button_accent_base_sb)
	set_stylebox('hover_pressed', 'ButtonAccent', button_accent_base_sb)
	set_stylebox('hover_pressed_mirrored', 'ButtonAccent', button_accent_base_sb)
	set_stylebox('normal', 'ButtonAccent', button_accent_base_sb)
	set_stylebox('normal_mirrored', 'ButtonAccent', button_accent_base_sb)
	set_stylebox('pressed', 'ButtonAccent', button_accent_base_sb)
	set_stylebox('pressed_mirrored', 'ButtonAccent', button_accent_base_sb)
	
	# ButtonWarning
	
	set_type_variation("ButtonWarning", "Button")
	
	var delete_button_sb: StyleBoxFlat = button_sb.duplicate()
	delete_button_sb.bg_color = _get_color(warn_color, contrast)
	
	var delete_button_hover_sb: StyleBoxFlat = button_sb.duplicate()
	delete_button_hover_sb.bg_color = _get_color(warn_color, contrast + 0.05)
	
	var delete_button_pressed_sb: StyleBoxFlat = button_sb.duplicate()
	delete_button_pressed_sb.bg_color = _get_color(warn_color, contrast + 0.1)
	
	var delete_button_disabled_sb: StyleBoxFlat = button_sb.duplicate()
	delete_button_disabled_sb.bg_color = _get_color(warn_color, 0.05)
	
	set_constant("outline_size", "ButtonWarning", 0)
	set_stylebox('disabled', 'ButtonWarning', delete_button_disabled_sb)
	set_stylebox('disabled_mirrored', 'ButtonWarning', delete_button_disabled_sb)
	set_stylebox('focus', 'ButtonWarning', base_empty_sb)
	set_stylebox('hover', 'ButtonWarning', delete_button_hover_sb)
	set_stylebox('hover_mirrored', 'ButtonWarning', delete_button_hover_sb)
	set_stylebox('hover_pressed', 'ButtonWarning', delete_button_pressed_sb)
	set_stylebox('hover_pressed_mirrored', 'ButtonWarning', delete_button_pressed_sb)
	set_stylebox('normal', 'ButtonWarning', delete_button_sb)
	set_stylebox('normal_mirrored', 'ButtonWarning', delete_button_sb)
	set_stylebox('pressed', 'ButtonWarning', delete_button_pressed_sb)
	set_stylebox('pressed_mirrored', 'ButtonWarning', delete_button_pressed_sb)
	
	# CheckBox
	
	var check_box_sb: StyleBoxFlat = base_empty_sb.duplicate()
	check_box_sb.set_content_margin_all(0)
	
	var check_box_hover_sb: StyleBoxFlat = check_box_sb.duplicate()
	#check_box_hover_sb.bg_color = _get_primary_color(contrast)
	
	var check_box_pressed_sb: StyleBoxFlat = check_box_sb.duplicate()
	#check_box_pressed_sb.bg_color = _get_primary_color(contrast)
	
	var check_box_disabled_sb: StyleBoxFlat = check_box_sb.duplicate()
	#check_box_disabled_sb.bg_color = _get_primary_color(0.05)
	
	set_color('font_hover_pressed_color', 'CheckBox', text_color)
	set_color('font_pressed_color', 'CheckBox', _get_text_color(0.7))
	set_constant("h_separation", "CheckBox", int(base_margin))
	set_icon("checked", "CheckBox", preload("res://ui/theme_default/assets/checked.svg"))
	set_icon("unchecked", "CheckBox", preload("res://ui/theme_default/assets/unchecked.svg"))
	set_icon("radio_checked", "CheckBox", preload("res://ui/theme_default/assets/radio_checked.svg"))
	set_icon("radio_unchecked", "CheckBox", preload("res://ui/theme_default/assets/radio_unchecked.svg"))
	set_icon("checked_disabled", "CheckBox", preload("res://ui/theme_default/assets/checked_disabled.svg"))
	set_icon("unchecked_disabled", "CheckBox", preload("res://ui/theme_default/assets/unchecked_disabled.svg"))
	set_icon("radio_checked_disabled", "CheckBox", preload("res://ui/theme_default/assets/radio_checked_disabled.svg"))
	set_icon("radio_unchecked_disabled", "CheckBox", preload("res://ui/theme_default/assets/radio_unchecked_disabled.svg"))
	set_stylebox("focus", "CheckBox", check_box_hover_sb)
	set_stylebox("disabled", "CheckBox", check_box_disabled_sb)
	set_stylebox("disabled_mirrored", "CheckBox", check_box_disabled_sb)
	set_stylebox("hover", "CheckBox", check_box_hover_sb)
	set_stylebox("hover_mirrored", "CheckBox", check_box_hover_sb)
	set_stylebox("hover_pressed", "CheckBox", check_box_pressed_sb)
	set_stylebox("hover_pressed_mirrored", "CheckBox", check_box_pressed_sb)
	set_stylebox("pressed", "CheckBox", check_box_pressed_sb)
	set_stylebox("pressed_mirrored", "CheckBox", check_box_pressed_sb)
	set_stylebox("normal", "CheckBox", check_box_sb)
	set_stylebox("normal_mirrored", "CheckBox", check_box_sb)
	
	# CheckButton
	
	set_color("font_focus_color", "CheckButton", _get_text_color(0.7))
	set_color("font_hover_pressed_color", "CheckButton", text_color)
	set_color("font_pressed_color", "CheckButton", text_color)
	set_icon("checked", "CheckButton", preload("res://ui/assets/icons/toggle_on.svg"))
	set_icon("unchecked", "CheckButton", preload("res://ui/assets/icons/toggle_off.svg"))
	set_stylebox("focus", "CheckButton", check_box_hover_sb)
	set_stylebox("disabled", "CheckButton", check_box_disabled_sb)
	set_stylebox("disabled_mirrored", "CheckButton", check_box_disabled_sb)
	set_stylebox("hover", "CheckButton", check_box_hover_sb)
	set_stylebox("hover_mirrored", "CheckButton", check_box_hover_sb)
	set_stylebox("hover_pressed", "CheckButton", check_box_pressed_sb)
	set_stylebox("hover_pressed_mirrored", "CheckButton", check_box_pressed_sb)
	set_stylebox("pressed", "CheckButton", check_box_pressed_sb)
	set_stylebox("pressed_mirrored", "CheckButton", check_box_pressed_sb)
	set_stylebox("normal", "CheckButton", check_box_sb)
	set_stylebox("normal_mirrored", "CheckButton", check_box_sb)
	
	# CollapsibleFieldPanel
	
	set_type_variation("CollapsibleFieldPanel", "PanelContainer")
	var sb: StyleBoxFlat = base_sb.duplicate()
	sb.bg_color = _get_secondary_color(contrast/2)
	set_stylebox("panel", "CollapsibleFieldPanel", sb)
	
	# EditorBackground
	
	set_type_variation("EditorBackground", "PanelContainer")
	sb = base_sb.duplicate()
	sb.bg_color = _get_primary_color(contrast, false)
	sb.set_corner_radius_all(0)
	sb.set_content_margin_all(0)
	set_stylebox("panel", "EditorBackground", sb)
	
	# EditorSidePanel
	
	set_type_variation("EditorSidePanel", "PanelContainer")
	sb = base_sb.duplicate()
	sb.bg_color = _get_primary_color(contrast, false)
	sb.set_corner_radius_all(0)
	sb.set_border_width_all(0)
	sb.border_width_left = 1
	set_stylebox("panel", "EditorSidePanel", sb)
	
	# EditorSidePanelTopBox
	
	set_type_variation("EditorSidePanelTopBox", "PanelContainer")
	sb = base_sb.duplicate()
	sb.bg_color = _get_primary_color(contrast, false)
	sb.set_corner_radius_all(0)
	sb.set_border_width_all(0)
	sb.set_content_margin_all(0)
	sb.set_expand_margin_all(base_spacing)
	sb.expand_margin_left -= 1
	set_stylebox("panel", "EditorSidePanelTopBox", sb)
	
	# FlatButton
	
	set_color('font_color', 'FlatButton', _get_text_color(0.8))
	set_color('font_disabled_color', 'FlatButton', _get_text_color(0.3))
	set_color('font_focus_color', 'FlatButton', text_color)
	set_color('font_hover_color', 'FlatButton', text_color)
	set_color('font_hover_pressed_color', 'FlatButton', text_color)
	set_color('font_pressed_color', 'FlatButton', text_color)
	set_color('icon_disabled_color', 'FlatButton', _get_text_color(0.3))
	set_color('icon_normal_color', 'FlatButton', _get_text_color(0.8))
	set_constant("outline_size", "FlatButton", 0)
	set_stylebox('disabled', 'FlatButton', button_disabled_sb)
	set_stylebox('disabled_mirrored', 'FlatButton', button_disabled_sb)
	set_stylebox('normal', 'FlatButton', flat_button_sb)
	set_stylebox('normal_mirrored', 'FlatButton', flat_button_sb)
	set_stylebox('hover', 'FlatButton', flat_button_hover_sb)
	set_stylebox('hover_mirrored', 'FlatButton', flat_button_hover_sb)
	set_stylebox('hover_pressed', 'FlatButton', flat_button_pressed_sb)
	set_stylebox('hover_pressed_mirrored', 'FlatButton', flat_button_pressed_sb)
	set_stylebox('pressed', 'FlatButton', flat_button_pressed_sb)
	set_stylebox('pressed_mirrored', 'FlatButton', flat_button_pressed_sb)
	
	# GraphEdit
	
	sb = base_sb.duplicate()
	sb.set_content_margin_all(0)
	sb.set_corner_radius_all(0)
	sb.set_border_width_all(0)
	set_color("grid_major", "GraphEdit", _get_text_color(contrast))
	set_color("grid_minor", "GraphEdit", _get_text_color(contrast))
	set_stylebox("panel", "GraphEdit", sb)
	
	# GraphNode
	
	var graph_node_sb: StyleBoxFlat = base_sb.duplicate()
	graph_node_sb.bg_color = _get_primary_color(contrast, false)
	graph_node_sb.corner_radius_top_left = 0
	graph_node_sb.corner_radius_top_right = 0
	graph_node_sb.shadow_color = Color("#000000", contrast)
	graph_node_sb.shadow_size = 30
	_set_border(graph_node_sb, base_border_color)
	graph_node_sb.border_width_top = 0
	
	var graph_node_selected_sb: StyleBoxFlat = graph_node_sb.duplicate()
	graph_node_selected_sb.border_color.a += 0.1
	
	var graph_node_titlebar_sb: StyleBoxFlat = base_sb.duplicate()
	graph_node_titlebar_sb.corner_radius_bottom_left = 0
	graph_node_titlebar_sb.corner_radius_bottom_right = 0
	graph_node_titlebar_sb.shadow_color = Color("#000000", contrast)
	graph_node_titlebar_sb.shadow_size = 30
	_set_border(graph_node_titlebar_sb, base_border_color)
	graph_node_titlebar_sb.border_width_bottom = 0
	
	var graph_node_titlebar_selected_sb: StyleBoxFlat = graph_node_titlebar_sb.duplicate()
	graph_node_titlebar_selected_sb.border_color.a += 0.1
	
	set_icon("port", "GraphNode", preload("res://ui/assets/icons/slot.svg"))
	set_constant("separation", "GraphNode", base_spacing)
	set_stylebox("panel", "GraphNode", graph_node_sb)
	set_stylebox("panel_selected", "GraphNode", graph_node_selected_sb)
	set_stylebox("titlebar", "GraphNode", graph_node_titlebar_sb)
	set_stylebox("titlebar_selected", "GraphNode", graph_node_titlebar_selected_sb)
	set_stylebox("slot", "GraphNode", StyleBoxEmpty.new())
	
	# GraphNodePicker
	
	set_type_variation("GraphNodePicker", "PanelContainer")
	sb = base_sb.duplicate()
	sb.bg_color = _get_primary_color(contrast, false)
	set_stylebox("panel", "GraphNodePicker", sb)
	
	# HBoxContainer & VBoxContainer
	
	set_type_variation("FieldContainer", "VBoxContainer")
	
	set_constant("separation", "HBoxContainer", base_spacing)
	set_constant("separation", "VBoxContainer", base_spacing)
	set_constant("separation", "FieldContainer", base_spacing/2)
	
	# HDottedSeparator & VDottedSeparator
	
	set_type_variation("HDottedSeparator", "HSeparator")
	set_type_variation("VDottedSeparator", "VSeparator")
	var dotted_sb: StyleBoxTexture = StyleBoxTexture.new()
	dotted_sb.texture = preload("res://ui/theme_default/assets/dash.svg")
	dotted_sb.modulate_color = base_border_color
	dotted_sb.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT
	dotted_sb.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT
	dotted_sb.texture_margin_top = 1
	set_constant("separation", "HDottedSeparator", 1)
	set_constant("separation", "VDottedSeparator", 1)
	set_stylebox("separator", "HDottedSeparator", dotted_sb)
	set_stylebox("separator", "VDottedSeparator", dotted_sb)
	
	# HSeparator & VSeparator
	
	var separator_sb: StyleBoxLine = StyleBoxLine.new()
	separator_sb.color = base_border_color
	separator_sb.vertical = false
	separator_sb.grow_begin = 0
	separator_sb.grow_end = 0
	set_constant("separation", "HSeparator", 1)
	set_constant("separation", "VSeparator", 1)
	set_stylebox("separator", "HSeparator", separator_sb)
	separator_sb = separator_sb.duplicate()
	separator_sb.vertical = true
	set_stylebox("separator", "VSeparator", separator_sb)
	
	# HSeparatorGrow & VSeparatorGrow
	
	set_type_variation("HSeparatorGrow", "HSeparator")
	set_type_variation("VSeparatorGrow", "VSeparator")
	separator_sb = separator_sb.duplicate()
	separator_sb.vertical = false
	separator_sb.grow_begin = base_spacing
	separator_sb.grow_end = base_spacing
	set_constant("separation", "HSeparatorGrow", 1)
	set_constant("separation", "VSeparatorGrow", 1)
	set_stylebox("separator", "HSeparatorGrow", separator_sb)
	separator_sb = separator_sb.duplicate()
	separator_sb.vertical = true
	set_stylebox("separator", "VSeparatorGrow", separator_sb)
	
	# HSlider
	
	var slider_sb: StyleBoxFlat = StyleBoxFlat.new()
	slider_sb.content_margin_top = 5
	slider_sb.set_corner_radius_all(5)
	slider_sb.bg_color = _get_primary_color(contrast)
	
	var grabber_area: StyleBoxFlat = slider_sb.duplicate()
	grabber_area.bg_color = accent_color
	
	set_icon("grabber", "HSlider", preload("res://ui/theme_default/assets/grabber.svg"))
	set_icon("grabber_highlight", "HSlider", preload("res://ui/theme_default/assets/grabber.svg"))
	set_icon("grabber_disabled", "HSlider", preload("res://ui/theme_default/assets/grabber.svg"))
	set_stylebox("slider", "HSlider", slider_sb)
	set_stylebox("grabber_area", "HSlider", grabber_area)
	set_stylebox("grabber_area_highlight", "HSlider", grabber_area)
	
	# ItemContainer
	
	set_type_variation("ItemContainer", "PanelContainer")
	
	sb = base_empty_sb.duplicate()
	set_stylebox("panel", "ItemContainer", sb)
	
	# Label
	
	set_type_variation("NodeValue", "Label")
	set_type_variation("NoteLabel", "Label")
	set_type_variation("WarnLabel", "Label")
	sb = base_sb.duplicate()
	set_color("font_color", "Label", text_color)
	set_color("font_color", "NodeValue", text_color)
	set_color("font_color", "NoteLabel", _get_text_color(0.6))
	set_color("font_color", "WarnLabel", warn_color)
	set_stylebox("normal", "NodeValue", sb)
	
	# LineEdit
	
	var line_edit_sb: StyleBoxFlat = base_field_sb.duplicate()
	
	var line_edit_focus_sb: StyleBoxFlat = line_edit_sb.duplicate()
	line_edit_focus_sb.draw_center = false
	line_edit_focus_sb.set_border_width_all(1)
	
	var line_edit_disabled_sb: StyleBoxFlat = line_edit_sb.duplicate()
	line_edit_disabled_sb.bg_color = _get_primary_color(0.05)
	
	set_stylebox("normal", "LineEdit", line_edit_sb)
	set_stylebox("focus", "LineEdit", line_edit_focus_sb)
	set_stylebox("disabled", "LineEdit", line_edit_disabled_sb)
	
	# MarginContainer
	
	set_constant("margin_left", "MarginContainer", int(base_margin))
	set_constant("margin_top", "MarginContainer", int(base_margin))
	set_constant("margin_right", "MarginContainer", int(base_margin))
	set_constant("margin_bottom", "MarginContainer", int(base_margin))
	
	# Panel
	
	sb = base_sb.duplicate()
	sb.bg_color = _get_primary_color(contrast, false)
	set_stylebox("panel", "Panel", sb)
	set_stylebox("panel", "PanelContainer", sb)
	
	# PopupMenu
	
	sb = base_sb.duplicate()
	sb.bg_color = _get_primary_color(contrast, false)
	_set_border(sb, _get_color(base_border_color, base_border_color.a, false))
	var popup_menu_hover_sb: StyleBoxFlat = base_field_sb.duplicate()
	popup_menu_hover_sb.bg_color = _get_secondary_color(contrast)
	separator_sb.color = text_color
	separator_sb.vertical = true
	separator_sb.grow_begin = 0
	separator_sb.grow_end = 0
	set_constant("icon_max_width", "PopupMenu", 14)
	set_constant("item_end_padding", "PopupMenu", base_spacing)
	set_constant("item_start_padding", "PopupMenu", base_spacing)
	set_constant("h_separation", "PopupMenu", base_spacing)
	set_constant("v_separation", "PopupMenu", 4)
	set_font_size("font_size", "PopupMenu", 16)
	set_icon("checked", "PopupMenu", preload("res://ui/theme_default/assets/checked.svg"))
	set_icon("unchecked", "PopupMenu", preload("res://ui/theme_default/assets/unchecked.svg"))
	set_icon("radio_checked", "PopupMenu", preload("res://ui/theme_default/assets/radio_checked.svg"))
	set_icon("radio_unchecked", "PopupMenu", preload("res://ui/theme_default/assets/radio_unchecked.svg"))
	set_icon("checked_disabled", "PopupMenu", preload("res://ui/theme_default/assets/checked_disabled.svg"))
	set_icon("unchecked_disabled", "PopupMenu", preload("res://ui/theme_default/assets/unchecked_disabled.svg"))
	set_icon("radio_checked_disabled", "PopupMenu", preload("res://ui/theme_default/assets/radio_checked_disabled.svg"))
	set_icon("radio_unchecked_disabled", "PopupMenu", preload("res://ui/theme_default/assets/radio_unchecked_disabled.svg"))
	set_stylebox("panel", "PopupMenu", sb)
	set_stylebox("hover", "PopupMenu", popup_menu_hover_sb)
	set_stylebox("separator", "PopupMenu", separator_sb)
	
	# ScrollBar
	var _side_panel_bg_color: Color = _get_primary_color(contrast, false)
	var _scroll_bar_color: Color = _get_color(base_border_color, base_border_color.a, false, _side_panel_bg_color)
	
	var scroll_sb: StyleBoxFlat = base_empty_sb.duplicate()
	scroll_sb.border_color = _scroll_bar_color
	scroll_sb.set_content_margin_all(2)
	scroll_sb.set_corner_radius_all(0)
	
	# ScrollBar's focus stylebox is not working.
	var scroll_focus_sb: StyleBoxFlat = scroll_sb.duplicate()
	scroll_focus_sb.draw_center = true
	
	var grabber_sb: StyleBoxFlat = base_sb.duplicate()
	grabber_sb.set_corner_radius_all(5)
	grabber_sb.bg_color = _scroll_bar_color
	
	set_stylebox("scroll", "VScrollBar", scroll_sb)
	set_stylebox("scroll_focus", "VScrollBar", scroll_focus_sb)
	set_stylebox("grabber", "VScrollBar", grabber_sb)
	set_stylebox("grabber", "VScrollBar", grabber_sb)
	set_stylebox("grabber_highlight", "VScrollBar", grabber_sb)
	set_stylebox("grabber_pressed", "VScrollBar", grabber_sb)
	
	set_stylebox("scroll", "HScrollBar", scroll_sb)
	set_stylebox("scroll_focus", "HScrollBar", scroll_focus_sb)
	set_stylebox("grabber", "HScrollBar", grabber_sb)
	set_stylebox("grabber", "HScrollBar", grabber_sb)
	set_stylebox("grabber_highlight", "HScrollBar", grabber_sb)
	set_stylebox("grabber_pressed", "HScrollBar", grabber_sb)
	
	# SpinBoxButton
	
	set_type_variation("SpinBoxButtonLeft", "Button")
	set_type_variation("SpinBoxButtonRight", "Button")
	
	var spin_box_button_sb: StyleBoxFlat = base_empty_sb.duplicate()
	spin_box_button_sb.set_content_margin_all(base_spacing/2)
	var spin_box_button_pressed_sb: StyleBoxFlat = base_sb.duplicate()
	spin_box_button_pressed_sb.set_content_margin_all(base_spacing/2)
	spin_box_button_pressed_sb.bg_color = _get_primary_color(contrast)
	spin_box_button_pressed_sb.corner_radius_top_right = 0
	spin_box_button_pressed_sb.corner_radius_bottom_right = 0
	
	set_stylebox("normal", "SpinBoxButtonLeft", spin_box_button_sb)
	set_stylebox("pressed", "SpinBoxButtonLeft", spin_box_button_pressed_sb)
	set_stylebox("focus", "SpinBoxButtonLeft", spin_box_button_sb)
	set_stylebox("hover", "SpinBoxButtonLeft", spin_box_button_sb)
	set_stylebox("disabled", "SpinBoxButtonLeft", spin_box_button_sb)
	
	spin_box_button_pressed_sb = spin_box_button_pressed_sb.duplicate()
	spin_box_button_pressed_sb.set_corner_radius_all(corner_radius)
	spin_box_button_pressed_sb.corner_radius_top_left = 0
	spin_box_button_pressed_sb.corner_radius_bottom_left = 0
	
	set_stylebox("normal", "SpinBoxButtonRight", spin_box_button_sb)
	set_stylebox("pressed", "SpinBoxButtonRight", spin_box_button_pressed_sb)
	set_stylebox("focus", "SpinBoxButtonRight", spin_box_button_sb)
	set_stylebox("hover", "SpinBoxButtonRight", spin_box_button_sb)
	set_stylebox("disabled", "SpinBoxButtonRight", spin_box_button_sb)
	
	# SpinBoxLineEdit
	
	set_type_variation("SpinBoxLineEdit", "LineEdit")
	
	var spin_box_line_edit_sb: StyleBoxFlat = base_field_sb.duplicate()
	spin_box_line_edit_sb.draw_center = false
	spin_box_line_edit_sb.set_content_margin_all(0)
	var spin_box_line_edit_focus_sb: StyleBoxFlat = spin_box_line_edit_sb.duplicate()
	spin_box_line_edit_focus_sb.bg_color = _get_primary_color(contrast)
	spin_box_line_edit_focus_sb.set_corner_radius_all(0)
	
	set_stylebox("normal", "SpinBoxLineEdit", spin_box_line_edit_sb)
	set_stylebox("focus", "SpinBoxLineEdit", spin_box_line_edit_focus_sb)
	set_stylebox("read_only", "SpinBoxLineEdit", spin_box_line_edit_sb)
	
	# SpinBoxPanel
	
	set_type_variation("SpinBoxPanel", "PanelContainer")
	sb = base_sb.duplicate()
	sb.bg_color = _get_primary_color(contrast/2)
	sb.set_content_margin_all(0)
	set_stylebox("panel", "SpinBoxPanel", sb)
	
	# TabBar
	
	var tab_unselected_sb: StyleBoxFlat = base_sb.duplicate()
	tab_unselected_sb.draw_center = false
	tab_unselected_sb.set_border_width_all(0)
	tab_unselected_sb.border_width_right = 1
	tab_unselected_sb.set_corner_radius_all(0)
	
	var tab_hovered_sb: StyleBoxFlat = tab_unselected_sb.duplicate()
	var tab_selected_sb: StyleBoxFlat = tab_unselected_sb.duplicate()
	tab_selected_sb.draw_center = true
	tab_selected_sb.bg_color = accent_color
	
	var tab_disabled_sb: StyleBoxFlat = tab_unselected_sb.duplicate()
	var tab_focus_sb: StyleBoxFlat = tab_unselected_sb.duplicate()
	
	set_color("font_disabled_color", "TabBar", _get_text_color(0.3))
	set_color("font_unselected_color", "TabBar", _get_text_color(0.8))
	set_color("font_hovered_color", "TabBar", text_color)
	set_color("font_selected_color", "TabBar", text_color)
	set_constant("h_separation", "TabBar", base_spacing)
	set_font_size("font_size", "TabBar", 16)
	set_stylebox("button_highlight", "TabBar", StyleBoxEmpty.new())
	set_stylebox("button_pressed", "TabBar", StyleBoxEmpty.new())
	set_stylebox("tab_unselected", "TabBar", tab_unselected_sb)
	set_stylebox("tab_hovered", "TabBar", tab_hovered_sb)
	set_stylebox("tab_selected", "TabBar", tab_selected_sb)
	set_stylebox("tab_disabled", "TabBar", tab_disabled_sb)
	set_stylebox("tab_focus", "TabBar", tab_focus_sb)
	
	# TextEdit
	var text_edit_sb: StyleBoxFlat = line_edit_sb.duplicate()
	
	var text_edit_focus_sb: StyleBoxFlat = line_edit_focus_sb.duplicate()
	
	var text_edit_disabled_sb: StyleBoxFlat = line_edit_disabled_sb.duplicate()
	
	set_font("font", "TextEdit", preload("res://ui/assets/fonts/CourierNewPSMT.ttf"))
	set_font_size("font_size", "TextEdit", 16)
	set_stylebox("normal", "TextEdit", text_edit_sb)
	set_stylebox("focus", "TextEdit", text_edit_focus_sb)
	set_stylebox("read_only", "TextEdit", text_edit_disabled_sb)
	
	# Tree
	
	var tree_sb: StyleBoxFlat = base_sb.duplicate()
	var tree_focus_sb: StyleBoxFlat = base_empty_sb.duplicate()
	
	set_color("relashion_ship_line_color", "Tree", Color(base_border_color, base_border_color.a/2))
	#set_color("guide_color", "Tree", Color(base_border_color, base_border_color.a/2))
	set_constant("icon_max_width", "Tree", 14)
	set_constant("h_separation", "Tree", base_spacing)
	set_constant("v_separation", "Tree", base_spacing/2)
	set_constant("inner_item_margin_bottom", "Tree", base_spacing)
	set_constant("inner_item_margin_left", "Tree", base_spacing)
	set_constant("inner_item_margin_top", "Tree", base_spacing)
	set_constant("inner_item_margin_right", "Tree", base_spacing)
	set_constant("draw_relationship_lines", "Tree", 1)
	set_constant("draw_guides", "Tree", 0)
	set_constant("relationship_line_width", "Tree", 0)
	set_constant("parent_hl_line_width", "Tree", border_width)
	set_constant("children_hl_line_width", "Tree", 0)
	set_icon("checked", "Tree", preload("res://ui/theme_default/assets/checked.svg"))
	set_icon("unchecked", "Tree", preload("res://ui/theme_default/assets/unchecked.svg"))
	set_icon("checked_disabled", "Tree", preload("res://ui/theme_default/assets/checked_disabled.svg"))
	set_icon("unchecked_disabled", "Tree", preload("res://ui/theme_default/assets/unchecked_disabled.svg"))
	set_stylebox("panel", "Tree", tree_sb)
	set_stylebox("focus", "Tree", tree_focus_sb)
	set_stylebox("hovered", "Tree", button_hover_sb)
	set_stylebox("hovered_dimmed", "Tree", button_hover_sb)
	set_stylebox("selected", "Tree", button_pressed_sb)
	set_stylebox("selected_focus", "Tree", button_pressed_sb)
	
	# TreeContainer
	
	set_type_variation("TreeContainer", "PanelContainer")
	
	sb = base_sb.duplicate()
	sb.set_corner_radius_all(0)
	sb.bg_color = _get_primary_color(contrast, false)
	set_stylebox("panel", "TreeContainer", sb)
	
	# OptionButton
	
	var option_button_sb = base_field_sb.duplicate()
	option_button_sb.bg_color = _get_secondary_color(contrast)
	
	var option_button_hover_sb: StyleBoxFlat = button_sb.duplicate()
	option_button_hover_sb.bg_color = _get_secondary_color(contrast + 0.05)
	
	var option_button_pressed_sb: StyleBoxFlat = button_sb.duplicate()
	option_button_pressed_sb.bg_color = _get_secondary_color(contrast + 0.1)
	
	var option_button_disabled_sb: StyleBoxFlat = button_sb.duplicate()
	option_button_disabled_sb.bg_color = _get_secondary_color(0.05)
	
	set_constant("arrow_margin", "OptionButton", base_spacing)
	set_constant("h_separation", "OptionButton", base_spacing)
	set_stylebox('disabled', 'OptionButton', option_button_disabled_sb)
	set_stylebox('disabled_mirrored', 'OptionButton', option_button_disabled_sb)
	set_stylebox('focus', 'OptionButton', base_empty_sb)
	set_stylebox('hover', 'OptionButton', option_button_hover_sb)
	set_stylebox('hover_mirrored', 'OptionButton', option_button_hover_sb)
	set_stylebox('hover_pressed', 'OptionButton', option_button_pressed_sb)
	set_stylebox('hover_pressed_mirrored', 'OptionButton', option_button_pressed_sb)
	set_stylebox('normal', 'OptionButton', option_button_sb)
	set_stylebox('normal_mirrored', 'OptionButton', option_button_sb)
	set_stylebox('pressed', 'OptionButton', option_button_pressed_sb)
	set_stylebox('pressed_mirrored', 'OptionButton', option_button_pressed_sb)
	
	# OuterPanel
	
	set_type_variation("OuterPanel", "PanelContainer")
	sb = base_sb.duplicate()
	sb.bg_color = _get_primary_color(contrast, false)
	sb.set_corner_radius_all(int(outer_radius))
	_set_border(sb, _get_color(base_border_color, base_border_color.a, false))
	set_stylebox("panel", "OuterPanel", sb)


func _get_primary_color(alpha: float = 1.0, transparent: bool = true) -> Color:
	#return _get_color(secondary_color, alpha, transparent)
	return _get_color(primary_color, alpha, transparent)
	
func _get_secondary_color(alpha: float = 1.0, transparent: bool = true) -> Color:
	#return _get_color(primary_color, alpha, transparent)
	return _get_color(secondary_color, alpha, transparent)

func _get_text_color(alpha: float = 1.0, transparent: bool = true) -> Color:
	return _get_color(text_color, alpha, transparent)

func _get_color(color: Color, alpha: float = 1.0, transparent: bool = true, blend_with: Color = background_color) -> Color:
	if transparent:
		return Color(color, alpha)
	return Color(blend_with).blend(Color(color, alpha))


# Shorthand content margin setter
func _set_margin(sb: StyleBox, left: float, top: float, right: float = left, bottom: float = top) -> void:
	sb.content_margin_left = left * scale
	sb.content_margin_top = top * scale
	sb.content_margin_right = right * scale
	sb.content_margin_bottom = bottom * scale

# Shorthand border setter
func _set_border(sb: StyleBoxFlat, color: Color, width: float = 1, blend: bool = false) -> void:
	sb.border_color = color
	sb.border_blend = blend
	sb.set_border_width_all(int(ceilf(width * scale)))
