@tool
class_name ThemeBuilder extends RefCounted
## Modular theme builder that constructs the Monologue theme using semantic colors

var theme: Theme
var palette: ThemeColorPalette
var styles: ThemeStyles


func _init(target_theme: Theme, color_palette: ThemeColorPalette) -> void:
	theme = target_theme
	palette = color_palette
	styles = ThemeStyles.new(palette)


## Build all theme components
func build() -> void:
	_build_buttons()
	_build_checkboxes()
	_build_inputs()
	_build_panels()
	_build_scrollbars()
	_build_separators()
	_build_sliders()
	_build_tabs()
	_build_tree()
	_build_graph_elements()
	_build_popup_menu()
	_build_labels()


## Build button styles
func _build_buttons() -> void:
	# Regular Button
	var btn_normal := styles.create_button(palette.button_background)
	var btn_hover := styles.create_button(palette.button_hover)
	var btn_pressed := styles.create_button(palette.button_pressed)
	var btn_disabled := styles.create_button(palette.darken(palette.button_background, 0.3))
	var btn_empty := styles.create_empty()
	
	theme.set_stylebox("normal", "Button", btn_normal)
	theme.set_stylebox("hover", "Button", btn_hover)
	theme.set_stylebox("pressed", "Button", btn_pressed)
	theme.set_stylebox("disabled", "Button", btn_disabled)
	theme.set_stylebox("focus", "Button", btn_empty)
	
	# Mirror variants
	theme.set_stylebox("normal_mirrored", "Button", btn_normal)
	theme.set_stylebox("hover_mirrored", "Button", btn_hover)
	theme.set_stylebox("pressed_mirrored", "Button", btn_pressed)
	theme.set_stylebox("hover_pressed", "Button", btn_pressed)
	theme.set_stylebox("hover_pressed_mirrored", "Button", btn_pressed)
	theme.set_stylebox("disabled_mirrored", "Button", btn_disabled)
	
	# Button colors
	theme.set_color("font_color", "Button", palette.text_secondary)
	theme.set_color("font_disabled_color", "Button", palette.text_disabled)
	theme.set_color("font_focus_color", "Button", palette.text)
	theme.set_color("font_hover_color", "Button", palette.text)
	theme.set_color("font_hover_pressed_color", "Button", palette.text)
	theme.set_color("font_pressed_color", "Button", palette.text)
	theme.set_color("icon_disabled_color", "Button", palette.text_disabled)
	theme.set_color("icon_normal_color", "Button", palette.text_secondary)
	
	# Button constants
	theme.set_constant("outline_size", "Button", 0)
	theme.set_constant("icon_max_width", "Button", 15)
	theme.set_constant("h_separation", "Button", styles.base_spacing)
	
	# ButtonAccent variation
	theme.set_type_variation("ButtonAccent", "Button")
	var btn_accent := styles.create_button(palette.accent)
	theme.set_stylebox("normal", "ButtonAccent", btn_accent)
	theme.set_stylebox("hover", "ButtonAccent", styles.create_button(palette.lighten(palette.accent, 0.1)))
	theme.set_stylebox("pressed", "ButtonAccent", styles.create_button(palette.lighten(palette.accent, 0.15)))
	theme.set_stylebox("disabled", "ButtonAccent", btn_accent)
	theme.set_stylebox("normal_mirrored", "ButtonAccent", btn_accent)
	theme.set_stylebox("hover_mirrored", "ButtonAccent", styles.create_button(palette.lighten(palette.accent, 0.1)))
	theme.set_stylebox("pressed_mirrored", "ButtonAccent", styles.create_button(palette.lighten(palette.accent, 0.15)))
	theme.set_stylebox("disabled_mirrored", "ButtonAccent", btn_accent)
	theme.set_stylebox("focus", "ButtonAccent", btn_accent)
	theme.set_stylebox("hover_pressed", "ButtonAccent", styles.create_button(palette.lighten(palette.accent, 0.15)))
	theme.set_stylebox("hover_pressed_mirrored", "ButtonAccent", styles.create_button(palette.lighten(palette.accent, 0.15)))
	
	# ButtonWarning variation
	theme.set_type_variation("ButtonWarning", "Button")
	var btn_warning := styles.create_button(palette.warning)
	theme.set_stylebox("normal", "ButtonWarning", btn_warning)
	theme.set_stylebox("hover", "ButtonWarning", styles.create_button(palette.lighten(palette.warning, 0.1)))
	theme.set_stylebox("pressed", "ButtonWarning", styles.create_button(palette.lighten(palette.warning, 0.15)))
	theme.set_stylebox("disabled", "ButtonWarning", styles.create_button(palette.darken(palette.warning, 0.3)))
	theme.set_stylebox("normal_mirrored", "ButtonWarning", btn_warning)
	theme.set_stylebox("hover_mirrored", "ButtonWarning", styles.create_button(palette.lighten(palette.warning, 0.1)))
	theme.set_stylebox("pressed_mirrored", "ButtonWarning", styles.create_button(palette.lighten(palette.warning, 0.15)))
	theme.set_stylebox("disabled_mirrored", "ButtonWarning", styles.create_button(palette.darken(palette.warning, 0.3)))
	theme.set_stylebox("focus", "ButtonWarning", btn_empty)
	theme.set_stylebox("hover_pressed", "ButtonWarning", styles.create_button(palette.lighten(palette.warning, 0.15)))
	theme.set_stylebox("hover_pressed_mirrored", "ButtonWarning", styles.create_button(palette.lighten(palette.warning, 0.15)))
	theme.set_constant("outline_size", "ButtonWarning", 0)
	
	# FlatButton variation (outlined button)
	var flat_btn_normal := styles.create_empty()
	flat_btn_normal.bg_color = Color.TRANSPARENT
	flat_btn_normal.set_border_width_all(styles.border_width)
	flat_btn_normal.border_color = palette.with_alpha(palette.text, 0.3)
	
	var flat_btn_hover := flat_btn_normal.duplicate()
	flat_btn_hover.bg_color = palette.hover_overlay
	flat_btn_hover.border_color = palette.with_alpha(palette.text, 0.5)
	
	var flat_btn_pressed := flat_btn_normal.duplicate()
	flat_btn_pressed.bg_color = palette.pressed_overlay
	flat_btn_pressed.border_color = palette.with_alpha(palette.text, 0.6)
	
	theme.set_color("font_color", "FlatButton", palette.text_secondary)
	theme.set_color("font_disabled_color", "FlatButton", palette.text_disabled)
	theme.set_color("font_focus_color", "FlatButton", palette.text)
	theme.set_color("font_hover_color", "FlatButton", palette.text)
	theme.set_color("font_hover_pressed_color", "FlatButton", palette.text)
	theme.set_color("font_pressed_color", "FlatButton", palette.text)
	theme.set_color("icon_disabled_color", "FlatButton", palette.text_disabled)
	theme.set_color("icon_normal_color", "FlatButton", palette.text_secondary)
	theme.set_constant("outline_size", "FlatButton", 0)
	theme.set_stylebox("disabled", "FlatButton", btn_disabled)
	theme.set_stylebox("disabled_mirrored", "FlatButton", btn_disabled)
	theme.set_stylebox("normal", "FlatButton", flat_btn_normal)
	theme.set_stylebox("normal_mirrored", "FlatButton", flat_btn_normal)
	theme.set_stylebox("hover", "FlatButton", flat_btn_hover)
	theme.set_stylebox("hover_mirrored", "FlatButton", flat_btn_hover)
	theme.set_stylebox("hover_pressed", "FlatButton", flat_btn_pressed)
	theme.set_stylebox("hover_pressed_mirrored", "FlatButton", flat_btn_pressed)
	theme.set_stylebox("pressed", "FlatButton", flat_btn_pressed)
	theme.set_stylebox("pressed_mirrored", "FlatButton", flat_btn_pressed)


