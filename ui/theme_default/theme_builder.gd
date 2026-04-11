@tool
class_name ThemeBuilder extends RefCounted
## Modular theme builder that constructs Monologue themes from theme settingss

const ICON_CHECKED: DPITexture = preload("res://ui/theme_default/assets/checked.svg")
const ICON_UNCHECKED: DPITexture = preload("res://ui/theme_default/assets/unchecked.svg")
const ICON_CHECKED_DISABLED: DPITexture = preload("res://ui/theme_default/assets/checked_disabled.svg")
const ICON_UNCHECKED_DISABLED: DPITexture = preload("res://ui/theme_default/assets/unchecked_disabled.svg")
const ICON_RADIO_CHECKED: DPITexture = preload("res://ui/theme_default/assets/radio_checked.svg")
const ICON_RADIO_UNCHECKED: DPITexture = preload("res://ui/theme_default/assets/radio_unchecked.svg")
const ICON_RADIO_CHECKED_DISABLED: DPITexture = preload(
	"res://ui/theme_default/assets/radio_checked_disabled.svg"
)
const ICON_RADIO_UNCHECKED_DISABLED: DPITexture = preload(
	"res://ui/theme_default/assets/radio_unchecked_disabled.svg"
)
const ICON_SLIDER_GRABBER: DPITexture = preload("res://ui/theme_default/assets/grabber.svg")

const FONT_REGULAR: FontFile = preload("res://ui/assets/fonts/GeneralSans-Regular.otf")
const FONT_MEDIUM: FontFile = preload("res://ui/assets/fonts/GeneralSans-Medium.otf")
const FONT_SEMIBOLD: FontFile = preload("res://ui/assets/fonts/GeneralSans-Semibold.otf")


## Build a complete theme from a theme settings
static func build_theme(settings: ThemeSettings) -> Theme:
	var time: float = Time.get_unix_time_from_system()
	
	var theme: Theme = Theme.new()
	var styles: ThemeStyles = ThemeStyles.new(settings)

	# Global typography defaults
	theme.default_font = FONT_REGULAR
	theme.default_font_size = 16

	_build_buttons(theme, settings, styles)
	_build_checkboxes(theme, settings, styles)
	_build_inputs(theme, settings, styles)
	_build_panels(theme, settings, styles)
	_build_scrollbars(theme, settings, styles)
	_build_separators(theme, settings, styles)
	_build_sliders(theme, settings, styles)
	_build_tabs(theme, settings, styles)
	_build_tree(theme, settings, styles)
	_build_graph_elements(theme, settings, styles)
	_build_popup_menu(theme, settings, styles)
	_build_labels(theme, settings, styles)
	
	var time_elapsed: float = Time.get_unix_time_from_system() - time
	if not Engine.is_editor_hint():
		Log.info("Theme generated in %s seconds" % time_elapsed)

	return theme


