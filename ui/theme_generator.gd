@tool
class_name MonologueThemeGenerator extends ProgrammaticTheme


var PRIMARY_COLOR := Color("313136")
var SECONDARY_COLOR := Color("36363c")
var TERTIARY_COLOR := Color("46464d")
var PRIMARY_TEXT_COLOR := Color("ffffff")
var PRIMARY_TEXT_COLOR_02 := Color("ffffff05")
var PRIMARY_TEXT_COLOR_40 := Color("ffffff64")
var SECONDARY_TEXT_COLOR := Color("b3b3b3")
var ACCENT_COLOR := Color("d55160")
var ERROR_COLOR := Color("c42e40")
var BACKGROUND_COLOR := Color("1e1e21")
var BORDER_COLOR := TERTIARY_COLOR

var DEFAULT_BORDER_WIDTH := 1
var PRIMARY_CORNER_RADIUS := 30
var SECONDARY_CORNER_RADIUS := 15
var TERTIARY_CORNER_RADIUS := 5
var PRIMARY_CONTENT_MARGIN := 20
var SECONDARY_CONTENT_MARGIN := 10
var TERTIARY_CONTENT_MARGIN := 5

# Base styleboxes
var GENERAL_NORMAL_STYLEBOX: Dictionary = stylebox_flat({
	bg_color = PRIMARY_COLOR,
	corners_ = corner_radius(SECONDARY_CORNER_RADIUS),
	font_color = PRIMARY_TEXT_COLOR,
	margins_ = content_margins(SECONDARY_CONTENT_MARGIN)
})
var BASE_BORDER_STYLEBOX: Dictionary = stylebox_flat({
	borders_ = border_width(DEFAULT_BORDER_WIDTH),
	border_color = BORDER_COLOR,
})
var SEPARATOR_STYLE: Dictionary = stylebox_line({
	color = BORDER_COLOR,
	grow_begin = 0,
	grow_end = 0,
	thickness = 1,
})

# Button states
var HOVER_BUTTON := { bg_color = TERTIARY_COLOR }
var PRESSED_BUTTON := { bg_color = TERTIARY_COLOR }
var EMPTY_BUTTON := { draw_center = false }
var ACCENT_BUTTON := { bg_color = ACCENT_COLOR }
var ERROR_BUTTON := { border_color = ERROR_COLOR, borders_ = border_width(DEFAULT_BORDER_WIDTH) }


func setup() -> void:
	set_save_path("res://ui/theme_default/main.tres")

func define_theme() -> void:
	define_button()
	define_check_box()
	define_graph_edit()
	define_graph_node()
	define_separator()
	define_label()
	define_margin_container()
	define_panel()
	define_popup_menu()
	define_box_container()
	define_scroll_bar()
	define_tab_bar()
	define_field_edit()
	define_tree()

# Button, OptionButton and MenuButton
func define_button() -> void:
	var button_style = stylebox_flat({
		bg_color = SECONDARY_COLOR,
		corners_ = corner_radius(TERTIARY_CORNER_RADIUS),
		margins_ = content_margins(SECONDARY_CONTENT_MARGIN, TERTIARY_CONTENT_MARGIN)
	})
	var button_style_no_corner = inherit(button_style, { corners_ = corner_radius(0) })

	for node_type in ["Button", "OptionButton", "MenuButton"]:
		_button_style_builder(button_style, node_type)
		_button_style_builder(button_style_no_corner, node_type, "_NoCorner")

	var accent_button_style = inherit(button_style, ACCENT_BUTTON)
	define_variant_style("Button_Accent", "Button", {
		normal = accent_button_style,
		hover = accent_button_style,
		pressed = accent_button_style,
		focus = accent_button_style
	})

	_button_style_builder(inherit(button_style, ERROR_BUTTON), "OptionButton", "_Error")
	_button_style_builder(inherit(button_style, ERROR_BUTTON), "OptionButton", "_NoCorner_Error")

# CheckBox and CheckButton
func define_check_box() -> void:
	var check_style = {
		normal = stylebox_empty({}),
		hover = stylebox_empty({}),
		pressed = stylebox_empty({}),
		focus = stylebox_empty({})
	}

	define_style("CheckBox", inherit(check_style, {
		h_separation = TERTIARY_CONTENT_MARGIN,
		checked = preload("res://ui/assets/icons/check.svg"),
		unchecked = ImageTexture.new()
	}))

	define_style("CheckButton", inherit(check_style, {
		checked = preload("res://ui/assets/icons/toggle_on.svg"),
		unchecked = preload("res://ui/assets/icons/toggle_off.svg")
	}))