## Build checkbox and toggle styles
func _build_checkboxes() -> void:
	var empty := styles.create_empty()
	empty.set_content_margin_all(0)
	
	theme.set_color("font_hover_pressed_color", "CheckBox", palette.text)
	theme.set_color("font_pressed_color", "CheckBox", palette.text_secondary)
	theme.set_constant("h_separation", "CheckBox", styles.base_spacing)
	theme.set_icon("checked", "CheckBox", preload("res://ui/theme_default/assets/checked.svg"))
	theme.set_icon("unchecked", "CheckBox", preload("res://ui/theme_default/assets/unchecked.svg"))
	theme.set_icon("radio_checked", "CheckBox", preload("res://ui/theme_default/assets/radio_checked.svg"))
	theme.set_icon("radio_unchecked", "CheckBox", preload("res://ui/theme_default/assets/radio_unchecked.svg"))
	theme.set_icon("checked_disabled", "CheckBox", preload("res://ui/theme_default/assets/checked_disabled.svg"))
	theme.set_icon("unchecked_disabled", "CheckBox", preload("res://ui/theme_default/assets/unchecked_disabled.svg"))
	theme.set_icon("radio_checked_disabled", "CheckBox", preload("res://ui/theme_default/assets/radio_checked_disabled.svg"))
	theme.set_icon("radio_unchecked_disabled", "CheckBox", preload("res://ui/theme_default/assets/radio_unchecked_disabled.svg"))
	theme.set_stylebox("focus", "CheckBox", empty)
	theme.set_stylebox("disabled", "CheckBox", empty)
	theme.set_stylebox("disabled_mirrored", "CheckBox", empty)
	theme.set_stylebox("hover", "CheckBox", empty)
	theme.set_stylebox("hover_mirrored", "CheckBox", empty)
	theme.set_stylebox("hover_pressed", "CheckBox", empty)
	theme.set_stylebox("hover_pressed_mirrored", "CheckBox", empty)
	theme.set_stylebox("pressed", "CheckBox", empty)
	theme.set_stylebox("pressed_mirrored", "CheckBox", empty)
	theme.set_stylebox("normal", "CheckBox", empty)
	theme.set_stylebox("normal_mirrored", "CheckBox", empty)
	
	# CheckButton (toggle)
	theme.set_color("font_focus_color", "CheckButton", palette.text_secondary)
	theme.set_color("font_hover_pressed_color", "CheckButton", palette.text)
	theme.set_color("font_pressed_color", "CheckButton", palette.text)
	theme.set_icon("checked", "CheckButton", preload("res://ui/assets/icons/toggle_on.svg"))
	theme.set_icon("unchecked", "CheckButton", preload("res://ui/assets/icons/toggle_off.svg"))
	theme.set_stylebox("focus", "CheckButton", empty)
	theme.set_stylebox("disabled", "CheckButton", empty)
	theme.set_stylebox("disabled_mirrored", "CheckButton", empty)
	theme.set_stylebox("hover", "CheckButton", empty)
	theme.set_stylebox("hover_mirrored", "CheckButton", empty)
	theme.set_stylebox("hover_pressed", "CheckButton", empty)
	theme.set_stylebox("hover_pressed_mirrored", "CheckButton", empty)
	theme.set_stylebox("pressed", "CheckButton", empty)
	theme.set_stylebox("pressed_mirrored", "CheckButton", empty)
	theme.set_stylebox("normal", "CheckButton", empty)
	theme.set_stylebox("normal_mirrored", "CheckButton", empty)


