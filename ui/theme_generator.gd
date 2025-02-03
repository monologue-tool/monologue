@tool
class_name MonologueThemeGenerator extends ProgrammaticTheme

## Colors
var primary_color: Color = Color("313136")
var secondary_color: Color = Color("36363c")
var tertiary_color: Color = Color("46464d")

var primary_text_color: Color = Color("ffffff")
var primary_text_color_02: Color = Color("ffffff05")
var primary_text_color_40: Color = Color("ffffff64")
var secondary_text_color: Color = Color("b3b3b3")

var accent_color: Color = Color("d55160")
var background_color: Color = Color("1e1e21")
var border_color: Color = tertiary_color

## Constants
var default_border_width: int = 1

var primary_corner_radius: int = 30
var secondary_corner_radius: int = 15
var tertiary_corner_radius: int = 5

var primary_content_margin: int = 20
var secondary_content_margin: int = 10
var tertiary_content_margin: int = 5

var general_normal_stylebox: Dictionary = stylebox_flat({
	bg_color = primary_color,
	corners_ = corner_radius(secondary_corner_radius),
	font_color = primary_text_color,
	margins_ = content_margins(secondary_content_margin)
})
var base_border_stylebox: Dictionary = stylebox_flat({
	borders_ = border_width(default_border_width),
	border_color = border_color,
})


var hover_button: Dictionary = { bg_color = tertiary_color }
var pressed_button: Dictionary = { bg_color = accent_color }
var empty_button: Dictionary = { draw_center = false }


func get_inner_radius(outer_radius: int, padding: int) -> int:
	return outer_radius - padding
func get_outer_radius(inner_radius: int, padding: int) -> int:
	return inner_radius + padding
func get_radius_padding(outer_radius: int, inner_radius: int) -> int:
	return outer_radius - inner_radius


func setup() -> void:
	set_save_path("res://ui/theme_default/main.tres")


func define_theme() -> void:
#region Button/OptionButton/MenuButton style
	var button_style: Dictionary = stylebox_flat({
		bg_color = secondary_color,
		corners_ = corner_radius(tertiary_corner_radius),
		margins_ = content_margins(secondary_content_margin, tertiary_content_margin)
	})
	var button_style_no_corner: Dictionary = inherit(button_style, { corners_ = corner_radius(0) })
	
	for node_type in ["Button", "OptionButton", "MenuButton"]:
		_button_style_builder(button_style, node_type)
		_button_style_builder(button_style_no_corner, node_type, "_NoCorner")
#endregion
	
#region CheckBox style
	define_style("CheckBox", {
		normal = inherit(button_style, empty_button, base_border_stylebox),
		hover = inherit(button_style, hover_button),
		pressed = inherit(button_style, pressed_button),
		focus = inherit(button_style, hover_button)
	})
#endregion
	
#region GraphEdit style
	var graph_edit_panel: Dictionary = stylebox_flat({ bg_color = background_color })
	
	define_style("GraphEdit", {
		grid_major = Color("ffffff0d"),
		grid_minor = Color("ffffff0d"),
		panel = graph_edit_panel
	})
#endregion
	
#region GraphNode style
	var selected_graph_node: Dictionary = { border_color = Color("fff") }
	
	var graph_node_panel_style: Dictionary = stylebox_flat({
		bg_color = primary_color,
		corners_ = corner_radius(0, 0, tertiary_corner_radius, tertiary_corner_radius),
		margins_ = content_margins(primary_content_margin, primary_content_margin, primary_content_margin, primary_content_margin)
	})
	var selected_graph_node_panel_style: Dictionary = inherit(graph_node_panel_style, selected_graph_node, stylebox_flat({
		border_ = border_width(1, 0, 1, 1)
	}))
	var graph_node_titlebar_style: Dictionary = stylebox_flat({
		corners_ = corner_radius(tertiary_corner_radius, tertiary_corner_radius, 0, 0),
		margins_ = content_margins(primary_content_margin, tertiary_content_margin, primary_content_margin, tertiary_content_margin)
	})
	var selected_graph_node_titlebar_style: Dictionary = inherit(graph_node_titlebar_style, selected_graph_node, stylebox_flat({
		border_ = border_width(1, 1, 1, 0)
	}))
	
	define_style("GraphNode", {
		separation = tertiary_content_margin,
		port = preload("res://ui/assets/icons/slot.svg"),
		
		panel = graph_node_panel_style,
		panel_selected = selected_graph_node_panel_style,
		slot = stylebox_empty({}),
		titlebar = graph_node_titlebar_style,
		titlebar_selected = selected_graph_node_titlebar_style
	})
#endregion
	
	define_style("GraphNodeTitleLabel", {
		font = preload("res://ui/assets/fonts/NotoSans-SemiBold.ttf"),
		normal = stylebox_empty({})
	})
	