# GraphEdit
func define_graph_edit() -> void:
	var graph_edit_panel = stylebox_flat({ bg_color = BACKGROUND_COLOR })

	define_style("GraphEdit", {
		grid_major = Color("ffffff0d"),
		grid_minor = Color("ffffff0d"),
		panel = graph_edit_panel
	})

# GraphNode and GraphNodeTitleLabel
func define_graph_node() -> void:
	var selected_graph_node = { border_color = Color("fff") }

	var graph_node_panel_style = stylebox_flat({
		bg_color = PRIMARY_COLOR,
		corners_ = corner_radius(0, 0, TERTIARY_CORNER_RADIUS, TERTIARY_CORNER_RADIUS),
		margins_ = content_margins(PRIMARY_CONTENT_MARGIN, PRIMARY_CONTENT_MARGIN, PRIMARY_CONTENT_MARGIN, PRIMARY_CONTENT_MARGIN)
	})
	var selected_graph_node_panel_style = inherit(graph_node_panel_style, selected_graph_node, stylebox_flat({
		border_ = border_width(1, 0, 1, 1)
	}))
	var graph_node_titlebar_style = stylebox_flat({
		corners_ = corner_radius(TERTIARY_CORNER_RADIUS, TERTIARY_CORNER_RADIUS, 0, 0),
		margins_ = content_margins(PRIMARY_CONTENT_MARGIN, TERTIARY_CONTENT_MARGIN, PRIMARY_CONTENT_MARGIN, TERTIARY_CONTENT_MARGIN)
	})
	var selected_graph_node_titlebar_style = inherit(graph_node_titlebar_style, selected_graph_node, stylebox_flat({
		border_ = border_width(1, 1, 1, 0)
	}))

	define_style("GraphNode", {
		separation = TERTIARY_CONTENT_MARGIN,
		port = preload("res://ui/assets/icons/slot.svg"),
		panel = graph_node_panel_style,
		panel_selected = selected_graph_node_panel_style,
		slot = stylebox_empty({}),
		titlebar = graph_node_titlebar_style,
		titlebar_selected = selected_graph_node_titlebar_style
	})

	define_style("GraphNodeTitleLabel", {
		font = preload("res://ui/assets/fonts/NotoSans-SemiBold.ttf"),
		normal = stylebox_empty({})
	})

# HSeparator and VSeparator
func define_separator() -> void:
	for separator_type in ["HSeparator", "VSeparator"]:
		var separator_type_style = inherit(SEPARATOR_STYLE, stylebox_line({
			vertical = separator_type == "VSeparator"
		}))
		define_style(separator_type, {
			separation = 1,
			separator = separator_type_style
		})

		for margin in [PRIMARY_CONTENT_MARGIN, SECONDARY_CONTENT_MARGIN, TERTIARY_CONTENT_MARGIN]:
			var variant_separator = { grow_begin = margin, grow_end = margin }

			define_variant_style("%s_Grow%s" % [separator_type, margin], separator_type, {
				separation = 1,
				separator = inherit(separator_type_style, variant_separator)
			})

# Label
func define_label() -> void:
	var node_value_style = stylebox_flat({
		margins_ = content_margins(TERTIARY_CONTENT_MARGIN),
		corners_ = corner_radius(TERTIARY_CORNER_RADIUS),
		bg_color = BACKGROUND_COLOR
	})

	define_style("Label", {
		font_color = PRIMARY_TEXT_COLOR,
		normal = stylebox_empty({})
	})

	define_variant_style("Label_Secondary", "Label", {
		font_color = SECONDARY_TEXT_COLOR
	})

	define_variant_style("Label_NodeValue", "Label", {
		font_color = SECONDARY_TEXT_COLOR,
		normal = node_value_style
	})

# MarginContainer
func define_margin_container() -> void:
	define_style("MarginContainer", {
		margin_bottom = PRIMARY_CONTENT_MARGIN,
		margin_left = PRIMARY_CONTENT_MARGIN,
		margin_right = PRIMARY_CONTENT_MARGIN,
		margin_top = PRIMARY_CONTENT_MARGIN
	})
	define_variant_style("MarginContainer_Medium", "MarginContainer", {
		margin_bottom = SECONDARY_CONTENT_MARGIN,
		margin_left = SECONDARY_CONTENT_MARGIN,
		margin_right = SECONDARY_CONTENT_MARGIN,
		margin_top = SECONDARY_CONTENT_MARGIN
	})
	define_variant_style("MarginContainer_Small", "MarginContainer", {
		margin_bottom = TERTIARY_CONTENT_MARGIN,
		margin_left = TERTIARY_CONTENT_MARGIN,
		margin_right = TERTIARY_CONTENT_MARGIN,
		margin_top = TERTIARY_CONTENT_MARGIN
	})