## Build input field styles (LineEdit, TextEdit, SpinBox)
func _build_inputs() -> void:
	var input_normal := styles.create_input(palette.input_background)
	var input_focus := input_normal.duplicate()
	input_focus.draw_center = false
	input_focus.set_border_width_all(1)
	var input_disabled := styles.create_input(palette.darken(palette.input_background, 0.2))
	
	# LineEdit
	theme.set_stylebox("normal", "LineEdit", input_normal)
	theme.set_stylebox("focus", "LineEdit", input_focus)
	theme.set_stylebox("disabled", "LineEdit", input_disabled)
	
	# LineEditPortraitOption variation
	theme.set_type_variation("LineEditPortraitOption", "LineEdit")
	var po_input := input_normal.duplicate()
	var po_focus := po_input.duplicate()
	po_focus.draw_center = true
	po_focus.bg_color = palette.background
	po_focus.set_border_width_all(1)
	
	theme.set_color("font_uneditable_color", "LineEditPortraitOption", palette.text)
	theme.set_color("font_color", "LineEditPortraitOption", palette.text)
	theme.set_stylebox("normal", "LineEditPortraitOption", po_input)
	theme.set_stylebox("focus", "LineEditPortraitOption", po_focus)
	theme.set_stylebox("disabled", "LineEditPortraitOption", input_disabled)
	
	# TextEdit
	theme.set_font("font", "TextEdit", preload("res://ui/assets/fonts/CourierNewPSMT.ttf"))
	theme.set_font_size("font_size", "TextEdit", 16)
	theme.set_stylebox("normal", "TextEdit", input_normal.duplicate())
	theme.set_stylebox("focus", "TextEdit", input_focus.duplicate())
	theme.set_stylebox("read_only", "TextEdit", input_disabled.duplicate())
	
	# SpinBox components
	theme.set_type_variation("SpinBoxButtonLeft", "Button")
	theme.set_type_variation("SpinBoxButtonRight", "Button")
	
	var spin_btn := styles.create_empty()
	spin_btn.set_content_margin_all(styles.base_spacing / 2)
	var spin_btn_pressed := styles.create_panel(palette.button_background)
	spin_btn_pressed.set_content_margin_all(styles.base_spacing / 2)
	
	var spin_btn_pressed_left := spin_btn_pressed.duplicate()
	spin_btn_pressed_left.corner_radius_top_right = 0
	spin_btn_pressed_left.corner_radius_bottom_right = 0
	
	var spin_btn_pressed_right := spin_btn_pressed.duplicate()
	spin_btn_pressed_right.corner_radius_top_left = 0
	spin_btn_pressed_right.corner_radius_bottom_left = 0
	
	theme.set_stylebox("normal", "SpinBoxButtonLeft", spin_btn)
	theme.set_stylebox("pressed", "SpinBoxButtonLeft", spin_btn_pressed_left)
	theme.set_stylebox("focus", "SpinBoxButtonLeft", spin_btn)
	theme.set_stylebox("hover", "SpinBoxButtonLeft", spin_btn)
	theme.set_stylebox("disabled", "SpinBoxButtonLeft", spin_btn)
	
	theme.set_stylebox("normal", "SpinBoxButtonRight", spin_btn)
	theme.set_stylebox("pressed", "SpinBoxButtonRight", spin_btn_pressed_right)
	theme.set_stylebox("focus", "SpinBoxButtonRight", spin_btn)
	theme.set_stylebox("hover", "SpinBoxButtonRight", spin_btn)
	theme.set_stylebox("disabled", "SpinBoxButtonRight", spin_btn)
	
	# SpinBoxLineEdit variation
	theme.set_type_variation("SpinBoxLineEdit", "LineEdit")
	var spin_input := styles.create_input(palette.input_background)
	spin_input.draw_center = false
	spin_input.set_content_margin_all(0)
	var spin_input_focus := spin_input.duplicate()
	spin_input_focus.bg_color = palette.button_background
	spin_input_focus.set_corner_radius_all(0)
	
	theme.set_stylebox("normal", "SpinBoxLineEdit", spin_input)
	theme.set_stylebox("focus", "SpinBoxLineEdit", spin_input_focus)
	theme.set_stylebox("read_only", "SpinBoxLineEdit", spin_input)