## Build button styles
static func _build_buttons(theme: Theme, settings: ThemeSettings, styles: ThemeStyles) -> void:
	# Regular Button
	var btn_normal := styles.create_button(settings.button_background)
	var btn_hover := styles.create_button(settings.button_hover)
	var btn_pressed := styles.create_button(settings.button_pressed)
	var btn_disabled := styles.create_button(settings.darken(settings.button_background, 0.3))
	var btn_empty := styles.create_empty()
	
	for type: String in ["Button", "TextureButton", "MenuButton"]:
		theme.set_stylebox("normal", type, btn_normal)
		theme.set_stylebox("hover", type, btn_hover)
		theme.set_stylebox("pressed", type, btn_pressed)
		theme.set_stylebox("disabled", type, btn_disabled)
		theme.set_stylebox("focus", type, btn_empty)

		# Mirror variants
		theme.set_stylebox("normal_mirrored", type, btn_normal)
		theme.set_stylebox("hover_mirrored", type, btn_hover)
		theme.set_stylebox("pressed_mirrored", type, btn_pressed)
		theme.set_stylebox("hover_pressed", type, btn_pressed)
		theme.set_stylebox("hover_pressed_mirrored", type, btn_pressed)
		theme.set_stylebox("disabled_mirrored", type, btn_disabled)

		# Button colors
		theme.set_color("font_color", type, Color(settings.text, 0.80))
		theme.set_color("font_disabled_color", type, settings.text_disabled)
		theme.set_color("font_focus_color", type, settings.text)
		theme.set_color("font_hover_color", type, settings.text)
		theme.set_color("font_hover_pressed_color", type, settings.text)
		theme.set_color("font_pressed_color", type, settings.text)
		theme.set_color("icon_disabled_color", type, settings.text_disabled)
		theme.set_color("icon_normal_color", type, settings.text_secondary)

		# Button constants
		theme.set_constant("outline_size", type, 0)
		theme.set_constant("icon_max_width", type, 15)
		theme.set_constant("h_separation", type, styles.base_spacing)

	# ButtonAccent variation
	theme.set_type_variation("ButtonAccent", "Button")
	var btn_accent := styles.create_button(settings.accent)
	theme.set_stylebox("normal", "ButtonAccent", btn_accent)
	theme.set_stylebox(
		"hover", "ButtonAccent", styles.create_button(settings.lighten(settings.accent, 0.1))
	)
	theme.set_stylebox(
		"pressed", "ButtonAccent", styles.create_button(settings.lighten(settings.accent, 0.15))
	)
	theme.set_stylebox("disabled", "ButtonAccent", btn_accent)
	theme.set_stylebox("normal_mirrored", "ButtonAccent", btn_accent)
	theme.set_stylebox(
		"hover_mirrored",
		"ButtonAccent",
		styles.create_button(settings.lighten(settings.accent, 0.1))
	)
	theme.set_stylebox(
		"pressed_mirrored",
		"ButtonAccent",
		styles.create_button(settings.lighten(settings.accent, 0.15))
	)
	theme.set_stylebox("disabled_mirrored", "ButtonAccent", btn_accent)
	theme.set_stylebox("focus", "ButtonAccent", btn_accent)
	theme.set_stylebox(
		"hover_pressed",
		"ButtonAccent",
		styles.create_button(settings.lighten(settings.accent, 0.15))
	)
	theme.set_stylebox(
		"hover_pressed_mirrored",
		"ButtonAccent",
		styles.create_button(settings.lighten(settings.accent, 0.15))
	)

	# ButtonWarning variation
	theme.set_type_variation("ButtonWarning", "Button")
	var btn_warning := styles.create_button(settings.warning)
	theme.set_stylebox("normal", "ButtonWarning", btn_warning)
	theme.set_stylebox(
		"hover", "ButtonWarning", styles.create_button(settings.lighten(settings.warning, 0.1))
	)
	theme.set_stylebox(
		"pressed", "ButtonWarning", styles.create_button(settings.lighten(settings.warning, 0.15))
	)
	theme.set_stylebox(
		"disabled", "ButtonWarning", styles.create_button(settings.darken(settings.warning, 0.3))
	)
	theme.set_stylebox("normal_mirrored", "ButtonWarning", btn_warning)
	theme.set_stylebox(
		"hover_mirrored",
		"ButtonWarning",
		styles.create_button(settings.lighten(settings.warning, 0.1))
	)
	theme.set_stylebox(
		"pressed_mirrored",
		"ButtonWarning",
		styles.create_button(settings.lighten(settings.warning, 0.15))
	)
	theme.set_stylebox(
		"disabled_mirrored",
		"ButtonWarning",
		styles.create_button(settings.darken(settings.warning, 0.3))
	)
	theme.set_stylebox("focus", "ButtonWarning", btn_empty)
	theme.set_stylebox(
		"hover_pressed",
		"ButtonWarning",
		styles.create_button(settings.lighten(settings.warning, 0.15))
	)
	theme.set_stylebox(
		"hover_pressed_mirrored",
		"ButtonWarning",
		styles.create_button(settings.lighten(settings.warning, 0.15))
	)
	theme.set_constant("outline_size", "ButtonWarning", 0)

	# FlatButton variation (outlined button)
	var flat_btn_normal: StyleBoxFlat = styles.create_empty()
	flat_btn_normal.bg_color = Color.TRANSPARENT
	flat_btn_normal.set_border_width_all(styles.border_width)
	flat_btn_normal.border_color = settings.with_alpha(settings.text, 0.18)

	var flat_btn_hover: StyleBoxFlat = flat_btn_normal.duplicate()
	flat_btn_hover.bg_color = settings.hover_overlay
	flat_btn_hover.border_color = settings.with_alpha(settings.text, 0.35)

	var flat_btn_pressed: StyleBoxFlat = flat_btn_normal.duplicate()
	flat_btn_pressed.bg_color = settings.pressed_overlay
	flat_btn_pressed.border_color = settings.with_alpha(settings.text, 0.50)

	theme.set_color("font_color", "FlatButton", settings.text_secondary)
	theme.set_color("font_disabled_color", "FlatButton", settings.text_disabled)
	theme.set_color("font_focus_color", "FlatButton", settings.text)
	theme.set_color("font_hover_color", "FlatButton", settings.text)
	theme.set_color("font_hover_pressed_color", "FlatButton", settings.text)
	theme.set_color("font_pressed_color", "FlatButton", settings.text)
	theme.set_color("icon_disabled_color", "FlatButton", settings.text_disabled)
	theme.set_color("icon_normal_color", "FlatButton", settings.text_secondary)
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
static func _build_checkboxes(theme: Theme, settings: ThemeSettings, styles: ThemeStyles) -> void:
	var empty := styles.create_empty()
	empty.set_content_margin_all(0)

	theme.set_color("font_hover_pressed_color", "CheckBox", settings.text)
	theme.set_color("font_pressed_color", "CheckBox", settings.text_secondary)
	theme.set_constant("h_separation", "CheckBox", styles.base_spacing)
	theme.set_constant("icon_max_width", "CheckBox", 24)
	theme.set_icon("checked", "CheckBox", ICON_CHECKED)
	theme.set_icon("unchecked", "CheckBox", ICON_UNCHECKED)
	theme.set_icon("radio_checked", "CheckBox", ICON_RADIO_CHECKED)
	theme.set_icon("radio_unchecked", "CheckBox", ICON_RADIO_UNCHECKED)
	theme.set_icon("checked_disabled", "CheckBox", ICON_CHECKED_DISABLED)
	theme.set_icon("unchecked_disabled", "CheckBox", ICON_UNCHECKED_DISABLED)
	theme.set_icon("radio_checked_disabled", "CheckBox", ICON_RADIO_CHECKED_DISABLED)
	theme.set_icon("radio_unchecked_disabled", "CheckBox", ICON_RADIO_UNCHECKED_DISABLED)
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
	theme.set_color("font_focus_color", "CheckButton", settings.text_secondary)
	theme.set_color("font_hover_pressed_color", "CheckButton", settings.text)
	theme.set_color("font_pressed_color", "CheckButton", settings.text)
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
static func _build_inputs(theme: Theme, settings: ThemeSettings, styles: ThemeStyles) -> void:
	var input_normal: StyleBoxFlat = styles.create_input(settings.input_background)
	var input_focus: StyleBoxFlat = input_normal.duplicate()
	input_focus.draw_center = true
	input_focus.set_border_width_all(1)
	input_focus.border_color = settings.accent
	var input_disabled: StyleBoxFlat = styles.create_input(settings.darken(settings.input_background, 0.2))

	# LineEdit
	theme.set_stylebox("normal", "LineEdit", input_normal)
	theme.set_stylebox("focus", "LineEdit", input_focus)
	theme.set_stylebox("disabled", "LineEdit", input_disabled)

	# LineEditPortraitOption variation
	theme.set_type_variation("LineEditPortraitOption", "LineEdit")
	var po_input: StyleBoxFlat = input_normal.duplicate()
	var po_focus: StyleBoxFlat = po_input.duplicate()
	po_focus.draw_center = true
	po_focus.bg_color = settings.panel_background
	po_focus.set_border_width_all(1)

	theme.set_color("font_uneditable_color", "LineEditPortraitOption", settings.text)
	theme.set_color("font_color", "LineEditPortraitOption", settings.text)
	theme.set_stylebox("normal", "LineEditPortraitOption", po_input)
	theme.set_stylebox("focus", "LineEditPortraitOption", po_focus)
	theme.set_stylebox("disabled", "LineEditPortraitOption", input_disabled)

	# TextEdit
	theme.set_font("font", "TextEdit", preload("res://ui/assets/fonts/CourierNewPSMT.ttf"))
	theme.set_font_size("font_size", "TextEdit", 14)
	theme.set_stylebox("normal", "TextEdit", input_normal.duplicate() as StyleBoxFlat)
	theme.set_stylebox("focus", "TextEdit", input_focus.duplicate() as StyleBoxFlat)
	theme.set_stylebox("read_only", "TextEdit", input_disabled.duplicate() as StyleBoxFlat)
	
	# SpinBox
	var empty_bg: StyleBoxEmpty = StyleBoxEmpty.new()
	var empty_image: ImageTexture = ImageTexture.new()
	theme.set_stylebox("up_background", "SpinBox", empty_bg)
	theme.set_stylebox("up_background_hover", "SpinBox", empty_bg)
	theme.set_stylebox("up_background_pressed", "SpinBox", empty_bg)
	theme.set_stylebox("up_background_disabled", "SpinBox", empty_bg)
	theme.set_stylebox("down_background", "SpinBox", empty_bg)
	theme.set_stylebox("down_background_hover", "SpinBox", empty_bg)
	theme.set_stylebox("down_background_pressed", "SpinBox", empty_bg)
	theme.set_stylebox("down_background_disabled", "SpinBox", empty_bg)
	theme.set_stylebox("field_and_buttons_separator", "SpinBox", empty_bg)
	theme.set_stylebox("up_down_buttons_separator", "SpinBox", empty_bg)
	theme.set_icon("updown", "SpinBox", empty_image)
	theme.set_icon("up", "SpinBox", empty_image)
	theme.set_icon("up_hover", "SpinBox", empty_image)
	theme.set_icon("up_pressed", "SpinBox", empty_image)
	theme.set_icon("up_disabled", "SpinBox", empty_image)
	theme.set_icon("down", "SpinBox", empty_image)
	theme.set_icon("down_hover", "SpinBox", empty_image)
	theme.set_icon("down_pressed", "SpinBox", empty_image)
	theme.set_icon("down_disabled", "SpinBox", empty_image)
	theme.set_constant("buttons_width", "SpinBox", 0)
	theme.set_constant("field_and_buttons_separation", "SpinBox", 0)

	# SpinBox components
	theme.set_type_variation("SpinBoxButtonLeft", "Button")
	theme.set_type_variation("SpinBoxButtonRight", "Button")

	var spin_btn: StyleBoxFlat = styles.create_empty()
	spin_btn.set_content_margin_all(styles.base_spacing / 2)
	var spin_btn_pressed := styles.create_panel(settings.button_background)
	spin_btn_pressed.set_content_margin_all(styles.base_spacing / 2)

	var spin_btn_pressed_left: StyleBoxFlat = spin_btn_pressed.duplicate()
	spin_btn_pressed_left.corner_radius_top_right = 0
	spin_btn_pressed_left.corner_radius_bottom_right = 0

	var spin_btn_pressed_right: StyleBoxFlat = spin_btn_pressed.duplicate()
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

	## SpinBoxLineEdit variation
	## FIXME: A type associated with a built-in class cannot be marked as a variation
	## of another type (variation: "SpinBoxLineEdit", base: "LineEdit").
	#theme.set_type_variation("SpinBoxLineEdit", "LineEdit")
	#var spin_input := styles.create_input(settings.input_background)
	#spin_input.draw_center = false
	#spin_input.set_content_margin_all(0)
	#var spin_input_focus := spin_input.duplicate()
	#spin_input_focus.bg_color = settings.button_background
	#spin_input_focus.set_corner_radius_all(0)