#region Separator
	var separator_style = stylebox_line({
		color = border_color,
		grow_begin = 0,
		grow_end = 0,
		thickness = 1,
	})
	for separator_type in ["HSeparator", "VSeparator"]:
		var separator_type_style: Dictionary = inherit(separator_style, stylebox_line({
			vertical = separator_type == "VSeparator"
		}))
		define_style(separator_type, {
			separation = 1,
			separator = separator_type_style
		})
		
		for margin in [primary_content_margin, secondary_content_margin, tertiary_content_margin]:
			var variant_separator: Dictionary = { grow_begin = margin, grow_end = margin }
			
			define_variant_style("%s_Grow%s" % [separator_type, margin], separator_type, {
				separation = 1,
				separator = inherit(separator_type_style, variant_separator)
			})
#endregion
	
#region Label style
	var node_value_style: Dictionary = stylebox_flat({
		margins_ = content_margins(tertiary_content_margin),
		corners_ = corner_radius(tertiary_corner_radius),
		bg_color = background_color
	})
	
	define_style("Label", {
		font_color = primary_text_color,
		normal = stylebox_empty({})
	})
	
	define_variant_style("Label_Secondary", "Label", {
		font_color = secondary_text_color
	})
	
	define_variant_style("Label_NodeValue", "Label", {
		font_color = secondary_text_color,
		normal = node_value_style
	})
#endregion

#region MarginContainer
	define_style("MarginContainer", {
		margin_bottom = primary_content_margin,
		margin_left = primary_content_margin,
		margin_right = primary_content_margin,
		margin_top = primary_content_margin
	})
	define_variant_style("MarginContainer_Medium", "MarginContainer", {
		margin_bottom = secondary_content_margin,
		margin_left = secondary_content_margin,
		margin_right = secondary_content_margin,
		margin_top = secondary_content_margin
	})
	define_variant_style("MarginContainer_Small", "MarginContainer", {
		margin_bottom = tertiary_content_margin,
		margin_left = tertiary_content_margin,
		margin_right = tertiary_content_margin,
		margin_top = tertiary_content_margin
	})
#endregion
	
#region Panel/PanelContainer
	var background_colors := [primary_color, secondary_color]
	var background_colors_label := ["Primary", "Secondary"]
	var margins := [0, primary_content_margin, secondary_content_margin, tertiary_content_margin]
	var corners := [0, primary_corner_radius, secondary_corner_radius, tertiary_corner_radius]
	
	define_style("Panel", { panel = general_normal_stylebox })
	define_style("PanelContainer", { panel = general_normal_stylebox })
	
	for color in background_colors:
		var bg_index: int = background_colors.find(color)
		var bg_panel_style = stylebox_flat({ bg_color = color })
		
		for margin in margins:
			var margin_index: int = margins.find(margin)
			var shape_panel_style = stylebox_flat({
				corners_ = corner_radius(corners[margin_index]),
				margins_ = content_margins(margin)
			})
			
			var variant_name: String = "%s_Corner%s" % [background_colors_label[bg_index],  margin]
			var variant_panel: Dictionary = inherit(bg_panel_style, shape_panel_style)
			
			define_variant_style("Panel_%s" % variant_name, "Panel", { panel = variant_panel })
			define_variant_style("PanelContainer_%s" % variant_name, "PanelContainer", { panel = variant_panel })
			
			define_variant_style("Panel_%s_Outline" % variant_name, "Panel", {
				panel = inherit(variant_panel, base_border_stylebox)
			})
			define_variant_style("PanelContainer_%s_Outline" % variant_name, "PanelContainer", {
				panel = inherit(variant_panel, base_border_stylebox)
			})
	
	var side_panel_style: Dictionary = stylebox_flat({
		bg_color = primary_color,
		borders_ = border_width(default_border_width, 0, 0, 0),
		corners_ = corner_radius(0),
		margins_ = content_margins(secondary_content_margin)
	})
	
	define_variant_style("PanelContainer_SidePanel", "PanelContainer", {
		panel = inherit(base_border_stylebox, side_panel_style)
	})
#endregion
	
#region PopupMenu style
	var popupmenu_style = inherit(general_normal_stylebox, base_border_stylebox, stylebox_flat({
		corners_ = corner_radius(secondary_corner_radius)
	}))
	
	define_style("PopupMenu", {
		h_separation = secondary_content_margin,
		icon_max_width = 14,
		item_end_padding = secondary_content_margin,
		item_start_padding = secondary_content_margin,
		v_separation = 4,
		font_size = 16,
		#title_font_size = 18,
		hover = inherit(general_normal_stylebox, stylebox_flat({
			corners_ = corner_radius(tertiary_content_margin),
			bg_color = tertiary_color
		})),
		panel = popupmenu_style,
		separator = inherit(separator_style, stylebox_flat({ vertical = true }))
	})
#endregion
	
	var box_containers := ["HBoxContainer", "VBoxContainer"]
	
	for box_container in box_containers:
		define_style(box_container, { separation = 0 })
		define_variant_style("%s_Big" % box_container, box_container, { separation = primary_content_margin })
		define_variant_style("%s_Medium" % box_container, box_container, { separation = secondary_content_margin })
		define_variant_style("%s_Small" % box_container, box_container, { separation = tertiary_content_margin })
	

	_scroll_bar_builder("HScrollBar")
	_scroll_bar_builder("HScrollBar", "Left")
	_scroll_bar_builder("VScrollBar")
	_scroll_bar_builder("VScrollBar", "Top")

	