## Build panel and container styles
func _build_panels() -> void:
	# Base Panel/PanelContainer
	var panel := styles.create_panel(palette.panel_background)
	theme.set_stylebox("panel", "Panel", panel)
	theme.set_stylebox("panel", "PanelContainer", panel)
	
	# EditorBackground
	theme.set_type_variation("EditorBackground", "PanelContainer")
	var bg := styles.create_panel(palette.background)
	bg.set_corner_radius_all(0)
	theme.set_stylebox("panel", "EditorBackground", bg)
	
	# InspectorPanel
	theme.set_type_variation("InspectorPanel", "PanelContainer")
	var inspector := styles.create_panel(palette.panel_background)
	inspector.set_corner_radius_all(0)
	inspector.set_border_width_all(0)
	theme.set_stylebox("panel", "InspectorPanel", inspector)
	
	# InspectorPanelTopBox
	theme.set_type_variation("InspectorPanelTopBox", "PanelContainer")
	var top_box := styles.create_panel(palette.panel_background)
	top_box.set_corner_radius_all(0)
	top_box.set_border_width_all(0)
	top_box.set_content_margin_all(0)
	top_box.set_expand_margin_all(styles.base_spacing)
	top_box.expand_margin_left -= 1
	theme.set_stylebox("panel", "InspectorPanelTopBox", top_box)
	
	# CollapsibleFieldPanel
	theme.set_type_variation("CollapsibleFieldPanel", "PanelContainer")
	var collapsible := styles.create_panel(palette.lighten(palette.panel_background, 0.05))
	theme.set_stylebox("panel", "CollapsibleFieldPanel", collapsible)
	
	# FieldPanel
	theme.set_type_variation("FieldPanel", "PanelContainer")
	var field_panel := styles.create_panel(palette.background, true)
	field_panel.set_content_margin_all(styles.base_spacing * 2)
	theme.set_stylebox("panel", "FieldPanel", field_panel)
	
	# OuterPanel
	theme.set_type_variation("OuterPanel", "PanelContainer")
	var outer := styles.create_panel(palette.panel_background, true)
	outer.set_corner_radius_all(styles.base_spacing + styles.corner_radius)
	theme.set_stylebox("panel", "OuterPanel", outer)
	
	# ItemContainer variations
	theme.set_type_variation("ItemContainer", "PanelContainer")
	var item := styles.create_empty()
	theme.set_stylebox("panel", "ItemContainer", item)
	
	theme.set_type_variation("ItemContainerFlat", "PanelContainer")
	var item_flat := styles.create_empty()
	item_flat.set_content_margin_all(0)
	theme.set_stylebox("panel", "ItemContainerFlat", item_flat)
	
	# Timeline panels
	theme.set_type_variation("TimelineCellNumber", "PanelContainer")
	var timeline_cell := styles.create_panel(palette.panel_background)
	timeline_cell.set_corner_radius_all(0)
	timeline_cell.border_width_right = styles.border_width
	timeline_cell.border_color = Color.BLACK
	theme.set_stylebox("panel", "TimelineCellNumber", timeline_cell)
	
	theme.set_type_variation("TimelineLayerPanel", "PanelContainer")
	var timeline_layer := styles.create_panel(palette.panel_background)
	timeline_layer.set_corner_radius_all(0)
	timeline_layer.border_width_bottom = styles.border_width
	timeline_layer.border_color = Color.BLACK
	theme.set_stylebox("panel", "TimelineLayerPanel", timeline_layer)
	
	# TreeContainer
	theme.set_type_variation("TreeContainer", "PanelContainer")
	var tree_container := styles.create_panel(palette.panel_background)
	tree_container.set_corner_radius_all(0)
	theme.set_stylebox("panel", "TreeContainer", tree_container)
	
	# TooltipPanel
	var tooltip := styles.create_panel(palette.with_alpha(palette.background, 0.5))
	tooltip.set_corner_radius_all(0)
	theme.set_stylebox("panel", "TooltipPanel", tooltip)
	
	# Container separations
	theme.set_type_variation("FieldContainer", "VBoxContainer")
	theme.set_constant("separation", "HBoxContainer", styles.base_spacing)
	theme.set_constant("separation", "VBoxContainer", styles.base_spacing)
	theme.set_constant("separation", "FieldContainer", styles.base_spacing / 2)
	
	theme.set_constant("separation", "HSplitContainer", styles.base_spacing)
	theme.set_constant("separation", "VSplitContainer", styles.base_spacing)
	theme.set_icon("grabber", "HSplitContainer", Texture2D.new())
	theme.set_icon("grabber", "VSplitContainer", Texture2D.new())