#
	#theme.set_stylebox("normal", "SpinBoxLineEdit", spin_input)
	#theme.set_stylebox("focus", "SpinBoxLineEdit", spin_input_focus)
	#theme.set_stylebox("read_only", "SpinBoxLineEdit", spin_input)


## Build panel and container styles
static func _build_panels(theme: Theme, settings: ThemeSettings, styles: ThemeStyles) -> void:
	# Base Panel/PanelContainer
	var panel := styles.create_panel(settings.panel_background)
	theme.set_stylebox("panel", "Panel", panel)
	theme.set_stylebox("panel", "PanelContainer", panel)

	# EditorBackground
	theme.set_type_variation("EditorBackground", "PanelContainer")
	var bg := styles.create_panel(settings.secondary)
	bg.set_corner_radius_all(0)
	theme.set_stylebox("panel", "EditorBackground", bg)

	# InspectorPanel
	theme.set_type_variation("InspectorPanel", "PanelContainer")
	var inspector := styles.create_panel(settings.panel_background)
	inspector.set_corner_radius_all(0)
	inspector.set_border_width_all(0)
	theme.set_stylebox("panel", "InspectorPanel", inspector)

	# InspectorPanelTopBox
	theme.set_type_variation("InspectorPanelTopBox", "PanelContainer")
	var top_box := styles.create_panel(settings.panel_background)
	top_box.set_corner_radius_all(0)
	top_box.set_border_width_all(0)
	top_box.set_content_margin_all(0)
	top_box.set_expand_margin_all(styles.base_spacing)
	top_box.expand_margin_left -= 1
	theme.set_stylebox("panel", "InspectorPanelTopBox", top_box)

	# FoldableContainer
	var f_panel: StyleBoxFlat = styles.create_panel(settings.darken(settings.secondary, 0.08))
	var f_title_collapsed_panel: StyleBoxFlat = f_panel.duplicate()
	f_title_collapsed_panel.bg_color = settings.secondary
	f_title_collapsed_panel.set_content_margin_all(styles.base_spacing)
	var f_title_panel: StyleBoxFlat = f_title_collapsed_panel.duplicate()

	f_panel.border_width_top = 0
	f_panel.corner_radius_top_left = 0
	f_panel.corner_radius_top_right = 0
	f_title_panel.corner_radius_bottom_left = 0
	f_title_panel.corner_radius_bottom_right = 0

	theme.set_font("font", "FoldableContainer", FONT_MEDIUM)
	theme.set_font_size("font_size", "FoldableContainer", 16)
	theme.set_stylebox("focus", "FoldableContainer", styles.create_empty())
	theme.set_stylebox("panel", "FoldableContainer", f_panel)
	theme.set_stylebox("title_panel", "FoldableContainer", f_title_panel)
	theme.set_stylebox("title_hover_panel", "FoldableContainer", f_title_panel)
	theme.set_stylebox("title_collapsed_panel", "FoldableContainer", f_title_collapsed_panel)
	theme.set_stylebox("title_collapsed_hover_panel", "FoldableContainer", f_title_collapsed_panel)

	# FieldContainer
	theme.set_type_variation("FieldContainer", "PanelContainer")
	var field_container_panel := styles.create_panel(settings.panel_background)
	field_container_panel.draw_center = false
	theme.set_stylebox("panel", "FieldContainer", field_container_panel)

	# FieldPanel
	theme.set_type_variation("FieldPanel", "PanelContainer")
	var field_panel := styles.create_panel(settings.panel_background)
	field_panel.set_content_margin_all(styles.base_spacing * 2)  # 12 px with base_spacing=6
	theme.set_stylebox("panel", "FieldPanel", field_panel)

	# OuterPanel
	theme.set_type_variation("OuterPanel", "PanelContainer")
	var outer := styles.create_panel(settings.panel_background, true)
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
	var timeline_cell := styles.create_panel(settings.panel_background)
	timeline_cell.set_corner_radius_all(0)
	timeline_cell.border_width_right = styles.border_width
	timeline_cell.border_color = Color.BLACK
	theme.set_stylebox("panel", "TimelineCellNumber", timeline_cell)

	theme.set_type_variation("TimelineLayerPanel", "PanelContainer")
	var timeline_layer := styles.create_panel(settings.panel_background)
	timeline_layer.set_corner_radius_all(0)
	timeline_layer.border_width_bottom = styles.border_width
	timeline_layer.border_color = Color.BLACK
	theme.set_stylebox("panel", "TimelineLayerPanel", timeline_layer)

	# TreeContainer
	theme.set_type_variation("TreeContainer", "PanelContainer")
	var tree_container := styles.create_panel(settings.panel_background)
	tree_container.set_corner_radius_all(0)
	theme.set_stylebox("panel", "TreeContainer", tree_container)

	# TooltipPanel
	var tooltip := styles.create_panel(settings.with_alpha(settings.panel_background, 0.5))
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

	# ListItemContainer
	theme.set_type_variation("ListItemContainer", "PanelContainer")
	var list_item_container := styles.create_panel(settings.darken(settings.secondary, 0.08))
	theme.set_stylebox("panel", "ListItemContainer", list_item_container)