# Panel and PanelContainer
func define_panel() -> void:
	var background_colors = [PRIMARY_COLOR, SECONDARY_COLOR]
	var background_colors_label = ["Primary", "Secondary"]
	var margins = [0, PRIMARY_CONTENT_MARGIN, SECONDARY_CONTENT_MARGIN, TERTIARY_CONTENT_MARGIN]
	var corners = [0, PRIMARY_CORNER_RADIUS, SECONDARY_CORNER_RADIUS, TERTIARY_CORNER_RADIUS]

	define_style("Panel", { panel = GENERAL_NORMAL_STYLEBOX })
	define_style("PanelContainer", { panel = GENERAL_NORMAL_STYLEBOX })

	for color in background_colors:
		var bg_index = background_colors.find(color)
		var bg_panel_style = stylebox_flat({ bg_color = color })

		for margin in margins:
			var margin_index = margins.find(margin)
			var shape_panel_style = stylebox_flat({
				corners_ = corner_radius(corners[margin_index]),
				margins_ = content_margins(margin)
			})

			var variant_name = "%s_Corner%s" % [background_colors_label[bg_index],  margin]
			var variant_panel = inherit(bg_panel_style, shape_panel_style)

			define_variant_style("Panel_%s" % variant_name, "Panel", { panel = variant_panel })
			define_variant_style("PanelContainer_%s" % variant_name, "PanelContainer", { panel = variant_panel })

			define_variant_style("Panel_%s_Outline" % variant_name, "Panel", {
				panel = inherit(variant_panel, BASE_BORDER_STYLEBOX)
			})
			define_variant_style("PanelContainer_%s_Outline" % variant_name, "PanelContainer", {
				panel = inherit(variant_panel, BASE_BORDER_STYLEBOX)
			})

	var side_panel_style = stylebox_flat({
		bg_color = PRIMARY_COLOR,
		borders_ = border_width(DEFAULT_BORDER_WIDTH, 0, 0, 0),
		corners_ = corner_radius(0),
		margins_ = content_margins(SECONDARY_CONTENT_MARGIN)
	})

	define_variant_style("PanelContainer_SidePanel", "PanelContainer", {
		panel = inherit(BASE_BORDER_STYLEBOX, side_panel_style)
	})

# PopupMenu
func define_popup_menu() -> void:
	var popupmenu_style = inherit(GENERAL_NORMAL_STYLEBOX, BASE_BORDER_STYLEBOX, stylebox_flat({
		corners_ = corner_radius(TERTIARY_CONTENT_MARGIN)
	}))

	define_style("PopupMenu", {
		h_separation = SECONDARY_CONTENT_MARGIN,
		icon_max_width = 14,
		item_end_padding = SECONDARY_CONTENT_MARGIN,
		item_start_padding = SECONDARY_CONTENT_MARGIN,
		v_separation = 4,
		font_size = 16,
		hover = inherit(GENERAL_NORMAL_STYLEBOX, stylebox_flat({
			corners_ = corner_radius(TERTIARY_CONTENT_MARGIN),
			bg_color = TERTIARY_COLOR
		})),
		panel = popupmenu_style,
		separator = inherit(SEPARATOR_STYLE, stylebox_flat({ vertical = true }))
	})

# HBoxContainer and VBoxContainer
func define_box_container() -> void:
	var box_containers = ["HBoxContainer", "VBoxContainer"]

	for box_container in box_containers:
		define_style(box_container, { separation = 0 })
		define_variant_style("%s_Big" % box_container, box_container, { separation = PRIMARY_CONTENT_MARGIN })
		define_variant_style("%s_Medium" % box_container, box_container, { separation = SECONDARY_CONTENT_MARGIN })
		define_variant_style("%s_Small" % box_container, box_container, { separation = TERTIARY_CONTENT_MARGIN })

# HScrollBar and VScrollBar
func define_scroll_bar() -> void:
	_scroll_bar_builder("HScrollBar")
	_scroll_bar_builder("HScrollBar", "Left")
	_scroll_bar_builder("VScrollBar")
	_scroll_bar_builder("VScrollBar", "Top")