## Build scrollbar styles
func _build_scrollbars() -> void:
	var scroll_empty := styles.create_empty()
	scroll_empty.border_color = palette.border
	scroll_empty.set_content_margin_all(2)
	scroll_empty.set_corner_radius_all(0)
	
	var scroll_focus := scroll_empty.duplicate()
	scroll_focus.draw_center = true
	
	var grabber := styles.create_panel(palette.border)
	grabber.set_corner_radius_all(5)
	
	# VScrollBar
	theme.set_stylebox("scroll", "VScrollBar", scroll_empty)
	theme.set_stylebox("scroll_focus", "VScrollBar", scroll_focus)
	theme.set_stylebox("grabber", "VScrollBar", grabber)
	theme.set_stylebox("grabber_highlight", "VScrollBar", grabber)
	theme.set_stylebox("grabber_pressed", "VScrollBar", grabber)
	
	# HScrollBar
	theme.set_stylebox("scroll", "HScrollBar", scroll_empty)
	theme.set_stylebox("scroll_focus", "HScrollBar", scroll_focus)
	theme.set_stylebox("grabber", "HScrollBar", grabber)
	theme.set_stylebox("grabber_highlight", "HScrollBar", grabber)
	theme.set_stylebox("grabber_pressed", "HScrollBar", grabber)


## Build separator styles
func _build_separators() -> void:
	var sep_h := styles.create_separator(false)
	var sep_v := styles.create_separator(true)
	
	theme.set_constant("separation", "HSeparator", 1)
	theme.set_constant("separation", "VSeparator", 1)
	theme.set_stylebox("separator", "HSeparator", sep_h)
	theme.set_stylebox("separator", "VSeparator", sep_v)
	
	# Dotted separator
	theme.set_type_variation("HDottedSeparator", "HSeparator")
	theme.set_type_variation("VDottedSeparator", "VSeparator")
	
	var dotted := StyleBoxTexture.new()
	dotted.texture = preload("res://ui/theme_default/assets/dash.svg")
	dotted.modulate_color = palette.border
	dotted.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT
	dotted.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT
	dotted.texture_margin_top = 1
	
	theme.set_constant("separation", "HDottedSeparator", 1)
	theme.set_constant("separation", "VDottedSeparator", 1)
	theme.set_stylebox("separator", "HDottedSeparator", dotted)
	theme.set_stylebox("separator", "VDottedSeparator", dotted)
	
	# Grow variants
	theme.set_type_variation("HSeparatorGrow", "HSeparator")
	theme.set_type_variation("VSeparatorGrow", "VSeparator")
	var sep_grow_h := styles.create_separator(false)
	sep_grow_h.grow_begin = styles.base_spacing
	sep_grow_h.grow_end = styles.base_spacing
	var sep_grow_v := styles.create_separator(true)
	sep_grow_v.grow_begin = styles.base_spacing
	sep_grow_v.grow_end = styles.base_spacing
	
	theme.set_constant("separation", "HSeparatorGrow", 1)
	theme.set_constant("separation", "VSeparatorGrow", 1)
	theme.set_stylebox("separator", "HSeparatorGrow", sep_grow_h)
	theme.set_stylebox("separator", "VSeparatorGrow", sep_grow_v)