## Build scrollbar styles
static func _build_scrollbars(theme: Theme, settings: ThemeSettings, styles: ThemeStyles) -> void:
	var scroll_empty: StyleBoxFlat = styles.create_empty()
	scroll_empty.set_content_margin_all(2)
	scroll_empty.set_corner_radius_all(0)

	var scroll_focus: StyleBoxFlat = scroll_empty.duplicate()
	scroll_focus.draw_center = true

	var grabber: StyleBoxFlat = styles.create_panel(settings.with_alpha(settings.text, 0.25))
	grabber.set_corner_radius_all(6)

	var grabber_highlight: StyleBoxFlat = grabber.duplicate()
	grabber_highlight.bg_color = settings.with_alpha(settings.text, 0.40)

	# VScrollBar
	theme.set_stylebox("scroll", "VScrollBar", scroll_empty)
	theme.set_stylebox("scroll_focus", "VScrollBar", scroll_focus)
	theme.set_stylebox("grabber", "VScrollBar", grabber)
	theme.set_stylebox("grabber_highlight", "VScrollBar", grabber_highlight)
	theme.set_stylebox("grabber_pressed", "VScrollBar", grabber_highlight)

	# HScrollBar
	theme.set_stylebox("scroll", "HScrollBar", scroll_empty)
	theme.set_stylebox("scroll_focus", "HScrollBar", scroll_focus)
	theme.set_stylebox("grabber", "HScrollBar", grabber)
	theme.set_stylebox("grabber_highlight", "HScrollBar", grabber_highlight)
	theme.set_stylebox("grabber_pressed", "HScrollBar", grabber_highlight)


