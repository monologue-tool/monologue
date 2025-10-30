## Custom theme for the Monologue editor.
##
## Defines a comprehensive dark theme with consistent styling across all
## UI controls. Includes colors, styleboxes, fonts, and constants for
## buttons, panels, inputs, graphs, and more.
@tool
class_name MonologueTheme extends Theme

## UI scale factor for high-DPI displays.
var scale: float = 1.0

## Whether to use dark theme colors.
var dark_theme: bool = true

## Contrast level for color variations.
var contrast: float = 0.15

# Color palette
## Default text color.
var text_color: Color = Color("e3e4eb")

## Background color for the editor.
var background_color: Color = Color(0.097, 0.097, 0.12, 1.0)

## Primary UI element color.
var primary_color: Color = Color("a9a8c0")

## Secondary UI element color.
var secondary_color: Color = Color("676278")

## Accent color for highlights and selections.
var accent_color: Color = Color("d15050")

## Warning/error color.
var warn_color: Color = Color("c42e40")

# Layout constants
## Base spacing unit in pixels.
var base_spacing: int = 4

## Corner radius for rounded UI elements.
var corner_radius: int = 3

## Opacity for graph relationship lines.
var relationship_line_opacity: float = 0.2

## Default border width.
var border_width: int = 1

## Base font size.
var base_font_size: int = 14


## Initializes the theme and generates all UI styles.
func _init() -> void:
	scale = 1.0
	var _use_high_ppi: bool = scale >= 1.0

	_generate_theme()