# TabBar
func define_tab_bar() -> void:
	var hovered_tab = stylebox_flat({ bg_color = TERTIARY_COLOR })
	var selected_tab = stylebox_flat({ bg_color = ACCENT_COLOR })
	var unselected_tab = stylebox_flat({ draw_center = false })

	var tab_bar_style = stylebox_flat({
		bg_color = SECONDARY_COLOR,
		borders_ = border_width(0, 0, DEFAULT_BORDER_WIDTH, 0),
		border_color = BORDER_COLOR,
		margins_ = content_margins(SECONDARY_CONTENT_MARGIN, TERTIARY_CONTENT_MARGIN)
	})

	define_style("TabBar", {
		font_hovered_color = PRIMARY_TEXT_COLOR,
		font_selected_color = PRIMARY_TEXT_COLOR,
		font_unselected_color = SECONDARY_TEXT_COLOR,
		h_separation = TERTIARY_CONTENT_MARGIN,
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

# TextEdit and LineEdit
func define_field_edit() -> void:
	var field_edit_style = stylebox_flat({
		margins_ = content_margins(TERTIARY_CONTENT_MARGIN),
		corners_ = corner_radius(TERTIARY_CORNER_RADIUS),
		bg_color = BACKGROUND_COLOR
	})

	define_style("TextEdit", {
		focus = inherit(field_edit_style, BASE_BORDER_STYLEBOX),
		normal = field_edit_style
	})

	define_style("LineEdit", {
		focus = inherit(field_edit_style, BASE_BORDER_STYLEBOX),
		normal = field_edit_style
	})
	define_variant_style("LineEdit_Flat", "LineEdit", {
		focus = inherit(field_edit_style, { draw_center = false }),
		normal = inherit(field_edit_style, { draw_center = false }),
	})

# Tree
func define_tree() -> void:
	var tree_panel = stylebox_flat({
		bg_color = BACKGROUND_COLOR,
		border_color = BORDER_COLOR,
		borders_ = border_width(DEFAULT_BORDER_WIDTH),
		corners_ = corner_radius(TERTIARY_CONTENT_MARGIN)
	})

	define_style("Tree", {
		children_hl_line_color = PRIMARY_TEXT_COLOR_02,
		custom_button_font_highlight = PRIMARY_TEXT_COLOR_40,
		font_color = PRIMARY_TEXT_COLOR,
		parent_hl_line_color = PRIMARY_TEXT_COLOR_40,
		relationship_line_color = PRIMARY_TEXT_COLOR_02,
		children_hl_line_width = 1,
		draw_guides = 0,
		draw_relationship_lines = 1,
		h_separation = SECONDARY_CONTENT_MARGIN,
		inner_item_margin_left = 1,
		inner_item_margin_right = 1,
		parent_hl_line_margin = 0,
		font_size = 18,
		title_button_font_size = 16,
		panel = tree_panel,
		focus = inherit(tree_panel, { draw_center = false })
	})

func _button_style_builder(style, node_type, variant_name: String = "") -> void:
	var main_style = {
		normal = style,
		hover = inherit(style, HOVER_BUTTON),
		pressed = inherit(style, PRESSED_BUTTON),
		focus = inherit(style, HOVER_BUTTON)
	}
	if variant_name == "":
		define_style(node_type, main_style)
	else:
		define_variant_style("%s%s" % [node_type, variant_name], node_type, main_style)

	define_variant_style("%s_Flat%s" % [node_type, variant_name], node_type, {
		normal = inherit(style, EMPTY_BUTTON),
		hover = inherit(style, HOVER_BUTTON),
		pressed = inherit(style, PRESSED_BUTTON),
		focus = inherit(style, HOVER_BUTTON)
	})
	define_variant_style("%s_Outline%s" % [node_type, variant_name], node_type, {
		normal = inherit(EMPTY_BUTTON, BASE_BORDER_STYLEBOX, style),
		hover = inherit(EMPTY_BUTTON, BASE_BORDER_STYLEBOX, style),
		pressed = inherit(style, HOVER_BUTTON),
		focus = inherit(EMPTY_BUTTON, BASE_BORDER_STYLEBOX, style)
	})

func _scroll_bar_builder(node_type, variant_name: String = "") -> void:
	var grabber_style = stylebox_flat({
		bg_color = TERTIARY_COLOR,
		corner_ = corner_radius(SECONDARY_CORNER_RADIUS)
	})
	var scroll_style = stylebox_flat({
		draw_center = true,
		bg_color = SECONDARY_COLOR,
		border_color = BORDER_COLOR,
		margins_ = content_margins(3),
		expand_ = expand_margins(3),
		corner_ = corner_radius(SECONDARY_CORNER_RADIUS)
	})

	var scroll_bar_style = {
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