## Build separator styles
static func _build_separators(theme: Theme, settings: ThemeSettings, styles: ThemeStyles) -> void:
	# Override separator color to use alpha-based border for subtlety
	var sep_h := styles.create_separator(false)
	sep_h.color = settings.border
	var sep_v := styles.create_separator(true)
	sep_v.color = settings.border

	theme.set_constant("separation", "HSeparator", 1)
	theme.set_constant("separation", "VSeparator", 1)
	theme.set_stylebox("separator", "HSeparator", sep_h)
	theme.set_stylebox("separator", "VSeparator", sep_v)

	# Dotted separator
	theme.set_type_variation("HDottedSeparator", "HSeparator")
	theme.set_type_variation("VDottedSeparator", "VSeparator")

	var dotted := StyleBoxTexture.new()
	dotted.texture = preload("res://ui/theme_default/assets/dash.svg")
	dotted.modulate_color = settings.border_strong
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
static func _build_sliders(theme: Theme, settings: ThemeSettings, styles: ThemeStyles) -> void:
	var slider_track := StyleBoxFlat.new()
	slider_track.content_margin_top = styles.base_spacing
	slider_track.set_corner_radius_all(5)
	slider_track.bg_color = settings.button_background

	var grabber_area: StyleBoxFlat = slider_track.duplicate()
	grabber_area.bg_color = settings.accent

	theme.set_icon("grabber", "HSlider", ICON_SLIDER_GRABBER)
	theme.set_icon("grabber_highlight", "HSlider", ICON_SLIDER_GRABBER)
	theme.set_icon("grabber_disabled", "HSlider", ICON_SLIDER_GRABBER)
	theme.set_stylebox("slider", "HSlider", slider_track)
	theme.set_stylebox("grabber_area", "HSlider", grabber_area)
	theme.set_stylebox("grabber_area_highlight", "HSlider", grabber_area)