## Generates all theme styleboxes, colors, fonts, and constants.
##
## Creates a comprehensive theme by defining styles for all UI controls
## including buttons, panels, inputs, graphs, and more.
func _generate_theme() -> void:
	# -----------------------
	# Globals / base helpers
	# -----------------------
	# Base margins, colors and common derived values
	var base_margin: float = base_spacing
	var base_border_color: Color = _get_text_color(0.2)
	var outer_radius: float = base_spacing + corner_radius

	# --- Base StyleBoxes (shared across many controls) ---
	# base_sb: main rounded panel / container look
	var base_sb: StyleBoxFlat = StyleBoxFlat.new()
	base_sb.bg_color = background_color
	base_sb.set_content_margin_all(base_margin)
	base_sb.set_corner_radius_all(int(corner_radius))
	base_sb.border_color = base_border_color

	# base_empty_sb: same but no center draw (useful for focusless plates)
	var base_empty_sb: StyleBoxFlat = base_sb.duplicate()
	base_empty_sb.draw_center = false

	# base_field_sb: input-like controls background (LineEdit, etc.)
	var base_field_sb: StyleBoxFlat = base_sb.duplicate()
	base_field_sb.content_margin_left = base_spacing * 2.0
	base_field_sb.content_margin_right = base_spacing * 2.0
	base_field_sb.bg_color = _get_secondary_color(contrast)

	# base_panel_sb: panels that should look like "primary" surface
	var base_panel_sb: StyleBoxFlat = base_sb.duplicate()
	base_panel_sb.bg_color = _get_primary_color(contrast, false)

	# -----------------------
	# BUTTON FAMILY (shared)
	# -----------------------
	# Create a grouped set of styleboxes for regular buttons.
	# Buttons share margins, radii; only colors differ (primary/accent/warn/flat)
	var button_sb: StyleBoxFlat = base_sb.duplicate()
	button_sb.bg_color = _get_primary_color(contrast)
	button_sb.content_margin_left = base_margin * 2.0
	button_sb.content_margin_top = base_margin
	button_sb.content_margin_right = base_margin * 2.0
	button_sb.content_margin_bottom = base_margin

	var button_hover_sb: StyleBoxFlat = button_sb.duplicate()
	button_hover_sb.bg_color = _get_primary_color(contrast + 0.05)

	var button_pressed_sb: StyleBoxFlat = button_sb.duplicate()
	button_pressed_sb.bg_color = _get_primary_color(contrast + 0.1)

	var button_disabled_sb: StyleBoxFlat = button_sb.duplicate()
	button_disabled_sb.bg_color = _get_primary_color(0.05)

	# Flat button uses border with transparent background
	var flat_button_sb: StyleBoxFlat = base_sb.duplicate()
	flat_button_sb.bg_color = Color.TRANSPARENT
	flat_button_sb.set_border_width_all(border_width)
	_set_border(flat_button_sb, _get_text_color(contrast))

	var flat_button_hover_sb: StyleBoxFlat = flat_button_sb.duplicate()
	flat_button_hover_sb.bg_color = _get_primary_color(0.1)
	_set_border(flat_button_hover_sb, _get_text_color(contrast + 0.05))

	var flat_button_pressed_sb: StyleBoxFlat = flat_button_sb.duplicate()
	flat_button_pressed_sb.bg_color = _get_primary_color(contrast / 2)
	_set_border(flat_button_pressed_sb, _get_text_color(contrast + 0.1))

	# Accent and warning variants: reuse button shape, only swap colors
	var button_accent_base_sb: StyleBoxFlat = button_sb.duplicate()
	button_accent_base_sb.bg_color = accent_color

	var delete_button_sb: StyleBoxFlat = button_sb.duplicate()
	delete_button_sb.bg_color = _get_color(warn_color, contrast)

	var delete_button_hover_sb: StyleBoxFlat = button_sb.duplicate()
	delete_button_hover_sb.bg_color = _get_color(warn_color, contrast + 0.05)

	var delete_button_pressed_sb: StyleBoxFlat = button_sb.duplicate()
	delete_button_pressed_sb.bg_color = _get_color(warn_color, contrast + 0.1)

	var delete_button_disabled_sb: StyleBoxFlat = button_sb.duplicate()
	delete_button_disabled_sb.bg_color = _get_color(warn_color, 0.05)

	# -----------------------
	# CHECK / TOGGLE FAMILY
	# -----------------------
	# Simple box style used for CheckBox/CheckButton toggles (we mostly rely on icons)
	var check_box_sb: StyleBoxFlat = base_empty_sb.duplicate()
	check_box_sb.set_content_margin_all(0)

	var check_box_hover_sb: StyleBoxFlat = check_box_sb.duplicate()
	# intentionally left bg transparent; icons express state

	var check_box_pressed_sb: StyleBoxFlat = check_box_sb.duplicate()

	var check_box_disabled_sb: StyleBoxFlat = check_box_sb.duplicate()

	# -----------------------
	# INPUT / FIELD FAMILY
	# -----------------------
	# Use one base for LineEdit/TextEdit/SpinBox lines then tweak per-case.
	var line_edit_sb: StyleBoxFlat = base_field_sb.duplicate()

	var line_edit_focus_sb: StyleBoxFlat = line_edit_sb.duplicate()
	line_edit_focus_sb.draw_center = false
	line_edit_focus_sb.set_border_width_all(1)

	var line_edit_disabled_sb: StyleBoxFlat = line_edit_sb.duplicate()
	line_edit_disabled_sb.bg_color = _get_primary_color(0.05)

	# Spinner/SpinBox left/right button shapes reuse small base
	var spin_box_button_sb: StyleBoxFlat = base_empty_sb.duplicate()
	spin_box_button_sb.set_content_margin_all(base_spacing / 2)

	var spin_box_button_pressed_sb: StyleBoxFlat = base_sb.duplicate()
	spin_box_button_pressed_sb.set_content_margin_all(base_spacing / 2)
	spin_box_button_pressed_sb.bg_color = _get_primary_color(contrast)

	# -----------------------
	# PANEL / CONTAINER FAMILY
	# -----------------------
	# Panels share base_panel_sb or base_sb depending on intent
	var panel_primary_sb: StyleBoxFlat = base_sb.duplicate()
	panel_primary_sb.bg_color = _get_primary_color(contrast, false)

	var panel_secondary_sb: StyleBoxFlat = base_sb.duplicate()
	panel_secondary_sb.bg_color = _get_secondary_color(contrast, false)

	# -----------------------
	# SEPARATOR / LINE FAMILY
	# -----------------------
	var separator_sb: StyleBoxLine = StyleBoxLine.new()
	separator_sb.color = base_border_color
	separator_sb.vertical = false
	separator_sb.grow_begin = 0
	separator_sb.grow_end = 0

	# dotted separator (texture)
	var dotted_sb: StyleBoxTexture = StyleBoxTexture.new()
	dotted_sb.texture = preload("res://ui/theme_default/assets/dash.svg")
	dotted_sb.modulate_color = base_border_color
	dotted_sb.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT
	dotted_sb.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT
	dotted_sb.texture_margin_top = 1

	# -----------------------
	# SCROLLBAR / SLIDERS
	# -----------------------
	var _inspector_panel_bg_color: Color = _get_primary_color(contrast, false)
	var _scroll_bar_color: Color = _get_color(
		base_border_color, base_border_color.a, false, _inspector_panel_bg_color
	)

	var scroll_sb: StyleBoxFlat = base_empty_sb.duplicate()
	scroll_sb.border_color = _scroll_bar_color
	scroll_sb.set_content_margin_all(2)
	scroll_sb.set_corner_radius_all(0)

	var scroll_focus_sb: StyleBoxFlat = scroll_sb.duplicate()
	scroll_focus_sb.draw_center = true

	var grabber_sb: StyleBoxFlat = base_sb.duplicate()
	grabber_sb.set_corner_radius_all(5)
	grabber_sb.bg_color = _scroll_bar_color

	# slider area
	var slider_sb: StyleBoxFlat = StyleBoxFlat.new()
	slider_sb.content_margin_top = 5
	slider_sb.set_corner_radius_all(5)
	slider_sb.bg_color = _get_primary_color(contrast)

	var grabber_area: StyleBoxFlat = slider_sb.duplicate()
	grabber_area.bg_color = accent_color

	# -----------------------
	# GRAPH / NODE STYLES
	# -----------------------
	var graph_node_sb: StyleBoxFlat = button_sb.duplicate()
	graph_node_sb.bg_color = _get_primary_color(contrast, false)
	graph_node_sb.shadow_color = Color("#000000", contrast)
	graph_node_sb.shadow_size = 10
	_set_border(graph_node_sb, base_border_color)

	var graph_node_selected_sb: StyleBoxFlat = graph_node_sb.duplicate()
	graph_node_selected_sb.border_color.a += 0.1

	var graph_node_titlebar_sb: StyleBoxEmpty = StyleBoxEmpty.new()
	var graph_node_titlebar_selected_sb: StyleBoxEmpty = graph_node_titlebar_sb.duplicate()

	# -----------------------
	# APPLY STYLES: Buttons
	# -----------------------
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
	set_constant("icon_max_width", "Button", 15)
	set_constant("h_separation", "Button", base_spacing)
	set_stylebox("disabled", "Button", button_disabled_sb)
	set_stylebox("disabled_mirrored", "Button", button_disabled_sb)
	set_stylebox("focus", "Button", base_empty_sb)
	set_stylebox("hover", "Button", button_hover_sb)
	set_stylebox("hover_mirrored", "Button", button_hover_sb)
	set_stylebox("hover_pressed", "Button", button_pressed_sb)
	set_stylebox("hover_pressed_mirrored", "Button", button_pressed_sb)
	set_stylebox("normal", "Button", button_sb)
	set_stylebox("normal_mirrored", "Button", button_sb)
	set_stylebox("pressed", "Button", button_pressed_sb)
	set_stylebox("pressed_mirrored", "Button", button_pressed_sb)

	# ButtonAccent (variation of Button)
	set_type_variation("ButtonAccent", "Button")
	set_stylebox("disabled", "ButtonAccent", button_accent_base_sb)
	set_stylebox("disabled_mirrored", "ButtonAccent", button_accent_base_sb)
	set_stylebox("focus", "ButtonAccent", button_accent_base_sb)
	set_stylebox("hover", "ButtonAccent", button_accent_base_sb)
	set_stylebox("hover_mirrored", "ButtonAccent", button_accent_base_sb)
	set_stylebox("hover_pressed", "ButtonAccent", button_accent_base_sb)
	set_stylebox("hover_pressed_mirrored", "ButtonAccent", button_accent_base_sb)
	set_stylebox("normal", "ButtonAccent", button_accent_base_sb)
	set_stylebox("normal_mirrored", "ButtonAccent", button_accent_base_sb)
	set_stylebox("pressed", "ButtonAccent", button_accent_base_sb)
	set_stylebox("pressed_mirrored", "ButtonAccent", button_accent_base_sb)

	# ButtonWarning (variation of Button)
	set_type_variation("ButtonWarning", "Button")
	set_constant("outline_size", "ButtonWarning", 0)
	set_stylebox("disabled", "ButtonWarning", delete_button_disabled_sb)
	set_stylebox("disabled_mirrored", "ButtonWarning", delete_button_disabled_sb)
	set_stylebox("focus", "ButtonWarning", base_empty_sb)
	set_stylebox("hover", "ButtonWarning", delete_button_hover_sb)
	set_stylebox("hover_mirrored", "ButtonWarning", delete_button_hover_sb)
	set_stylebox("hover_pressed", "ButtonWarning", delete_button_pressed_sb)
	set_stylebox("hover_pressed_mirrored", "ButtonWarning", delete_button_pressed_sb)
	set_stylebox("normal", "ButtonWarning", delete_button_sb)
	set_stylebox("normal_mirrored", "ButtonWarning", delete_button_sb)
	set_stylebox("pressed", "ButtonWarning", delete_button_pressed_sb)
	set_stylebox("pressed_mirrored", "ButtonWarning", delete_button_pressed_sb)

	# FlatButton (uses flat_button_* family)
	set_color("font_color", "FlatButton", _get_text_color(0.8))
	set_color("font_disabled_color", "FlatButton", _get_text_color(0.3))
	set_color("font_focus_color", "FlatButton", text_color)
	set_color("font_hover_color", "FlatButton", text_color)
	set_color("font_hover_pressed_color", "FlatButton", text_color)
	set_color("font_pressed_color", "FlatButton", text_color)
	set_color("icon_disabled_color", "FlatButton", _get_text_color(0.3))
	set_color("icon_normal_color", "FlatButton", _get_text_color(0.8))
	set_constant("outline_size", "FlatButton", 0)
	set_stylebox("disabled", "FlatButton", button_disabled_sb)
	set_stylebox("disabled_mirrored", "FlatButton", button_disabled_sb)
	set_stylebox("normal", "FlatButton", flat_button_sb)
	set_stylebox("normal_mirrored", "FlatButton", flat_button_sb)
	set_stylebox("hover", "FlatButton", flat_button_hover_sb)
	set_stylebox("hover_mirrored", "FlatButton", flat_button_hover_sb)
	set_stylebox("hover_pressed", "FlatButton", flat_button_pressed_sb)
	set_stylebox("hover_pressed_mirrored", "FlatButton", flat_button_pressed_sb)
	set_stylebox("pressed", "FlatButton", flat_button_pressed_sb)
	set_stylebox("pressed_mirrored", "FlatButton", flat_button_pressed_sb)

	# -----------------------
	# CHECKBOX / CHECKBUTTON
	# -----------------------
	set_color("font_hover_pressed_color", "CheckBox", text_color)
	set_color("font_pressed_color", "CheckBox", _get_text_color(0.7))
	set_constant("h_separation", "CheckBox", int(base_margin))
	set_icon("checked", "CheckBox", preload("res://ui/theme_default/assets/checked.svg"))
	set_icon("unchecked", "CheckBox", preload("res://ui/theme_default/assets/unchecked.svg"))
	set_icon(
		"radio_checked", "CheckBox", preload("res://ui/theme_default/assets/radio_checked.svg")
	)
	set_icon(
		"radio_unchecked", "CheckBox", preload("res://ui/theme_default/assets/radio_unchecked.svg")
	)
	set_icon(
		"checked_disabled",
		"CheckBox",
		preload("res://ui/theme_default/assets/checked_disabled.svg")
	)
	set_icon(
		"unchecked_disabled",
		"CheckBox",
		preload("res://ui/theme_default/assets/unchecked_disabled.svg")
	)
	set_icon(
		"radio_checked_disabled",
		"CheckBox",
		preload("res://ui/theme_default/assets/radio_checked_disabled.svg")
	)
	set_icon(
		"radio_unchecked_disabled",
		"CheckBox",
		preload("res://ui/theme_default/assets/radio_unchecked_disabled.svg")
	)
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

	# CheckButton uses toggle icons
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

	# -----------------------
	# PANELS & EDITOR AREAS
	# -----------------------
	# CollapsibleFieldPanel
	set_type_variation("CollapsibleFieldPanel", "PanelContainer")
	var sb: StyleBoxFlat = base_sb.duplicate()
	sb.bg_color = _get_primary_color(contrast / 2)
	set_stylebox("panel", "CollapsibleFieldPanel", sb)

	# EditorBackground
	set_type_variation("EditorBackground", "PanelContainer")
	sb = base_sb.duplicate()
	sb.bg_color = background_color
	sb.set_corner_radius_all(0)
	set_stylebox("panel", "EditorBackground", sb)

	# InspectorPanel
	set_type_variation("InspectorPanel", "PanelContainer")
	sb = base_sb.duplicate()
	sb.bg_color = _get_primary_color(contrast, false)
	sb.set_corner_radius_all(0)
	sb.set_border_width_all(0)
	set_stylebox("panel", "InspectorPanel", sb)

	# InspectorPanelTopBox
	set_type_variation("InspectorPanelTopBox", "PanelContainer")
	sb = base_sb.duplicate()
	sb.bg_color = _get_primary_color(contrast, false)
	sb.set_corner_radius_all(0)
	sb.set_border_width_all(0)
	sb.set_content_margin_all(0)
	sb.set_expand_margin_all(base_spacing)
	sb.expand_margin_left -= 1
	set_stylebox("panel", "InspectorPanelTopBox", sb)

	# EditorSection / Tab styling (reusing base styles)
	set_type_variation("EditorSection", "TabContainer")
	sb = base_sb.duplicate()
	sb.bg_color = _get_primary_color(contrast, false)
	sb.set_corner_radius_all(corner_radius)
	sb.set_content_margin_all(base_margin)
	sb.set_border_width_all(border_width)
	sb.border_color = base_border_color
	set_stylebox("panel_unfocus", "EditorSection", sb)

	sb = sb.duplicate()
	sb.border_color = accent_color
	set_stylebox("panel_focus", "EditorSection", sb)

	sb = sb.duplicate()
	sb.border_width_top = 0
	sb.corner_radius_top_left = 0
	sb.corner_radius_top_right = 0
	sb.border_color = base_border_color
	set_stylebox("tab_panel_unfocus", "EditorSection", sb)

	sb = sb.duplicate()
	sb.border_color = accent_color
	set_stylebox("tab_panel_focus", "EditorSection", sb)

	sb = base_sb.duplicate()
	sb.bg_color = _get_secondary_color(contrast, false)
	sb.set_corner_radius_all(0)
	sb.corner_radius_top_left = corner_radius
	sb.corner_radius_top_right = corner_radius
	sb.set_border_width_all(border_width)
	sb.border_width_bottom = 0
	sb.border_color = base_border_color
	set_stylebox("tabbar_background_unfocus", "EditorSection", sb)

	sb = sb.duplicate()
	sb.border_color = accent_color
	set_stylebox("tabbar_background_focus", "EditorSection", sb)

	sb = base_sb.duplicate()
	sb.set_corner_radius_all(0)
	sb.corner_radius_top_left = corner_radius - 1
	sb.corner_radius_top_right = corner_radius - 1
	sb.bg_color = _get_primary_color(contrast, false)
	sb.border_color = Color.TRANSPARENT
	sb.border_width_top = 1
	set_stylebox("tab_selected", "EditorSection", sb)

	sb = base_sb.duplicate()
	sb.draw_center = false
	set_stylebox("tab_unselected", "EditorSection", sb)
	set_stylebox("tab_focus", "EditorSection", sb)
	set_stylebox("tab_hovered", "EditorSection", sb)
	set_stylebox("tab_disabled", "EditorSection", sb)

	set_color("font_unselected_color", "EditorSection", _get_text_color(0.8))
	set_color("font_disabled_color", "EditorSection", _get_text_color(0.3))
	set_color("font_hover_color", "EditorSection", text_color)
	set_color("font_selected_color", "EditorSection", text_color)
	set_constant("side_margin", "EditorSection", 1)
	set_constant("icon_separation", "EditorSection", int(base_margin))
	set_constant("icon_max_width", "EditorSection", base_font_size)
	set_font_size("font_size", "EditorSection", base_font_size)

	# -----------------------
	# FIELD PANEL / PANELS
	# -----------------------
	set_type_variation("FieldPanel", "PanelContainer")
	sb = base_sb.duplicate()
	sb.bg_color = background_color
	sb.set_border_width_all(border_width)
	sb.set_content_margin_all(base_margin * 2)
	set_stylebox("panel", "FieldPanel", sb)

	# Panel / PanelContainer default
	sb = base_panel_sb.duplicate()
	set_stylebox("panel", "Panel", sb)
	set_stylebox("panel", "PanelContainer", sb)

	# PopupMenu
	sb = base_sb.duplicate()
	sb.bg_color = _get_primary_color(contrast, false)
	_set_border(sb, _get_color(base_border_color, base_border_color.a, false))
	var popup_menu_hover_sb: StyleBoxFlat = base_field_sb.duplicate()
	popup_menu_hover_sb.bg_color = _get_secondary_color(contrast)
	separator_sb = separator_sb.duplicate()
	separator_sb.color = _get_text_color(contrast)
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
	set_icon(
		"radio_checked", "PopupMenu", preload("res://ui/theme_default/assets/radio_checked.svg")
	)
	set_icon(
		"radio_unchecked", "PopupMenu", preload("res://ui/theme_default/assets/radio_unchecked.svg")
	)
	set_icon(
		"checked_disabled",
		"PopupMenu",
		preload("res://ui/theme_default/assets/checked_disabled.svg")
	)
	set_icon(
		"unchecked_disabled",
		"PopupMenu",
		preload("res://ui/theme_default/assets/unchecked_disabled.svg")
	)
	set_icon(
		"radio_checked_disabled",
		"PopupMenu",
		preload("res://ui/theme_default/assets/radio_checked_disabled.svg")
	)
	set_icon(
		"radio_unchecked_disabled",
		"PopupMenu",
		preload("res://ui/theme_default/assets/radio_unchecked_disabled.svg")
	)
	set_stylebox("panel", "PopupMenu", sb)
	set_stylebox("hover", "PopupMenu", popup_menu_hover_sb)
	set_stylebox("separator", "PopupMenu", separator_sb)

	# -----------------------
	# SCROLLBARS
	# -----------------------
	set_stylebox("scroll", "VScrollBar", scroll_sb)
	set_stylebox("scroll_focus", "VScrollBar", scroll_focus_sb)
	set_stylebox("grabber", "VScrollBar", grabber_sb)
	set_stylebox("grabber_highlight", "VScrollBar", grabber_sb)
	set_stylebox("grabber_pressed", "VScrollBar", grabber_sb)

	set_stylebox("scroll", "HScrollBar", scroll_sb)
	set_stylebox("scroll_focus", "HScrollBar", scroll_focus_sb)
	set_stylebox("grabber", "HScrollBar", grabber_sb)
	set_stylebox("grabber_highlight", "HScrollBar", grabber_sb)
	set_stylebox("grabber_pressed", "HScrollBar", grabber_sb)

	# -----------------------
	# SPINBOX
	# -----------------------
	set_type_variation("SpinBoxButtonLeft", "Button")
	set_type_variation("SpinBoxButtonRight", "Button")

	var spin_box_button_pressed_sb_local: StyleBoxFlat = spin_box_button_pressed_sb.duplicate()
	spin_box_button_pressed_sb_local.bg_color = _get_primary_color(contrast)
	spin_box_button_pressed_sb_local.corner_radius_top_right = 0
	spin_box_button_pressed_sb_local.corner_radius_bottom_right = 0

	set_stylebox("normal", "SpinBoxButtonLeft", spin_box_button_sb)
	set_stylebox("pressed", "SpinBoxButtonLeft", spin_box_button_pressed_sb_local)
	set_stylebox("focus", "SpinBoxButtonLeft", spin_box_button_sb)
	set_stylebox("hover", "SpinBoxButtonLeft", spin_box_button_sb)
	set_stylebox("disabled", "SpinBoxButtonLeft", spin_box_button_sb)

	var spin_box_button_pressed_sb_right: StyleBoxFlat = (
		spin_box_button_pressed_sb_local.duplicate()
	)
	spin_box_button_pressed_sb_right.set_corner_radius_all(corner_radius)
	spin_box_button_pressed_sb_right.corner_radius_top_left = 0
	spin_box_button_pressed_sb_right.corner_radius_bottom_left = 0

	set_stylebox("normal", "SpinBoxButtonRight", spin_box_button_sb)
	set_stylebox("pressed", "SpinBoxButtonRight", spin_box_button_pressed_sb_right)
	set_stylebox("focus", "SpinBoxButtonRight", spin_box_button_sb)
	set_stylebox("hover", "SpinBoxButtonRight", spin_box_button_sb)
	set_stylebox("disabled", "SpinBoxButtonRight", spin_box_button_sb)

	# -----------------------
	# LINEEDIT / TEXTEDIT
	# -----------------------
	set_stylebox("normal", "LineEdit", line_edit_sb)
	set_stylebox("focus", "LineEdit", line_edit_focus_sb)
	set_stylebox("disabled", "LineEdit", line_edit_disabled_sb)

	# LineEditPortraitOption variation
	set_type_variation("LineEditPortraitOption", "LineEdit")
	var po_line_edit_sb: StyleBoxFlat = line_edit_sb.duplicate()
	var po_line_edit_focus_sb: StyleBoxFlat = po_line_edit_sb.duplicate()
	po_line_edit_focus_sb.draw_center = true
	po_line_edit_focus_sb.bg_color = background_color
	po_line_edit_focus_sb.set_border_width_all(1)
	var po_line_edit_disabled_sb: StyleBoxFlat = line_edit_disabled_sb.duplicate()

	set_color("font_uneditable_color", "LineEditPortraitOption", text_color)
	set_color("font_color", "LineEditPortraitOption", text_color)
	set_stylebox("normal", "LineEditPortraitOption", po_line_edit_sb)
	set_stylebox("focus", "LineEditPortraitOption", po_line_edit_focus_sb)
	set_stylebox("disabled", "LineEditPortraitOption", po_line_edit_disabled_sb)

	# TextEdit shares the same family but uses a monospaced font
	var text_edit_sb: StyleBoxFlat = line_edit_sb.duplicate()
	var text_edit_focus_sb: StyleBoxFlat = line_edit_focus_sb.duplicate()
	var text_edit_disabled_sb: StyleBoxFlat = line_edit_disabled_sb.duplicate()

	set_font("font", "TextEdit", preload("res://ui/assets/fonts/CourierNewPSMT.ttf"))
	set_font_size("font_size", "TextEdit", 16)
	set_stylebox("normal", "TextEdit", text_edit_sb)
	set_stylebox("focus", "TextEdit", text_edit_focus_sb)
	set_stylebox("read_only", "TextEdit", text_edit_disabled_sb)

	# SpinBoxLineEdit variation
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

	# -----------------------
	# TABBAR
	# -----------------------
	var tab_unselected_sb: StyleBoxFlat = button_sb.duplicate()
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

	# -----------------------
	# GRAPHEDIT / GRAPHNODE
	# -----------------------
	sb = base_sb.duplicate()
	sb.set_content_margin_all(0)
	sb.set_corner_radius_all(0)
	sb.set_border_width_all(0)
	sb.bg_color = background_color
	set_color("grid_major", "GraphEdit", _get_text_color(contrast))
	set_color("grid_minor", "GraphEdit", _get_text_color(contrast))
	set_stylebox("panel", "GraphEdit", sb)

	set_constant("separation", "GraphNode", base_spacing)
	set_stylebox("panel", "GraphNode", graph_node_sb)
	set_stylebox("panel_selected", "GraphNode", graph_node_selected_sb)
	set_stylebox("titlebar", "GraphNode", graph_node_titlebar_sb)
	set_stylebox("titlebar_selected", "GraphNode", graph_node_titlebar_selected_sb)
	set_stylebox("slot", "GraphNode", StyleBoxEmpty.new())

	# GraphNodeTitleLabel
	set_font_size("font_size", "GraphNodeTitleLabel", 1)

	# GraphNodeViewTitleLabel
	set_type_variation("GraphNodeViewTitleLabel", "Label")
	set_color("font_color", "GraphNodeViewTitleLabel", text_color)
	set_font_size("font_size", "GraphNodeViewTitleLabel", 18)

	# GraphNodeViewValueLabel
	set_type_variation("GraphNodeViewValueLabel", "Label")
	set_color("font_color", "GraphNodeViewValueLabel", _get_text_color(0.5))
	set_font_size("font_size", "GraphNodeViewValueLabel", 16)

	# GraphNodeViewRownHBox
	set_type_variation("GraphNodeViewRownHBox", "HBoxContainer")
	set_constant("separation", "GraphNodeViewRownHBox", base_spacing * 5)

	# GraphNodePicker
	set_type_variation("GraphNodePicker", "PanelContainer")
	sb = base_sb.duplicate()
	sb.bg_color = _get_primary_color(contrast, false)
	set_stylebox("panel", "GraphNodePicker", sb)

	# -----------------------
	# CONTAINERS / SEPARATORS
	# -----------------------
	set_type_variation("FieldContainer", "VBoxContainer")

	set_constant("separation", "HBoxContainer", base_spacing)
	set_constant("separation", "VBoxContainer", base_spacing)
	set_constant("separation", "FieldContainer", base_spacing / 2)

	set_type_variation("HDottedSeparator", "HSeparator")
	set_type_variation("VDottedSeparator", "VSeparator")
	set_constant("separation", "HDottedSeparator", 1)
	set_constant("separation", "VDottedSeparator", 1)
	set_stylebox("separator", "HDottedSeparator", dotted_sb)
	set_stylebox("separator", "VDottedSeparator", dotted_sb)

	set_constant("separation", "HSplitContainer", int(base_margin))
	set_constant("separation", "VSplitContainer", int(base_margin))
	set_icon("grabber", "HSplitContainer", Texture2D.new())
	set_icon("grabber", "VSplitContainer", Texture2D.new())

	set_constant("separation", "HSeparator", 1)
	set_constant("separation", "VSeparator", 1)
	set_stylebox("separator", "HSeparator", separator_sb)
	var separator_sb_v: StyleBoxLine = separator_sb.duplicate()
	separator_sb_v.vertical = true
	set_stylebox("separator", "VSeparator", separator_sb_v)

	# Grow variants
	set_type_variation("HSeparatorGrow", "HSeparator")
	set_type_variation("VSeparatorGrow", "VSeparator")
	var separator_grow: StyleBoxLine = separator_sb.duplicate()
	separator_grow.vertical = false
	separator_grow.grow_begin = base_spacing
	separator_grow.grow_end = base_spacing
	set_constant("separation", "HSeparatorGrow", 1)
	set_constant("separation", "VSeparatorGrow", 1)
	set_stylebox("separator", "HSeparatorGrow", separator_grow)
	var separator_grow_v: StyleBoxLine = separator_grow.duplicate()
	separator_grow_v.vertical = true
	set_stylebox("separator", "VSeparatorGrow", separator_grow_v)

	# -----------------------
	# SLIDER
	# -----------------------
	set_icon("grabber", "HSlider", preload("res://ui/theme_default/assets/grabber.svg"))
	set_icon("grabber_highlight", "HSlider", preload("res://ui/theme_default/assets/grabber.svg"))
	set_icon("grabber_disabled", "HSlider", preload("res://ui/theme_default/assets/grabber.svg"))
	set_stylebox("slider", "HSlider", slider_sb)
	set_stylebox("grabber_area", "HSlider", grabber_area)
	set_stylebox("grabber_area_highlight", "HSlider", grabber_area)

	# -----------------------
	# ITEM CONTAINERS & LABELS
	# -----------------------
	set_type_variation("ItemContainer", "PanelContainer")
	sb = base_empty_sb.duplicate()
	set_stylebox("panel", "ItemContainer", sb)

	set_type_variation("ItemContainerFlat", "PanelContainer")
	sb = base_empty_sb.duplicate()
	sb.set_content_margin_all(0)
	set_stylebox("panel", "ItemContainerFlat", sb)

	# Labels
	set_type_variation("NodeValue", "Label")
	set_type_variation("NoteLabel", "Label")
	set_type_variation("WarnLabel", "Label")
	sb = base_sb.duplicate()
	sb.content_margin_top = base_spacing / 2
	sb.content_margin_bottom = base_spacing / 2
	set_color("font_color", "Label", text_color)
	set_color("font_color", "NodeValue", text_color)
	set_color("font_color", "NoteLabel", _get_text_color(0.6))
	set_color("font_color", "WarnLabel", warn_color)
	set_stylebox("normal", "NodeValue", sb)

	# -----------------------
	# TIMELINE / TREE / TOOLTIP
	# -----------------------
	set_type_variation("TimelineCellNumber", "PanelContainer")
	sb = base_sb.duplicate()
	sb.set_corner_radius_all(0)
	sb.bg_color = _get_primary_color(contrast, false)
	sb.border_width_right = border_width
	sb.border_color = Color.BLACK
	set_stylebox("panel", "TimelineCellNumber", sb)

	set_type_variation("TimelineLayerPanel", "PanelContainer")
	sb = base_sb.duplicate()
	sb.set_corner_radius_all(0)
	sb.bg_color = _get_primary_color(contrast, false)
	sb.border_width_bottom = border_width
	sb.border_color = Color.BLACK
	set_stylebox("panel", "TimelineLayerPanel", sb)

	# Tree
	var tree_sb: StyleBoxFlat = base_sb.duplicate()
	var tree_focus_sb: StyleBoxFlat = base_empty_sb.duplicate()

	set_color(
		"relashion_ship_line_color", "Tree", Color(base_border_color, base_border_color.a / 2)
	)
	#set_color("guide_color", "Tree", Color(base_border_color, base_border_color.a/2))
	set_constant("icon_max_width", "Tree", 14)
	set_constant("h_separation", "Tree", base_spacing)
	set_constant("v_separation", "Tree", base_spacing / 2)
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
	set_icon(
		"checked_disabled", "Tree", preload("res://ui/theme_default/assets/checked_disabled.svg")
	)
	set_icon(
		"unchecked_disabled",
		"Tree",
		preload("res://ui/theme_default/assets/unchecked_disabled.svg")
	)
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

	# TooltipPanel
	sb = base_sb.duplicate()
	sb.set_corner_radius_all(0)
	sb.bg_color = Color(background_color, 0.5)
	set_stylebox("panel", "TooltipPanel", sb)

	# -----------------------
	# OPTION BUTTON (uses field family)
	# -----------------------
	var option_button_sb: StyleBoxFlat = base_field_sb.duplicate()
	option_button_sb.bg_color = _get_secondary_color(contrast)

	var option_button_hover_sb: StyleBoxFlat = button_sb.duplicate()
	option_button_hover_sb.bg_color = _get_secondary_color(contrast + 0.05)

	var option_button_pressed_sb: StyleBoxFlat = button_sb.duplicate()
	option_button_pressed_sb.bg_color = _get_secondary_color(contrast + 0.1)

	var option_button_disabled_sb: StyleBoxFlat = button_sb.duplicate()
	option_button_disabled_sb.bg_color = _get_secondary_color(0.05)

	set_constant("arrow_margin", "OptionButton", base_spacing)
	set_constant("h_separation", "OptionButton", base_spacing)
	set_stylebox("disabled", "OptionButton", option_button_disabled_sb)
	set_stylebox("disabled_mirrored", "OptionButton", option_button_disabled_sb)
	set_stylebox("focus", "OptionButton", base_empty_sb)
	set_stylebox("hover", "OptionButton", option_button_hover_sb)
	set_stylebox("hover_mirrored", "OptionButton", option_button_hover_sb)
	set_stylebox("hover_pressed", "OptionButton", option_button_pressed_sb)
	set_stylebox("hover_pressed_mirrored", "OptionButton", option_button_pressed_sb)
	set_stylebox("normal", "OptionButton", option_button_sb)
	set_stylebox("normal_mirrored", "OptionButton", option_button_sb)
	set_stylebox("pressed", "OptionButton", option_button_pressed_sb)
	set_stylebox("pressed_mirrored", "OptionButton", option_button_pressed_sb)

	# -----------------------
	# OUTER PANEL
	# -----------------------
	set_type_variation("OuterPanel", "PanelContainer")
	sb = base_sb.duplicate()
	sb.bg_color = _get_primary_color(contrast, false)
	sb.set_corner_radius_all(int(outer_radius))
	_set_border(sb, _get_color(base_border_color, base_border_color.a, false))
	set_stylebox("panel", "OuterPanel", sb)