## Build slider styles
func _build_sliders() -> void:
	var slider_track := StyleBoxFlat.new()
	slider_track.content_margin_top = 5
	slider_track.set_corner_radius_all(5)
	slider_track.bg_color = palette.button_background
	
	var grabber_area := slider_track.duplicate()
	grabber_area.bg_color = palette.accent
	
	theme.set_icon("grabber", "HSlider", preload("res://ui/theme_default/assets/grabber.svg"))
	theme.set_icon("grabber_highlight", "HSlider", preload("res://ui/theme_default/assets/grabber.svg"))
	theme.set_icon("grabber_disabled", "HSlider", preload("res://ui/theme_default/assets/grabber.svg"))
	theme.set_stylebox("slider", "HSlider", slider_track)
	theme.set_stylebox("grabber_area", "HSlider", grabber_area)
	theme.set_stylebox("grabber_area_highlight", "HSlider", grabber_area)


## Build tab styles
func _build_tabs() -> void:
	# TabBar
	var tab_unselected := styles.create_empty()
	tab_unselected.draw_center = false
	tab_unselected.set_border_width_all(0)
	tab_unselected.border_width_right = 1
	tab_unselected.set_corner_radius_all(0)
	
	var tab_selected := tab_unselected.duplicate()
	tab_selected.draw_center = true
	tab_selected.bg_color = palette.accent
	
	theme.set_color("font_disabled_color", "TabBar", palette.text_disabled)
	theme.set_color("font_unselected_color", "TabBar", palette.text_secondary)
	theme.set_color("font_hovered_color", "TabBar", palette.text)
	theme.set_color("font_selected_color", "TabBar", palette.text)
	theme.set_constant("h_separation", "TabBar", styles.base_spacing)
	theme.set_font_size("font_size", "TabBar", 16)
	theme.set_stylebox("button_highlight", "TabBar", StyleBoxEmpty.new())
	theme.set_stylebox("button_pressed", "TabBar", StyleBoxEmpty.new())
	theme.set_stylebox("tab_unselected", "TabBar", tab_unselected)
	theme.set_stylebox("tab_hovered", "TabBar", tab_unselected.duplicate())
	theme.set_stylebox("tab_selected", "TabBar", tab_selected)
	theme.set_stylebox("tab_disabled", "TabBar", tab_unselected.duplicate())
	theme.set_stylebox("tab_focus", "TabBar", tab_unselected.duplicate())
	
	# EditorSection (TabContainer variation)
	theme.set_type_variation("EditorSection", "TabContainer")
	var section_unfocus := styles.create_panel(palette.panel_background, true)
	var section_focus := section_unfocus.duplicate()
	section_focus.border_color = palette.accent
	
	theme.set_stylebox("panel_unfocus", "EditorSection", section_unfocus)
	theme.set_stylebox("panel_focus", "EditorSection", section_focus)
	
	var tab_panel_unfocus := section_unfocus.duplicate()
	tab_panel_unfocus.border_width_top = 0
	tab_panel_unfocus.corner_radius_top_left = 0
	tab_panel_unfocus.corner_radius_top_right = 0
	
	var tab_panel_focus := tab_panel_unfocus.duplicate()
	tab_panel_focus.border_color = palette.accent
	
	theme.set_stylebox("tab_panel_unfocus", "EditorSection", tab_panel_unfocus)
	theme.set_stylebox("tab_panel_focus", "EditorSection", tab_panel_focus)
	
	var tabbar_bg_unfocus := styles.create_panel(palette.secondary, true)
	tabbar_bg_unfocus.set_corner_radius_all(0)
	tabbar_bg_unfocus.corner_radius_top_left = styles.corner_radius
	tabbar_bg_unfocus.corner_radius_top_right = styles.corner_radius
	tabbar_bg_unfocus.border_width_bottom = 0
	
	var tabbar_bg_focus := tabbar_bg_unfocus.duplicate()
	tabbar_bg_focus.border_color = palette.accent
	
	theme.set_stylebox("tabbar_background_unfocus", "EditorSection", tabbar_bg_unfocus)
	theme.set_stylebox("tabbar_background_focus", "EditorSection", tabbar_bg_focus)
	
	var tab_sel := styles.create_panel(palette.panel_background)
	tab_sel.set_corner_radius_all(0)
	tab_sel.corner_radius_top_left = styles.corner_radius - 1
	tab_sel.corner_radius_top_right = styles.corner_radius - 1
	tab_sel.border_color = Color.TRANSPARENT
	tab_sel.border_width_top = 1
	
	var tab_unsel := styles.create_panel(palette.secondary)
	tab_unsel.draw_center = false
	
	theme.set_stylebox("tab_selected", "EditorSection", tab_sel)
	theme.set_stylebox("tab_unselected", "EditorSection", tab_unsel)
	theme.set_stylebox("tab_focus", "EditorSection", tab_unsel)
	theme.set_stylebox("tab_hovered", "EditorSection", tab_unsel)
	theme.set_stylebox("tab_disabled", "EditorSection", tab_unsel)
	
	theme.set_color("font_unselected_color", "EditorSection", palette.text_secondary)
	theme.set_color("font_disabled_color", "EditorSection", palette.text_disabled)
	theme.set_color("font_hover_color", "EditorSection", palette.text)
	theme.set_color("font_selected_color", "EditorSection", palette.text)
	theme.set_constant("side_margin", "EditorSection", 1)
	theme.set_constant("icon_separation", "EditorSection", styles.base_spacing)
	theme.set_constant("icon_max_width", "EditorSection", 14)
	theme.set_font_size("font_size", "EditorSection", 14)