## Build tab styles
static func _build_tabs(theme: Theme, settings: ThemeSettings, styles: ThemeStyles) -> void:
	# TabBar
	var tab_unselected := styles.create_button(settings.secondary)
	tab_unselected.content_margin_top /= 2
	tab_unselected.content_margin_bottom /= 2

	var tab_selected: StyleBoxFlat = tab_unselected.duplicate()
	tab_selected.draw_center = true
	tab_selected.bg_color = settings.accent

	theme.set_color("font_disabled_color", "TabBar", settings.text_disabled)
	theme.set_color("font_unselected_color", "TabBar", settings.text_secondary)
	theme.set_color("font_hovered_color", "TabBar", settings.text)
	theme.set_color("font_selected_color", "TabBar", Color.WHITE)
	theme.set_constant("h_separation", "TabBar", styles.base_spacing)
	#theme.set_font_size("font_size", "TabBar", 16)
	theme.set_icon("close", "TabBar", preload("res://ui/assets/icons/ui_close.svg"))
	theme.set_icon("menu", "TabBar", preload("res://ui/assets/icons/vertical_dots.svg"))
	theme.set_icon("menu_highlight", "TabBar", preload("res://ui/assets/icons/vertical_dots.svg"))
	theme.set_icon("increment", "TabContainer", preload("res://ui/assets/icons/arrow_right.svg"))
	theme.set_icon(
		"increment_highlight", "TabContainer", preload("res://ui/assets/icons/arrow_right.svg")
	)
	theme.set_icon("decrement", "TabContainer", preload("res://ui/assets/icons/arrow_left.svg"))
	theme.set_icon(
		"decrement_highlight", "TabContainer", preload("res://ui/assets/icons/arrow_left.svg")
	)
	theme.set_stylebox("button_highlight", "TabBar", StyleBoxEmpty.new())
	theme.set_stylebox("button_pressed", "TabBar", StyleBoxEmpty.new())
	theme.set_stylebox("tab_unselected", "TabBar", tab_unselected)
	theme.set_stylebox("tab_hovered", "TabBar", tab_unselected.duplicate() as StyleBoxFlat)
	theme.set_stylebox("tab_selected", "TabBar", tab_selected)
	theme.set_stylebox("tab_disabled", "TabBar", tab_unselected.duplicate() as StyleBoxFlat)
	theme.set_stylebox("tab_focus", "TabBar", tab_selected.duplicate() as StyleBoxFlat)

	# EditorSection (TabContainer variation)
	theme.set_type_variation("EditorSection", "TabContainer")
	var section_unfocus: StyleBoxFlat = styles.create_panel(settings.panel_background)
	var section_focus: StyleBoxFlat = section_unfocus.duplicate()
	section_focus.border_color = settings.border
	#section_focus.border_color = settings.accent

	theme.set_icon(
		"menu", "TabContainer", preload("res://ui/assets/icons/vertical_dots_unfocus.svg")
	)
	theme.set_icon(
		"menu_highlight", "TabContainer", preload("res://ui/assets/icons/vertical_dots.svg")
	)
	theme.set_icon("increment", "TabContainer", preload("res://ui/assets/icons/arrow_right.svg"))
	theme.set_icon(
		"increment_highlight", "TabContainer", preload("res://ui/assets/icons/arrow_right.svg")
	)
	theme.set_icon("decrement", "TabContainer", preload("res://ui/assets/icons/arrow_left.svg"))
	theme.set_icon(
		"decrement_highlight", "TabContainer", preload("res://ui/assets/icons/arrow_left.svg")
	)

	theme.set_stylebox("panel_unfocus", "EditorSection", section_unfocus)
	theme.set_stylebox("panel_focus", "EditorSection", section_focus)

	var tab_panel_unfocus: StyleBoxFlat = section_unfocus.duplicate()
	tab_panel_unfocus.border_width_top = 0
	#tab_panel_unfocus.corner_radius_top_left = 0
	#tab_panel_unfocus.corner_radius_top_right = 0

	var tab_panel_focus: StyleBoxFlat = tab_panel_unfocus.duplicate()
	tab_panel_focus.border_color = settings.border
	#tab_panel_focus.border_color = settings.accent

	theme.set_stylebox("tab_panel_unfocus", "EditorSection", tab_panel_unfocus)
	theme.set_stylebox("tab_panel_focus", "EditorSection", tab_panel_focus)

	var tabbar_bg_unfocus := styles.create_panel(settings.secondary)
	tabbar_bg_unfocus.set_border_width_all(0)
	tabbar_bg_unfocus.set_corner_radius_all(0)
	tabbar_bg_unfocus.content_margin_bottom = 0
	#tabbar_bg_unfocus.corner_radius_top_left = styles.corner_radius
	#tabbar_bg_unfocus.corner_radius_top_right = styles.corner_radius

	var tabbar_bg_focus: StyleBoxFlat = tabbar_bg_unfocus.duplicate()
	tabbar_bg_focus.border_color = settings.border
	#tabbar_bg_focus.border_color = settings.accent

	theme.set_stylebox("tabbar_background_unfocus", "EditorSection", tabbar_bg_unfocus)
	theme.set_stylebox("tabbar_background_focus", "EditorSection", tabbar_bg_focus)

	var tab_sel := styles.create_button(settings.panel_background)
	tab_sel.set_corner_radius_all(0)
	tab_sel.corner_radius_top_left = styles.corner_radius - 1
	tab_sel.corner_radius_top_right = styles.corner_radius - 1
	tab_sel.border_color = Color.TRANSPARENT
	tab_sel.border_width_top = 1

	var tab_unsel := styles.create_button(settings.secondary)
	tab_unsel.draw_center = false

	theme.set_stylebox("tab_selected", "EditorSection", tab_sel)
	theme.set_stylebox("tab_unselected", "EditorSection", tab_unsel)
	theme.set_stylebox("tab_focus", "EditorSection", tab_unsel)
	theme.set_stylebox("tab_hovered", "EditorSection", tab_unsel)
	theme.set_stylebox("tab_disabled", "EditorSection", tab_unsel)

	theme.set_color("font_unselected_color", "EditorSection", settings.text_secondary)
	theme.set_color("font_disabled_color", "EditorSection", settings.text_disabled)
	theme.set_color("font_hover_color", "EditorSection", settings.text)
	theme.set_color("font_selected_color", "EditorSection", settings.text)
	theme.set_constant("side_margin", "EditorSection", 1)
	theme.set_constant("icon_separation", "EditorSection", styles.base_spacing)
	theme.set_constant("icon_max_width", "EditorSection", 16)
	theme.set_font("font", "EditorSection", FONT_MEDIUM)
	theme.set_font_size("font_size", "EditorSection", 13)