## Returns the primary color with specified alpha.
##
## [param alpha] The alpha/opacity value. Default is 1.0.
## [br][br]
## [param transparent] If true, uses transparency; if false, blends with background. Default is true.
func _get_primary_color(alpha: float = 1.0, transparent: bool = true) -> Color:
	return _get_color(primary_color, alpha, transparent)


## Returns the secondary color with specified alpha.
##
## [param alpha] The alpha/opacity value. Default is 1.0.
## [br][br]
## [param transparent] If true, uses transparency; if false, blends with background. Default is true.
func _get_secondary_color(alpha: float = 1.0, transparent: bool = true) -> Color:
	return _get_color(secondary_color, alpha, transparent)


## Returns the text color with specified alpha.
##
## [param alpha] The alpha/opacity value. Default is 1.0.
## [br][br]
## [param transparent] If true, uses transparency; if false, blends with background. Default is true.
func _get_text_color(alpha: float = 1.0, transparent: bool = true) -> Color:
	return _get_color(text_color, alpha, transparent)


## Returns a color with specified alpha, either transparent or blended.
##
## [param color] The base color to modify.
## [br][br]
## [param alpha] The alpha/opacity value. Default is 1.0.
## [br][br]
## [param transparent] If true, uses transparency; if false, blends with blend_with. Default is true.
## [br][br]
## [param blend_with] The color to blend with when transparent is false. Default is background_color.
func _get_color(
	color: Color, alpha: float = 1.0, transparent: bool = true, blend_with: Color = background_color
) -> Color:
	if transparent:
		return Color(color, alpha)
	return Color(blend_with).blend(Color(color, alpha))


## Sets content margins on a StyleBox.
##
## [param sb] The StyleBox to modify.
## [br][br]
## [param left] Left margin value.
## [br][br]
## [param top] Top margin value.
## [br][br]
## [param right] Right margin value (defaults to left if not specified).
## [br][br]
## [param bottom] Bottom margin value (defaults to top if not specified).
func _set_margin(
	sb: StyleBox, left: float, top: float, right: float = left, bottom: float = top
) -> void:
	sb.content_margin_left = left * scale
	sb.content_margin_top = top * scale
	sb.content_margin_right = right * scale
	sb.content_margin_bottom = bottom * scale


## Sets border properties on a StyleBoxFlat.
##
## [param sb] The StyleBoxFlat to modify.
## [br][br]
## [param color] The border color.
## [br][br]
## [param width] The border width. Default is 1.
## [br][br]
## [param blend] Whether to blend the border. Default is false.
func _set_border(sb: StyleBoxFlat, color: Color, width: float = 1, blend: bool = false) -> void:
	sb.border_color = color
	sb.border_blend = blend
	sb.set_border_width_all(int(ceilf(width * scale)))