## Build tree styles
func _build_tree() -> void:
	var tree_panel := styles.create_panel(palette.panel_background)
	var tree_empty := styles.create_empty()
	var tree_hover := styles.create_button(palette.button_hover)
	var tree_selected := styles.create_button(palette.button_pressed)
	
	theme.set_color("relationship_line_color", "Tree", palette.with_alpha(palette.border, 0.5))
	theme.set_constant("icon_max_width", "Tree", 14)
	theme.set_constant("h_separation", "Tree", styles.base_spacing)
	theme.set_constant("v_separation", "Tree", styles.base_spacing / 2)
	theme.set_constant("inner_item_margin_bottom", "Tree", styles.base_spacing)
	theme.set_constant("inner_item_margin_left", "Tree", styles.base_spacing)
	theme.set_constant("inner_item_margin_top", "Tree", styles.base_spacing)
	theme.set_constant("inner_item_margin_right", "Tree", styles.base_spacing)
	theme.set_constant("draw_relationship_lines", "Tree", 1)
	theme.set_constant("draw_guides", "Tree", 0)
	theme.set_constant("relationship_line_width", "Tree", 0)
	theme.set_constant("parent_hl_line_width", "Tree", styles.border_width)
	theme.set_constant("children_hl_line_width", "Tree", 0)
	theme.set_icon("checked", "Tree", preload("res://ui/theme_default/assets/checked.svg"))
	theme.set_icon("unchecked", "Tree", preload("res://ui/theme_default/assets/unchecked.svg"))
	theme.set_icon("checked_disabled", "Tree", preload("res://ui/theme_default/assets/checked_disabled.svg"))
	theme.set_icon("unchecked_disabled", "Tree", preload("res://ui/theme_default/assets/unchecked_disabled.svg"))
	theme.set_stylebox("panel", "Tree", tree_panel)
	theme.set_stylebox("focus", "Tree", tree_empty)
	theme.set_stylebox("hovered", "Tree", tree_hover)
	theme.set_stylebox("hovered_dimmed", "Tree", tree_hover)
	theme.set_stylebox("selected", "Tree", tree_selected)
	theme.set_stylebox("selected_focus", "Tree", tree_selected)


## Build graph-related styles
func _build_graph_elements() -> void:
	# GraphEdit
	var graph_bg := styles.create_panel(palette.background)
	graph_bg.set_content_margin_all(0)
	graph_bg.set_corner_radius_all(0)
	graph_bg.set_border_width_all(0)
	
	theme.set_color("grid_major", "GraphEdit", palette.with_alpha(palette.text, 0.15))
	theme.set_color("grid_minor", "GraphEdit", palette.with_alpha(palette.text, 0.15))
	theme.set_stylebox("panel", "GraphEdit", graph_bg)
	
	# GraphNode
	var node_panel := styles.create_panel(palette.panel_background, true)
	node_panel.shadow_color = palette.with_alpha(Color.BLACK, 0.15)
	node_panel.shadow_size = 10
	
	var node_selected := node_panel.duplicate()
	node_selected.border_color = palette.lighten(palette.border, 0.1)
	
	theme.set_constant("separation", "GraphNode", styles.base_spacing)
	theme.set_stylebox("panel", "GraphNode", node_panel)
	theme.set_stylebox("panel_selected", "GraphNode", node_selected)
	theme.set_stylebox("titlebar", "GraphNode", StyleBoxEmpty.new())
	theme.set_stylebox("titlebar_selected", "GraphNode", StyleBoxEmpty.new())
	theme.set_stylebox("slot", "GraphNode", StyleBoxEmpty.new())
	
	# GraphNode label variants
	theme.set_font_size("font_size", "GraphNodeTitleLabel", 1)
	
	theme.set_type_variation("GraphNodeViewTitleLabel", "Label")
	theme.set_color("font_color", "GraphNodeViewTitleLabel", palette.text)
	theme.set_font_size("font_size", "GraphNodeViewTitleLabel", 18)
	
	theme.set_type_variation("GraphNodeViewValueLabel", "Label")
	theme.set_color("font_color", "GraphNodeViewValueLabel", palette.with_alpha(palette.text, 0.5))
	theme.set_font_size("font_size", "GraphNodeViewValueLabel", 16)
	
	theme.set_type_variation("GraphNodeViewRownHBox", "HBoxContainer")
	theme.set_constant("separation", "GraphNodeViewRownHBox", styles.base_spacing * 5)
	
	# GraphNodePicker
	theme.set_type_variation("GraphNodePicker", "PanelContainer")
	var picker := styles.create_panel(palette.panel_background)
	theme.set_stylebox("panel", "GraphNodePicker", picker)