## Build tree styles
static func _build_tree(theme: Theme, settings: ThemeSettings, styles: ThemeStyles) -> void:
	var tree_panel := styles.create_panel(settings.tertiary)
	var tree_empty := styles.create_button(Color.TRANSPARENT)
	var tree_hover := styles.create_button(settings.button_hover)
	var tree_selected := styles.create_button(settings.button_pressed)

	theme.set_color("relationship_line_color", "Tree", settings.with_alpha(settings.border, 0.5))
	theme.set_constant("icon_max_width", "Tree", 18)
	theme.set_constant("h_separation", "Tree", styles.base_spacing)
	theme.set_constant("v_separation", "Tree", styles.base_spacing / 2)
	theme.set_constant("inner_item_margin_bottom", "Tree", styles.base_spacing/2)
	theme.set_constant("inner_item_margin_left", "Tree", styles.base_spacing)
	theme.set_constant("inner_item_margin_top", "Tree", styles.base_spacing/2)
	theme.set_constant("inner_item_margin_right", "Tree", styles.base_spacing)
	theme.set_constant("draw_relationship_lines", "Tree", 1)
	theme.set_constant("draw_guides", "Tree", 0)
	theme.set_constant("relationship_line_width", "Tree", 0)
	theme.set_constant("parent_hl_line_width", "Tree", styles.border_width)
	theme.set_constant("children_hl_line_width", "Tree", 0)
	theme.set_icon("checked", "Tree", ICON_CHECKED)
	theme.set_icon("unchecked", "Tree", ICON_UNCHECKED)
	theme.set_icon("checked_disabled", "Tree", ICON_CHECKED_DISABLED)
	theme.set_icon("unchecked_disabled", "Tree", ICON_UNCHECKED_DISABLED)
	theme.set_stylebox("panel", "Tree", tree_panel)
	theme.set_stylebox("focus", "Tree", tree_empty)
	theme.set_stylebox("hovered", "Tree", tree_hover)
	theme.set_stylebox("hovered_dimmed", "Tree", tree_hover)
	theme.set_stylebox("selected", "Tree", tree_selected)
	theme.set_stylebox("selected_focus", "Tree", tree_selected)
	theme.set_stylebox("hovered_selected", "Tree", tree_selected)
	theme.set_stylebox("hovered_selected_focus", "Tree", tree_selected)
	theme.set_stylebox("button_hovered", "Tree", tree_hover)
	theme.set_stylebox("button_pressed", "Tree", tree_selected)
	theme.set_stylebox("custom_button", "Tree", tree_hover)
	theme.set_stylebox("custom_button_hovered", "Tree", tree_hover)
	theme.set_stylebox("custom_button_pressed", "Tree", tree_selected)


## Build graph-related styles
static func _build_graph_elements(
	theme: Theme, settings: ThemeSettings, styles: ThemeStyles
) -> void:
	# GraphEdit
	var graph_bg := styles.create_panel(settings.tertiary)
	graph_bg.set_content_margin_all(0)
	graph_bg.set_corner_radius_all(0)
	graph_bg.set_border_width_all(0)

	theme.set_color("grid_major", "GraphEdit", settings.with_alpha(settings.text, 0.08))
	theme.set_color("grid_minor", "GraphEdit", settings.with_alpha(settings.text, 0.04))
	theme.set_stylebox("panel", "GraphEdit", graph_bg)

	# GraphNode
	var node_panel: StyleBoxFlat = styles.create_panel(settings.primary, true)
	node_panel.border_color = settings.border
	node_panel.shadow_color = settings.with_alpha(Color.BLACK, 0.10)
	node_panel.shadow_size = 12

	var node_selected: StyleBoxFlat = node_panel.duplicate()
	node_selected.border_color = settings.accent

	theme.set_constant("separation", "GraphNode", styles.base_spacing)
	theme.set_stylebox("panel", "GraphNode", node_panel)
	theme.set_stylebox("panel_selected", "GraphNode", node_selected)
	theme.set_stylebox("titlebar", "GraphNode", StyleBoxEmpty.new())
	theme.set_stylebox("titlebar_selected", "GraphNode", StyleBoxEmpty.new())
	theme.set_stylebox("slot", "GraphNode", StyleBoxEmpty.new())

	# GraphNode label variants
	theme.set_font_size("font_size", "GraphNodeTitleLabel", 1)

	theme.set_type_variation("GraphNodeViewTitleLabel", "Label")
	theme.set_font("font", "GraphNodeViewTitleLabel", FONT_MEDIUM)
	theme.set_color("font_color", "GraphNodeViewTitleLabel", settings.text)
	theme.set_font_size("font_size", "GraphNodeViewTitleLabel", 18)

	theme.set_type_variation("GraphNodeViewValueLabel", "Label")
	theme.set_font("font", "GraphNodeViewValueLabel", FONT_REGULAR)
	theme.set_color(
		"font_color", "GraphNodeViewValueLabel", settings.with_alpha(settings.text, 0.55)
	)
	theme.set_font_size("font_size", "GraphNodeViewValueLabel", 14)

	theme.set_type_variation("GraphNodeViewRownHBox", "HBoxContainer")
	theme.set_constant("separation", "GraphNodeViewRownHBox", styles.base_spacing * 5)

	# GraphNodePicker
	theme.set_type_variation("GraphNodePicker", "PanelContainer")
	var picker := styles.create_panel(settings.panel_background)
	theme.set_stylebox("panel", "GraphNodePicker", picker)