#region TabBar style
	var hovered_tab: Dictionary = stylebox_flat({ bg_color = tertiary_color })
	var selected_tab: Dictionary = stylebox_flat({ bg_color = accent_color })
	var unselected_tab: Dictionary = stylebox_flat({ draw_center = false })
	
	var tab_bar_style: Dictionary = stylebox_flat({
		bg_color = secondary_color,
		borders_ = border_width(0, 0, default_border_width, 0),
		border_color = border_color,
		margins_ = content_margins(secondary_content_margin, tertiary_content_margin)
	})
	
	define_style("TabBar", {
		font_hovered_color = primary_text_color,
		font_selected_color = primary_text_color,
		font_unselected_color = secondary_text_color,
		h_separation = tertiary_content_margin,
		font_size = 14,
		close = preload("res://ui/assets/icons/cross.svg"),
		button_highlight = stylebox_empty({}),
		button_pressed = stylebox_empty({}),
		tab_disabled = stylebox_empty({}),
		tab_focus = stylebox_empty({}),
		tab_hovered = inherit(tab_bar_style, hovered_tab),
		tab_selected = inherit(tab_bar_style, selected_tab),
		tab_unselected = inherit(tab_bar_style, unselected_tab)
	})
#endregion
	
	var field_edit_style: Dictionary = stylebox_flat({
		margins_ = content_margins(tertiary_content_margin),
		corners_ = corner_radius(tertiary_corner_radius),
		bg_color = background_color
	})
	
	define_style("TextEdit", {
		focus = inherit(field_edit_style, base_border_stylebox),
		normal = field_edit_style
	})
	
	define_style("LineEdit", {
		focus = inherit(field_edit_style, base_border_stylebox),
		normal = field_edit_style
	})
	
#region Tree style
	var tree_panel: Dictionary = stylebox_flat({
		bg_color = background_color,
		border_color = border_color,
		borders_ = border_width(default_border_width),
		corners_ = corner_radius(tertiary_content_margin)
	})
	
	define_style("Tree", {
		children_hl_line_color = primary_text_color_02,
		custom_button_font_highlight = primary_text_color_40,
		font_color = primary_text_color,
		parent_hl_line_color = primary_text_color_40,
		relationship_line_color = primary_text_color_02,
		children_hl_line_width = 1,
		draw_guides = 0,
		draw_relationship_lines = 1,
		h_separation = secondary_content_margin,
		inner_item_margin_left = 1,
		inner_item_margin_right = 1,
		parent_hl_line_margin = 0,
		font_size = 18,
		title_button_font_size = 16,
		panel = tree_panel,
		focus = inherit(tree_panel, { draw_center = false })
	})
#endregion


func _button_style_builder(style, node_type, variant_name: String = "") -> void:
	var main_style: Dictionary = {
		normal = style,
		hover = inherit(style, hover_button),
		pressed = inherit(style, pressed_button),
		focus = inherit(style, hover_button)
	}
	if variant_name == "":
		define_style(node_type, main_style)
	else:
		define_variant_style("%s%s" % [node_type, variant_name], node_type, main_style)
		
	define_variant_style("%s_Flat%s" % [node_type, variant_name], node_type, {
		normal = inherit(style, empty_button),
		hover = inherit(style, hover_button),
		pressed = inherit(style, pressed_button),
		focus = inherit(style, hover_button)
	})
	define_variant_style("%s_Outline%s" % [node_type, variant_name], node_type, {
		normal = inherit(empty_button, base_border_stylebox, style),
		hover = inherit(empty_button, base_border_stylebox, style),
		pressed = inherit(style, hover_button),
		focus = inherit(empty_button, base_border_stylebox, style)
	})


func _scroll_bar_builder(node_type, variant_name: String = "") -> void:
	var grabber_style: Dictionary = stylebox_flat({
		bg_color = tertiary_color,
		corner_ = corner_radius(secondary_corner_radius)
	})
	var scroll_style: Dictionary = stylebox_flat({
		draw_center = true,
		bg_color = secondary_color,
		border_color = border_color,
		margins_ = content_margins(3),
		expand_ = expand_margins(3),
		corner_ = corner_radius(secondary_corner_radius)
	})
	
	var scroll_bar_style: Dictionary = {
		grabber = grabber_style,
		grabber_highlight = grabber_style,
		grabber_pressed = grabber_style,
		scroll = scroll_style,
		scroll_focus = scroll_style
	}
		
	if variant_name == "":
		define_style(node_type, scroll_bar_style)
	else:
		define_variant_style("%s_%s" % [node_type,  variant_name], node_type, scroll_bar_style)


func request_stylebox() -> StyleBox:
	return StyleBoxEmpty.new()