## Build popup menu styles
func _build_popup_menu() -> void:
	var menu_panel := styles.create_panel(palette.panel_background, true)
	var menu_hover := styles.create_input(palette.surface_variant)
	var menu_sep := styles.create_separator(true)
	menu_sep.color = palette.with_alpha(palette.text, 0.15)
	
	theme.set_constant("icon_max_width", "PopupMenu", 14)
	theme.set_constant("item_end_padding", "PopupMenu", styles.base_spacing)
	theme.set_constant("item_start_padding", "PopupMenu", styles.base_spacing)
	theme.set_constant("h_separation", "PopupMenu", styles.base_spacing)
	theme.set_constant("v_separation", "PopupMenu", 4)
	theme.set_font_size("font_size", "PopupMenu", 16)
	theme.set_icon("checked", "PopupMenu", preload("res://ui/theme_default/assets/checked.svg"))
	theme.set_icon("unchecked", "PopupMenu", preload("res://ui/theme_default/assets/unchecked.svg"))
	theme.set_icon("radio_checked", "PopupMenu", preload("res://ui/theme_default/assets/radio_checked.svg"))
	theme.set_icon("radio_unchecked", "PopupMenu", preload("res://ui/theme_default/assets/radio_unchecked.svg"))
	theme.set_icon("checked_disabled", "PopupMenu", preload("res://ui/theme_default/assets/checked_disabled.svg"))
	theme.set_icon("unchecked_disabled", "PopupMenu", preload("res://ui/theme_default/assets/unchecked_disabled.svg"))
	theme.set_icon("radio_checked_disabled", "PopupMenu", preload("res://ui/theme_default/assets/radio_checked_disabled.svg"))
	theme.set_icon("radio_unchecked_disabled", "PopupMenu", preload("res://ui/theme_default/assets/radio_unchecked_disabled.svg"))
	theme.set_stylebox("panel", "PopupMenu", menu_panel)
	theme.set_stylebox("hover", "PopupMenu", menu_hover)
	theme.set_stylebox("separator", "PopupMenu", menu_sep)
	
	# OptionButton
	var option_normal := styles.create_input(palette.surface_variant)
	var option_hover := styles.create_input(palette.lighten(palette.surface_variant, 0.05))
	var option_pressed := styles.create_input(palette.lighten(palette.surface_variant, 0.1))
	var option_disabled := styles.create_input(palette.darken(palette.surface_variant, 0.2))
	var option_empty := styles.create_empty()
	
	theme.set_constant("arrow_margin", "OptionButton", styles.base_spacing)
	theme.set_constant("h_separation", "OptionButton", styles.base_spacing)
	theme.set_stylebox("disabled", "OptionButton", option_disabled)
	theme.set_stylebox("disabled_mirrored", "OptionButton", option_disabled)
	theme.set_stylebox("focus", "OptionButton", option_empty)
	theme.set_stylebox("hover", "OptionButton", option_hover)
	theme.set_stylebox("hover_mirrored", "OptionButton", option_hover)
	theme.set_stylebox("hover_pressed", "OptionButton", option_pressed)
	theme.set_stylebox("hover_pressed_mirrored", "OptionButton", option_pressed)
	theme.set_stylebox("normal", "OptionButton", option_normal)
	theme.set_stylebox("normal_mirrored", "OptionButton", option_normal)
	theme.set_stylebox("pressed", "OptionButton", option_pressed)
	theme.set_stylebox("pressed_mirrored", "OptionButton", option_pressed)


## Build label styles
func _build_labels() -> void:
	var label_bg := styles.create_panel(palette.panel_background)
	label_bg.content_margin_top = styles.base_spacing / 2
	label_bg.content_margin_bottom = styles.base_spacing / 2
	
	theme.set_color("font_color", "Label", palette.text)
	
	theme.set_type_variation("NodeValue", "Label")
	theme.set_color("font_color", "NodeValue", palette.text)
	theme.set_stylebox("normal", "NodeValue", label_bg)
	
	theme.set_type_variation("NoteLabel", "Label")
	theme.set_color("font_color", "NoteLabel", palette.with_alpha(palette.text, 0.6))
	
	theme.set_type_variation("WarnLabel", "Label")
	theme.set_color("font_color", "WarnLabel", palette.warning)