## Build popup menu styles
static func _build_popup_menu(theme: Theme, settings: ThemeSettings, styles: ThemeStyles) -> void:
	var menu_panel := styles.create_panel(settings.tertiary, false)
	var menu_hover := styles.create_input(settings.surface_variant)
	var menu_sep := styles.create_separator(true)
	menu_sep.color = settings.with_alpha(settings.text, 0.15)

	theme.set_constant("icon_max_width", "PopupMenu", 10)
	theme.set_constant("item_end_padding", "PopupMenu", styles.base_spacing)
	theme.set_constant("item_start_padding", "PopupMenu", styles.base_spacing)
	theme.set_constant("h_separation", "PopupMenu", styles.base_spacing)
	theme.set_constant("v_separation", "PopupMenu", styles.base_spacing)
	theme.set_font_size("font_size", "PopupMenu", 16)
	theme.set_icon("checked", "PopupMenu", ICON_CHECKED)
	theme.set_icon("unchecked", "PopupMenu", ICON_UNCHECKED)
	theme.set_icon("radio_checked", "PopupMenu", ICON_RADIO_CHECKED)
	theme.set_icon("radio_unchecked", "PopupMenu", ICON_RADIO_UNCHECKED)
	theme.set_icon("checked_disabled", "PopupMenu", ICON_CHECKED_DISABLED)
	theme.set_icon("unchecked_disabled", "PopupMenu", ICON_UNCHECKED_DISABLED)
	theme.set_icon("radio_checked_disabled", "PopupMenu", ICON_RADIO_CHECKED_DISABLED)
	theme.set_icon("radio_unchecked_disabled", "PopupMenu", ICON_RADIO_UNCHECKED_DISABLED)
	theme.set_stylebox("panel", "PopupMenu", menu_panel)
	theme.set_stylebox("hover", "PopupMenu", menu_hover)
	theme.set_stylebox("separator", "PopupMenu", menu_sep)

	# OptionButton
	var option_normal := styles.create_input(settings.tertiary)
	var option_disabled := styles.create_input(settings.lighten(settings.tertiary, 0.2))
	var option_empty := styles.create_empty()

	theme.set_constant("arrow_margin", "OptionButton", styles.base_spacing)
	theme.set_constant("h_separation", "OptionButton", styles.base_spacing)
	theme.set_stylebox("disabled", "OptionButton", option_disabled)
	theme.set_stylebox("disabled_mirrored", "OptionButton", option_disabled)
	theme.set_stylebox("focus", "OptionButton", option_empty)
	theme.set_stylebox("hover", "OptionButton", option_normal)
	theme.set_stylebox("hover_mirrored", "OptionButton", option_normal)
	theme.set_stylebox("hover_pressed", "OptionButton", option_normal)
	theme.set_stylebox("hover_pressed_mirrored", "OptionButton", option_normal)
	theme.set_stylebox("normal", "OptionButton", option_normal)
	theme.set_stylebox("normal_mirrored", "OptionButton", option_normal)
	theme.set_stylebox("pressed", "OptionButton", option_normal)
	theme.set_stylebox("pressed_mirrored", "OptionButton", option_normal)


## Build label styles
static func _build_labels(theme: Theme, settings: ThemeSettings, styles: ThemeStyles) -> void:
	var label_bg := styles.create_panel(settings.panel_background)
	label_bg.content_margin_top = styles.base_spacing / 2
	label_bg.content_margin_bottom = styles.base_spacing / 2

	theme.set_color("font_color", "Label", settings.text)

	theme.set_type_variation("NodeValue", "Label")
	theme.set_font("font", "NodeValue", FONT_MEDIUM)
	theme.set_color("font_color", "NodeValue", settings.text)
	theme.set_stylebox("normal", "NodeValue", label_bg)

	theme.set_type_variation("NoteLabel", "Label")
	theme.set_color("font_color", "NoteLabel", settings.with_alpha(settings.text, 0.55))

	theme.set_type_variation("WarnLabel", "Label")
	theme.set_font("font", "WarnLabel", FONT_MEDIUM)
	theme.set_color("font_color", "WarnLabel", settings.warning)
