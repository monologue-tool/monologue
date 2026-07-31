# This file builds the whole editor theme in code and embeds SVG markup as string
# literals, so a few linter rules do not apply here:
#   max-line-length              -- SVG attributes cannot be wrapped without altering the markup.
#   function-preload-variable-name -- locals hold preloaded textures, not class references.
#   max-file-lines               -- one function per themed control; splitting it per
#                                   control group is worth doing, but not urgent.
# gdlint: disable=max-line-length,function-preload-variable-name,max-file-lines
@abstract class_name ThemeLayout

static var font_main: FontVariation = preload("res://ui/assets/fonts/Main.tres")
static var font_typing: FontVariation = preload("res://ui/assets/fonts/Typing.tres")

# Shared by FoldableContainer and by the PopupMenu submenu arrows. Never recoloured, so a
# single instance is fine here -- icons that mutate color_map take a duplicate() instead.
static var folded_arrow_icon: DPITexture = preload("res://ui/assets/icons/folded_arrow.svg")
static var folded_arrow_mirrored_icon: DPITexture = preload(
	"res://ui/assets/icons/folded_arrow_mirrored.svg"
)

static var font_size_sm: int = 12
static var font_size_md: int = 14
static var font_size_lg: int = 18

static var bg_primary_color: Color
static var bg_surface_color: Color
static var bg_elevated_color: Color
static var bg_higher_color: Color

static var text_primary_color: Color
static var text_muted_color: Color
static var border_color: Color
static var selection_color: Color
static var disabled_selection_color: Color

static var accent_color: Color
static var fail_color: Color
static var success_color: Color
static var highlight_color: Color

static var radius_sm: int = 4
static var radius_md: int = 6
static var margin_sm: Vector2 = Vector2(5, 2)
static var margin_md: Vector2 = Vector2(10, 5)
static var spacing_sm: int = 5
static var spacing_md: int = 10
static var spacing_lg: int = 12

static var icon_xs: int = 12
static var icon_sm: int = 16
static var icon_md: int = 18
static var icon_lg: int = 20

static var radio_checked_icon: DPITexture
static var radio_unchecked_icon: DPITexture

static var is_theme_dark: bool

static var _colormap_dict: Dictionary


static func color_difference(color1: Color, color2: Color) -> float:
	return (absf(color1.r - color2.r) + absf(color1.g - color2.g) + absf(color1.b - color2.b)) / 3.0


static func recalculate_colors() -> void:
	is_theme_dark = (bg_primary_color.get_luminance() < 0.5)

	bg_primary_color = Color("161616") if is_theme_dark else Color("f2f2f2")
	bg_surface_color = Color("202020") if is_theme_dark else Color("e8e8e8")
	bg_elevated_color = Color("323232") if is_theme_dark else Color("d6d6d6")
	bg_higher_color = Color("424242") if is_theme_dark else Color("c8c8c8")

	text_primary_color = Color("d3d3d3") if is_theme_dark else Color("2c2c2c")
	text_muted_color = Color("777777") if is_theme_dark else Color("888888")
	border_color = Color("323232") if is_theme_dark else Color("d0d0d0")
	selection_color = Color(bg_higher_color, 0.5)
	disabled_selection_color = Color(bg_elevated_color, 0.5)

	accent_color = Color("b44040")
	fail_color = Color("e86666ff")
	success_color = Color("72e879")
	highlight_color = Color("966fc5")

	_colormap_dict = {
		"bg_primary": "#" + bg_primary_color.to_html(false),
		"bg_surface": "#" + bg_surface_color.to_html(false),
		"bg_elevated": "#" + bg_elevated_color.to_html(false),
		"bg_higher": "#" + bg_higher_color.to_html(false),
		"text_primary": "#" + text_primary_color.to_html(false),
		"text_muted": "#" + text_muted_color.to_html(false),
		"accent": "#" + accent_color.to_html(false),
		"radius_sm": "%s" % radius_sm
	}

	radio_checked_icon = (
		DPITexture
		. create_from_string(
			(
				"""<svg width="10" height="10" viewBox="0 0 10 10" fill="none" xmlns="http://www.w3.org/2000/svg">
			<rect width="10" height="10" rx="5" fill="{accent}"/>
			<rect x="2" y="2" width="6" height="6" rx="3" fill="{text_primary}"/>
		</svg>"""
				. format(_colormap_dict)
			)
		)
	)

	radio_unchecked_icon = (
		DPITexture
		. create_from_string(
			(
				"""<svg width="10" height="10" viewBox="0 0 10 10" fill="none" xmlns="http://www.w3.org/2000/svg">
			<rect x="0.5" y="0.5" width="9" height="9" rx="4.5" fill="{text_muted}"/>
		</svg>"""
				. format(_colormap_dict)
			)
		)
	)


static func rebuild_fonts() -> void:
	font_main.base_font = FontFile.new()
	font_typing.base_font = FontFile.new()


static func generate_theme() -> Theme:
	var start_time: float = Time.get_unix_time_from_system()

	recalculate_colors()
	var theme := Theme.new()
	theme.default_font = font_main
	theme.default_font_size = 12

	_setup_panel(theme)
	_setup_button(theme)
	_setup_checkbox(theme)
	_setup_optionbutton(theme)
	_setup_lineedit(theme)
	_setup_scrollbar(theme)
	_setup_separator(theme)
	_setup_margincontainer(theme)
	_setup_label(theme)
	_setup_textedit(theme)
	_setup_richtextlabel(theme)
	_setup_foldablecontainer(theme)
	_setup_boxcontainer(theme)
	_setup_graphnode(theme)
	_setup_graphedit(theme)
	_setup_splitcontainer(theme)
	_setup_tree(theme)
	_setup_popupmenu(theme)

	var end_time: float = Time.get_unix_time_from_system()
	var elasped: float = end_time - start_time

	Log.info("Theme generated in %s seconds." % elasped)

	return theme


static func generate_and_apply_theme() -> void:
	var default_theme: Theme = ThemeDB.get_project_theme()
	default_theme.default_font = font_main
	default_theme.default_font_size = 12
	var generated_theme: Theme = generate_theme()
	default_theme.merge_with(generated_theme)


static func _setup_panel(theme: Theme) -> void:
	theme.add_type("PanelContainer")
	var stylebox: StyleBoxFlat = StyleBoxFlat.new()
	stylebox.set_corner_radius_all(radius_sm)
	stylebox.content_margin_top = margin_md.y
	stylebox.content_margin_bottom = margin_md.y
	stylebox.content_margin_left = margin_md.x
	stylebox.content_margin_right = margin_md.x
	stylebox.bg_color = bg_surface_color
	theme.set_stylebox("panel", "PanelContainer", stylebox)

	theme.add_type("EditorBackground")
	theme.set_type_variation("EditorBackground", "PanelContainer")
	var editor_bg_stylebox: StyleBoxFlat = StyleBoxFlat.new()
	editor_bg_stylebox.bg_color = bg_primary_color
	theme.set_stylebox("panel", "EditorBackground", editor_bg_stylebox)

	theme.add_type("EditorHeader")
	theme.set_type_variation("EditorHeader", "PanelContainer")
	var editor_header_stylebox: StyleBoxFlat = StyleBoxFlat.new()
	editor_header_stylebox.content_margin_top = margin_md.y
	editor_header_stylebox.content_margin_bottom = margin_md.y
	editor_header_stylebox.content_margin_left = margin_md.x
	editor_header_stylebox.content_margin_right = margin_md.x
	editor_header_stylebox.bg_color = bg_surface_color
	theme.set_stylebox("panel", "EditorHeader", editor_header_stylebox)

	theme.add_type("EditorPanel")
	theme.set_type_variation("EditorPanel", "PanelContainer")
	var editor_panel_stylebox: StyleBoxFlat = StyleBoxFlat.new()
	editor_panel_stylebox.set_corner_radius_all(radius_md)
	editor_panel_stylebox.content_margin_top = margin_md.y
	editor_panel_stylebox.content_margin_bottom = margin_md.y
	editor_panel_stylebox.content_margin_left = margin_md.x
	editor_panel_stylebox.content_margin_right = margin_md.x
	editor_panel_stylebox.bg_color = bg_surface_color
	theme.set_stylebox("panel", "EditorPanel", editor_panel_stylebox)

	theme.add_type("EditorGraphPanel")
	theme.set_type_variation("EditorGraphPanel", "PanelContainer")
	var editor_graph_panel_stylebox: StyleBoxFlat = StyleBoxFlat.new()
	editor_graph_panel_stylebox.set_corner_radius_all(radius_md)
	editor_graph_panel_stylebox.set_content_margin_all(1)
	editor_graph_panel_stylebox.set_border_width_all(1)
	editor_graph_panel_stylebox.bg_color = bg_surface_color
	editor_graph_panel_stylebox.border_color = bg_surface_color
	theme.set_stylebox("panel", "EditorGraphPanel", editor_graph_panel_stylebox)

	theme.add_type("ConsolePanel")
	theme.set_type_variation("ConsolePanel", "PanelContainer")
	var console_panel_stylebox: StyleBoxFlat = StyleBoxFlat.new()
	console_panel_stylebox.bg_color = bg_primary_color
	console_panel_stylebox.set_corner_radius_all(radius_md)
	console_panel_stylebox.content_margin_top = margin_md.y
	console_panel_stylebox.content_margin_bottom = margin_md.y
	console_panel_stylebox.content_margin_left = margin_md.x
	console_panel_stylebox.content_margin_right = margin_md.x
	theme.set_stylebox("panel", "ConsolePanel", console_panel_stylebox)

	theme.add_type("ListFieldPanel")
	theme.set_type_variation("ListFieldPanel", "PanelContainer")
	var list_field_panel_stylebox: StyleBoxFlat = StyleBoxFlat.new()
	list_field_panel_stylebox.bg_color = bg_surface_color
	list_field_panel_stylebox.set_corner_radius_all(radius_md)
	list_field_panel_stylebox.set_content_margin_all(0)
	theme.set_stylebox("panel", "ListFieldPanel", list_field_panel_stylebox)

	theme.add_type("ListItemPanel")
	theme.set_type_variation("ListItemPanel", "PanelContainer")
	var list_item_panel_stylebox: StyleBoxFlat = StyleBoxFlat.new()
	list_item_panel_stylebox.bg_color = Color(bg_primary_color, 0.5)
	list_item_panel_stylebox.set_corner_radius_all(0)
	list_item_panel_stylebox.content_margin_top = margin_md.y
	list_item_panel_stylebox.content_margin_bottom = margin_md.y
	list_item_panel_stylebox.content_margin_left = margin_md.x
	list_item_panel_stylebox.content_margin_right = margin_md.x
	theme.set_stylebox("panel", "ListItemPanel", list_item_panel_stylebox)

	theme.add_type("ListItemOddPanel")
	theme.set_type_variation("ListItemOddPanel", "PanelContainer")
	var list_item_odd_panel_stylebox: StyleBoxFlat = list_item_panel_stylebox.duplicate()
	list_item_odd_panel_stylebox.bg_color = bg_primary_color
	theme.set_stylebox("panel", "ListItemOddPanel", list_item_odd_panel_stylebox)

	theme.add_type("ColorPanel")
	theme.set_type_variation("ColorPanel", "PanelContainer")
	var color_panel_stylebox: StyleBoxFlat = StyleBoxFlat.new()
	color_panel_stylebox.bg_color = bg_surface_color
	color_panel_stylebox.set_corner_radius_all(radius_md)
	color_panel_stylebox.set_content_margin_all(0)
	theme.set_stylebox("panel", "ColorPanel", color_panel_stylebox)


static func _setup_button(theme: Theme) -> void:
	theme.add_type("Button")
	theme.set_constant("h_separation", "Button", spacing_sm)
	theme.set_constant("icon_max_width", "Button", icon_xs)
	theme.set_color("font_color", "Button", text_primary_color)
	theme.set_color("font_disabled_color", "Button", text_muted_color)
	theme.set_color("font_focus_color", "Button", text_primary_color)
	theme.set_color("font_hover_color", "Button", text_primary_color)
	theme.set_color("font_pressed_color", "Button", text_primary_color)
	theme.set_color("font_hover_pressed_color", "Button", text_primary_color)
	theme.set_color("icon_normal_color", "Button", text_primary_color)
	theme.set_color("icon_hover_color", "Button", text_primary_color)
	theme.set_color("icon_pressed_color", "Button", text_primary_color)
	theme.set_color("icon_hover_pressed_color", "Button", text_primary_color)
	theme.set_color("icon_focus_color", "Button", text_primary_color)
	theme.set_color("icon_disabled_color", "Button", text_muted_color)
	theme.set_font_size("font_size", "Button", font_size_sm)

	var button_stylebox: StyleBoxFlat = StyleBoxFlat.new()
	button_stylebox.set_corner_radius_all(radius_sm)
	button_stylebox.content_margin_top = margin_sm.y
	button_stylebox.content_margin_bottom = margin_sm.y
	button_stylebox.content_margin_left = margin_sm.x
	button_stylebox.content_margin_right = margin_sm.x

	var normal_button_stylebox: StyleBoxFlat = button_stylebox.duplicate()
	normal_button_stylebox.draw_center = false
	theme.set_stylebox("normal", "Button", normal_button_stylebox)

	var hover_button_stylebox: StyleBoxFlat = button_stylebox.duplicate()
	hover_button_stylebox.bg_color = bg_elevated_color
	theme.set_stylebox("hover", "Button", hover_button_stylebox)

	var pressed_button_stylebox: StyleBoxFlat = button_stylebox.duplicate()
	pressed_button_stylebox.bg_color = bg_elevated_color
	theme.set_stylebox("pressed", "Button", pressed_button_stylebox)

	var hover_pressed_button_stylebox: StyleBoxFlat = button_stylebox.duplicate()
	hover_pressed_button_stylebox.bg_color = bg_elevated_color
	theme.set_stylebox("hover_pressed", "Button", hover_pressed_button_stylebox)

	var disabled_button_stylebox: StyleBoxFlat = button_stylebox.duplicate()
	disabled_button_stylebox.draw_center = false
	theme.set_stylebox("disabled", "Button", disabled_button_stylebox)

	var button_focus_stylebox: StyleBoxFlat = button_stylebox.duplicate()
	button_focus_stylebox.draw_center = false
	theme.set_stylebox("focus", "Button", button_focus_stylebox)

	theme.add_type("ToggleButton")
	theme.set_type_variation("ToggleButton", "Button")

	var pressed_toggle_button_stylebox: StyleBoxFlat = pressed_button_stylebox.duplicate()
	pressed_toggle_button_stylebox.bg_color = accent_color
	theme.set_stylebox("pressed", "ToggleButton", pressed_toggle_button_stylebox)

	var hover_pressed_toggle_button_stylebox: StyleBoxFlat = (
		hover_pressed_button_stylebox.duplicate()
	)
	hover_pressed_toggle_button_stylebox.bg_color = accent_color
	theme.set_stylebox("hover_pressed", "ToggleButton", hover_pressed_toggle_button_stylebox)

	theme.add_type("PlainButton")
	theme.set_type_variation("PlainButton", "Button")

	var normal_plain_button_stylebox: StyleBoxFlat = pressed_button_stylebox.duplicate()
	normal_plain_button_stylebox.bg_color = bg_elevated_color
	theme.set_stylebox("normal", "PlainButton", normal_plain_button_stylebox)

	theme.add_type("IconButton")
	theme.set_type_variation("IconButton", "Button")

	var normal_icon_button_stylebox: StyleBoxFlat = normal_button_stylebox.duplicate()
	normal_icon_button_stylebox.draw_center = true
	normal_icon_button_stylebox.bg_color = bg_elevated_color
	normal_icon_button_stylebox.set_content_margin_all(margin_sm.x)
	theme.set_stylebox("normal", "IconButton", normal_icon_button_stylebox)

	var hover_icon_button_stylebox: StyleBoxFlat = hover_button_stylebox.duplicate()
	hover_icon_button_stylebox.set_content_margin_all(margin_sm.x)
	theme.set_stylebox("hover", "IconButton", hover_icon_button_stylebox)

	var pressed_icon_button_stylebox: StyleBoxFlat = pressed_button_stylebox.duplicate()
	pressed_icon_button_stylebox.bg_color = accent_color
	pressed_icon_button_stylebox.set_content_margin_all(margin_sm.x)
	theme.set_stylebox("pressed", "IconButton", pressed_icon_button_stylebox)

	var hover_pressed_icon_button_stylebox: StyleBoxFlat = hover_pressed_button_stylebox.duplicate()
	hover_pressed_icon_button_stylebox.set_content_margin_all(margin_sm.x)
	theme.set_stylebox("hover_pressed", "IconButton", hover_pressed_icon_button_stylebox)

	var disabled_icon_button_stylebox: StyleBoxFlat = disabled_button_stylebox.duplicate()
	disabled_icon_button_stylebox.draw_center = true
	disabled_icon_button_stylebox.bg_color = bg_elevated_color
	disabled_icon_button_stylebox.set_content_margin_all(margin_sm.x)
	theme.set_stylebox("disabled", "IconButton", disabled_icon_button_stylebox)

	theme.add_type("ToggleIconButton")
	theme.set_type_variation("ToggleIconButton", "IconButton")

	var hover_pressed_toggle_icon_button_stylebox: StyleBoxFlat = (
		hover_pressed_icon_button_stylebox.duplicate()
	)
	hover_pressed_toggle_icon_button_stylebox.bg_color = accent_color
	theme.set_stylebox(
		"hover_pressed", "ToggleIconButton", hover_pressed_toggle_icon_button_stylebox
	)

	theme.add_type("ListItemIconButton")
	theme.set_type_variation("ListItemIconButton", "IconButton")
	theme.set_color("icon_normal_color", "ListItemIconButton", text_muted_color)
	theme.set_color("icon_hover_color", "ListItemIconButton", text_muted_color)
	theme.set_color("icon_pressed_color", "ListItemIconButton", text_muted_color)
	theme.set_color("icon_hover_pressed_color", "ListItemIconButton", text_muted_color)
	theme.set_color("icon_focus_color", "ListItemIconButton", text_muted_color)
	theme.set_color("icon_disabled_color", "ListItemIconButton", Color(text_muted_color, 0.5))

	var normal_list_item_icon_button_stylebox: StyleBoxFlat = (
		normal_icon_button_stylebox.duplicate()
	)
	normal_list_item_icon_button_stylebox.draw_center = false
	theme.set_stylebox("normal", "ListItemIconButton", normal_list_item_icon_button_stylebox)

	var hover_list_item_icon_button_stylebox: StyleBoxFlat = hover_icon_button_stylebox.duplicate()
	hover_list_item_icon_button_stylebox.draw_center = false
	theme.set_stylebox("hover", "ListItemIconButton", hover_list_item_icon_button_stylebox)

	var pressed_list_item_icon_button_stylebox: StyleBoxFlat = (
		pressed_icon_button_stylebox.duplicate()
	)
	pressed_list_item_icon_button_stylebox.draw_center = false
	theme.set_stylebox("pressed", "ListItemIconButton", pressed_list_item_icon_button_stylebox)

	var hover_pressed_list_item_icon_button_stylebox: StyleBoxFlat = (
		hover_pressed_icon_button_stylebox.duplicate()
	)
	hover_pressed_list_item_icon_button_stylebox.draw_center = false
	theme.set_stylebox(
		"hover_pressed", "ListItemIconButton", hover_pressed_list_item_icon_button_stylebox
	)

	var disabled_list_item_icon_button_stylebox: StyleBoxFlat = (
		disabled_icon_button_stylebox.duplicate()
	)
	disabled_list_item_icon_button_stylebox.draw_center = false
	theme.set_stylebox("disabled", "ListItemIconButton", disabled_list_item_icon_button_stylebox)


static func _setup_checkbox(theme: Theme) -> void:
	theme.add_type("CheckBox")
	theme.set_constant("h_separation", "CheckBox", spacing_sm)
	theme.set_constant("icon_max_width", "CheckBox", icon_lg)
	theme.set_color("font_color", "CheckBox", text_primary_color)
	theme.set_color("font_disabled_color", "CheckBox", text_muted_color)
	theme.set_color("font_focus_color", "CheckBox", text_primary_color)
	theme.set_color("font_hover_color", "CheckBox", text_primary_color)
	theme.set_color("font_pressed_color", "CheckBox", text_primary_color)
	theme.set_color("font_hover_pressed_color", "CheckBox", text_primary_color)

	var checked_texture: DPITexture = (
		DPITexture
		. create_from_string(
			(
				"""<svg width="20" height="20" viewBox="0 0 20 20" fill="none" xmlns="http://www.w3.org/2000/svg">
			<rect width="20" height="20" rx="{radius_sm}" fill="{bg_primary}"/>
			<path d="M5 10L7.53471 12.5427C8.73965 13.7514 10.7747 13.4241 11.5399 11.8985L15 5" stroke="{text_primary}" stroke-width="2" stroke-linecap="round"/>
		</svg>"""
				. format(_colormap_dict)
			)
		)
	)
	var checked_disabled_texture: DPITexture = (
		DPITexture
		. create_from_string(
			(
				"""<svg width="20" height="20" viewBox="0 0 20 20" fill="none" xmlns="http://www.w3.org/2000/svg">
			<rect width="20" height="20" rx="{radius_sm}" fill="{bg_higher}"/>
			<path d="M5 10L7.53471 12.5427C8.73965 13.7514 10.7747 13.4241 11.5399 11.8985L15 5" stroke="{text_muted}" stroke-width="2" stroke-linecap="round"/>
		</svg>"""
				. format(_colormap_dict)
			)
		)
	)
	var unchecked_texture: DPITexture = (
		DPITexture
		. create_from_string(
			(
				"""<svg width="20" height="20" viewBox="0 0 20 20" fill="none" xmlns="http://www.w3.org/2000/svg">
			<rect width="20" height="20" rx="{radius_sm}" fill="{bg_primary}"/>
		</svg>"""
				. format(_colormap_dict)
			)
		)
	)
	var unchecked_disabled_texture: DPITexture = (
		DPITexture
		. create_from_string(
			(
				"""<svg width="20" height="20" viewBox="0 0 20 20" fill="none" xmlns="http://www.w3.org/2000/svg">
			<rect width="20" height="20" rx="{radius_sm}" fill="{bg_higher}"/>
		</svg>"""
				. format(_colormap_dict)
			)
		)
	)

	theme.set_icon("checked", "CheckBox", checked_texture)
	theme.set_icon("checked_disabled", "CheckBox", checked_disabled_texture)
	theme.set_icon("unchecked", "CheckBox", unchecked_texture)
	theme.set_icon("unchecked_disabled", "CheckBox", unchecked_disabled_texture)

	var checkbox_stylebox: StyleBoxEmpty = StyleBoxEmpty.new()
	checkbox_stylebox.content_margin_top = margin_sm.y
	checkbox_stylebox.content_margin_bottom = margin_sm.y
	checkbox_stylebox.content_margin_left = margin_sm.x
	checkbox_stylebox.content_margin_right = margin_sm.x
	theme.set_stylebox("normal", "CheckBox", checkbox_stylebox)
	theme.set_stylebox("pressed", "CheckBox", checkbox_stylebox)
	theme.set_stylebox("hover", "CheckBox", checkbox_stylebox)
	theme.set_stylebox("hover_pressed", "CheckBox", checkbox_stylebox)
	theme.set_stylebox("focus", "CheckBox", checkbox_stylebox)
	theme.set_stylebox("disabled", "CheckBox", checkbox_stylebox)


static func _setup_optionbutton(theme: Theme) -> void:
	theme.add_type("OptionButton")
	theme.set_constant("h_separation", "OptionButton", spacing_sm)
	theme.set_constant("icon_max_width", "OptionButton", icon_xs)
	theme.set_constant("align_to_largest_style", "OptionButton", 1)
	theme.set_constant("arrow_margin", "OptionButton", spacing_sm)
	theme.set_constant("modulate_arrow", "OptionButton", 1)
	theme.set_font_size("font_size", "OptionButton", font_size_sm)
	theme.set_icon("arrow", "OptionButton", preload("res://ui/assets/icons/arrow_down.svg"))

	var stylebox: StyleBoxFlat = StyleBoxFlat.new()
	stylebox.set_corner_radius_all(radius_sm)
	stylebox.content_margin_top = margin_md.y
	stylebox.content_margin_bottom = margin_md.y
	stylebox.content_margin_left = margin_md.x
	stylebox.content_margin_right = margin_md.x

	var normal_stylebox: StyleBoxFlat = stylebox.duplicate()
	normal_stylebox.bg_color = bg_elevated_color
	theme.set_stylebox("normal", "OptionButton", normal_stylebox)
	theme.set_stylebox("pressed", "OptionButton", normal_stylebox)
	theme.set_stylebox("hover_pressed", "OptionButton", normal_stylebox)

	var focus_stylebox: StyleBoxEmpty = StyleBoxEmpty.new()
	theme.set_stylebox("focus", "OptionButton", focus_stylebox)

	var hover_stylebox: StyleBoxFlat = stylebox.duplicate()
	hover_stylebox.bg_color = bg_elevated_color
	theme.set_stylebox("hover", "OptionButton", hover_stylebox)

	var disabled_stylebox: StyleBoxFlat = stylebox.duplicate()
	disabled_stylebox.bg_color = bg_primary_color
	theme.set_stylebox("disabled", "OptionButton", disabled_stylebox)


static func _setup_lineedit(theme: Theme) -> void:
	theme.add_type("LineEdit")
	theme.set_color("caret_color", "LineEdit", text_primary_color)
	theme.set_color("font_color", "LineEdit", text_primary_color)
	theme.set_color("font_uneditable_color", "LineEdit", text_muted_color)
	theme.set_color("font_placeholder_color", "LineEdit", text_muted_color)
	theme.set_color("selection_color", "LineEdit", selection_color)
	theme.set_color("disabled_selection_color", "LineEdit", selection_color)
	theme.set_font_size("font_size", "LineEdit", font_size_sm)
	theme.set_font("font", "LineEdit", font_main)

	var stylebox: StyleBoxFlat = StyleBoxFlat.new()
	stylebox.set_corner_radius_all(radius_sm)
	stylebox.content_margin_top = margin_md.y
	stylebox.content_margin_bottom = margin_md.y
	stylebox.content_margin_left = margin_md.x
	stylebox.content_margin_right = margin_md.x

	var disabled_stylebox: StyleBoxFlat = stylebox.duplicate()
	disabled_stylebox.bg_color = bg_elevated_color
	theme.set_stylebox("read_only", "LineEdit", disabled_stylebox)

	var normal_stylebox: StyleBoxFlat = stylebox.duplicate()
	normal_stylebox.bg_color = bg_primary_color
	theme.set_stylebox("normal", "LineEdit", normal_stylebox)

	var hover_stylebox: StyleBoxFlat = stylebox.duplicate()
	hover_stylebox.draw_center = false
	theme.set_stylebox("hover", "LineEdit", hover_stylebox)

	var focus_stylebox: StyleBoxEmpty = StyleBoxEmpty.new()
	theme.set_stylebox("focus", "LineEdit", focus_stylebox)

	theme.add_type("LineEditListItemPreview")
	theme.set_type_variation("LineEditListItemPreview", "LineEdit")

	var disabled_preview_stylebox: StyleBoxFlat = disabled_stylebox.duplicate()
	disabled_preview_stylebox.bg_color = bg_surface_color
	theme.set_stylebox("read_only", "LineEditListItemPreview", disabled_preview_stylebox)

	var normal_preview_stylebox: StyleBoxFlat = normal_stylebox.duplicate()
	normal_preview_stylebox.bg_color = bg_elevated_color
	theme.set_stylebox("normal", "LineEditListItemPreview", normal_preview_stylebox)

	var hover_preview_stylebox: StyleBoxFlat = hover_stylebox.duplicate()
	theme.set_stylebox("hover", "LineEditListItemPreview", hover_preview_stylebox)

	var focus_preview_stylebox: StyleBoxEmpty = focus_stylebox.duplicate()
	theme.set_stylebox("focus", "LineEditListItemPreview", focus_preview_stylebox)


static func _setup_scrollbar(theme: Theme) -> void:
	theme.add_type("HScrollBar")
	theme.add_type("VScrollBar")
	var stylebox: StyleBoxFlat = StyleBoxFlat.new()
	stylebox.set_corner_radius_all(1)
	stylebox.content_margin_left = 1.0
	stylebox.content_margin_right = 1.0

	var grabber_stylebox: StyleBoxFlat = stylebox.duplicate()
	grabber_stylebox.bg_color = border_color
	theme.set_stylebox("grabber", "HScrollBar", grabber_stylebox)
	theme.set_stylebox("grabber", "VScrollBar", grabber_stylebox)

	var grabber_stylebox_pressed: StyleBoxFlat = stylebox.duplicate()
	grabber_stylebox_pressed.bg_color = text_muted_color
	theme.set_stylebox("grabber_highlight", "HScrollBar", grabber_stylebox_pressed)
	theme.set_stylebox("grabber_pressed", "HScrollBar", grabber_stylebox_pressed)
	theme.set_stylebox("grabber_highlight", "VScrollBar", grabber_stylebox_pressed)
	theme.set_stylebox("grabber_pressed", "VScrollBar", grabber_stylebox_pressed)

	var h_scroll_stylebox: StyleBoxFlat = StyleBoxFlat.new()
	h_scroll_stylebox.set_corner_radius_all(3)
	h_scroll_stylebox.content_margin_top = margin_sm.y
	h_scroll_stylebox.content_margin_bottom = margin_sm.y
	h_scroll_stylebox.content_margin_left = margin_sm.x
	h_scroll_stylebox.content_margin_right = margin_sm.x
	h_scroll_stylebox.draw_center = false
	theme.set_stylebox("scroll", "HScrollBar", h_scroll_stylebox)

	var v_scroll_stylebox: StyleBoxFlat = StyleBoxFlat.new()
	v_scroll_stylebox.set_corner_radius_all(3)
	v_scroll_stylebox.content_margin_top = margin_sm.x
	v_scroll_stylebox.content_margin_bottom = margin_sm.x
	v_scroll_stylebox.content_margin_left = margin_sm.y
	v_scroll_stylebox.content_margin_right = margin_sm.y
	v_scroll_stylebox.draw_center = false
	theme.set_stylebox("scroll", "VScrollBar", v_scroll_stylebox)


static func _setup_separator(theme: Theme) -> void:
	theme.add_type("HSeparator")
	var h_stylebox: StyleBoxLine = StyleBoxLine.new()
	h_stylebox.color = border_color
	h_stylebox.thickness = 1
	theme.set_stylebox("separator", "HSeparator", h_stylebox)

	theme.add_type("SmallHSeparator")
	theme.set_type_variation("SmallHSeparator", "HSeparator")
	var h_small_stylebox: StyleBoxLine = h_stylebox.duplicate()
	h_small_stylebox.grow_begin = -spacing_sm
	h_small_stylebox.grow_end = -spacing_sm
	theme.set_stylebox("separator", "SmallHSeparator", h_small_stylebox)

	theme.add_type("WideHSeparator")
	theme.set_type_variation("SmallHSeparator", "HSeparator")
	var h_wide_stylebox: StyleBoxLine = h_stylebox.duplicate()
	h_wide_stylebox.grow_begin = spacing_sm
	h_wide_stylebox.grow_end = spacing_sm
	theme.set_stylebox("separator", "SmallHSeparator", h_wide_stylebox)

	theme.add_type("UltraWideHSeparator")
	theme.set_type_variation("UltraWideHSeparator", "HSeparator")
	var h_ultra_wide_stylebox: StyleBoxLine = h_stylebox.duplicate()
	h_ultra_wide_stylebox.grow_begin = spacing_lg
	h_ultra_wide_stylebox.grow_end = spacing_lg
	theme.set_stylebox("separator", "UltraWideHSeparator", h_ultra_wide_stylebox)

	theme.add_type("VSeparator")
	var v_stylebox: StyleBoxLine = h_stylebox.duplicate()
	v_stylebox.vertical = true
	theme.set_stylebox("separator", "VSeparator", v_stylebox)

	theme.add_type("SmallVSeparator")
	theme.set_type_variation("SmallVSeparator", "VSeparator")
	var v_small_stylebox: StyleBoxLine = v_stylebox.duplicate()
	v_small_stylebox.vertical = true
	theme.set_stylebox("separator", "SmallVSeparator", v_small_stylebox)


static func _setup_margincontainer(theme: Theme) -> void:
	theme.add_type("MarginContainer")
	theme.set_constant("margin_left", "MarginContainer", spacing_sm)
	theme.set_constant("margin_top", "MarginContainer", spacing_sm)
	theme.set_constant("margin_right", "MarginContainer", spacing_sm)
	theme.set_constant("margin_bottom", "MarginContainer", spacing_sm)

	theme.add_type("MediumMarginContainer")
	theme.set_type_variation("MediumMarginContainer", "MarginContainer")
	theme.set_constant("margin_left", "MarginContainer", spacing_md)
	theme.set_constant("margin_top", "MarginContainer", spacing_md)
	theme.set_constant("margin_right", "MarginContainer", spacing_md)
	theme.set_constant("margin_bottom", "MarginContainer", spacing_md)


static func _setup_label(theme: Theme) -> void:
	var stylebox: StyleBoxEmpty = StyleBoxEmpty.new()
	stylebox.content_margin_top = margin_md.y
	stylebox.content_margin_bottom = margin_md.y

	theme.add_type("Label")
	theme.set_font("font", "Label", font_main)
	theme.set_color("font_color", "Label", text_primary_color)
	theme.set_font_size("font_size", "Label", font_size_md)
	# TODO: Differenciate more labels.
	#theme.set_stylebox("normal", "Label", stylebox)

	theme.add_type("TitleLabel")
	theme.set_type_variation("TitleLabel", "Label")
	theme.set_font_size("font_size", "TitleLabel", font_size_sm)
	theme.set_color("font_color", "TitleLabel", text_muted_color)

	theme.add_type("NoteLabel")
	theme.set_type_variation("NoteLabel", "Label")
	theme.set_color("font_color", "NoteLabel", text_muted_color)

	theme.add_type("WarnLabel")
	theme.set_type_variation("WarnLabel", "Label")
	theme.set_color("font_color", "WarnLabel", fail_color)
	theme.set_font_size("font_size", "WarnLabel", font_size_md)

	theme.add_type("GraphNodeViewTitleLabel")
	theme.set_type_variation("GraphNodeViewTitleLabel", "Label")
	theme.set_color("font_color", "GraphNodeViewTitleLabel", text_muted_color)
	theme.set_font_size("font_size", "GraphNodeViewTitleLabel", font_size_lg)

	theme.add_type("GraphNodeViewValueLabel")
	theme.set_type_variation("GraphNodeViewValueLabel", "Label")
	theme.set_color("font_color", "GraphNodeViewValueLabel", text_primary_color)
	theme.set_font_size("font_size", "GraphNodeViewValueLabel", font_size_md)

	theme.add_type("TooltipLabel")
	theme.set_color("font_color", "TooltipLabel", text_primary_color)
	theme.set_font_size("font_size", "TooltipLabel", font_size_sm)
	theme.set_font("font", "TooltipLabel", font_main)


static func _setup_textedit(theme: Theme) -> void:
	theme.add_type("TextEdit")
	theme.set_color("search_result_color", "TextEdit", accent_color)
	theme.set_color("search_result_border", "TextEdit", Color.TRANSPARENT)
	theme.set_color("caret_color", "TextEdit", text_primary_color)
	theme.set_color("caret_background_color", "TextEdit", bg_primary_color)
	theme.set_color("selection_color", "TextEdit", selection_color)
	theme.set_color("font_color", "TextEdit", text_primary_color)
	theme.set_color("font_readonly_color", "TextEdit", text_muted_color)
	theme.set_color("font_placeholder_color", "TextEdit", text_muted_color)
	theme.set_font("font", "TextEdit", font_main)
	theme.set_font_size("font_size", "TextEdit", font_size_sm)

	var normal_stylebox: StyleBoxFlat = StyleBoxFlat.new()
	normal_stylebox.bg_color = bg_primary_color
	normal_stylebox.set_corner_radius_all(radius_sm)
	normal_stylebox.content_margin_top = margin_sm.y
	normal_stylebox.content_margin_bottom = margin_sm.y
	normal_stylebox.content_margin_left = margin_sm.x
	normal_stylebox.content_margin_right = margin_sm.x
	theme.set_stylebox("normal", "TextEdit", normal_stylebox)

	var focus_stylebox: StyleBoxEmpty = StyleBoxEmpty.new()
	theme.set_stylebox("focus", "TextEdit", focus_stylebox)

	var disabled_stylebox: StyleBoxFlat = normal_stylebox.duplicate()
	disabled_stylebox.bg_color = bg_elevated_color
	theme.set_stylebox("read_only", "TextEdit", disabled_stylebox)


static func _setup_richtextlabel(theme: Theme) -> void:
	theme.add_type("RichTextLabel")
	theme.set_color("default_color", "RichTextLabel", text_primary_color)
	theme.set_color("selection_color", "RichTextLabel", selection_color)
	theme.set_color("table_odd_row_bg", "RichTextLabel", Color(bg_higher_color, 0.25))
	theme.set_color("table_even_row_bg", "RichTextLabel", Color(bg_higher_color, 0.1))
	theme.set_color("table_border", "RichTextLabel", border_color)
	theme.set_font_size("normal_font_size", "RichTextLabel", font_size_sm)
	theme.set_font_size("bold_font_size", "RichTextLabel", font_size_sm)
	theme.set_font_size("bold_italics_font_size", "RichTextLabel", font_size_sm)
	theme.set_font_size("italics_font_size", "RichTextLabel", font_size_sm)
	theme.set_font_size("mono_font_size", "RichTextLabel", font_size_sm)


static func _setup_foldablecontainer(theme: Theme) -> void:
	theme.add_type("FoldableContainer")
	theme.set_color("font_color", "FoldableContainer", text_muted_color)
	theme.set_color("hover_font_color", "FoldableContainer", text_muted_color)
	theme.set_color("collapsed_font_color", "FoldableContainer", text_muted_color)
	theme.set_constant("h_separation", "FoldableContainer", spacing_md)
	theme.set_font_size("font_size", "FoldableContainer", font_size_sm)
	theme.set_icon(
		"expanded_arrow", "FoldableContainer", preload("res://ui/assets/icons/expanded_arrow.svg")
	)
	theme.set_icon(
		"expanded_arrow_mirrored",
		"FoldableContainer",
		preload("res://ui/assets/icons/expanded_arrow_mirrored.svg")
	)
	theme.set_icon("folded_arrow", "FoldableContainer", folded_arrow_icon)
	theme.set_icon("folded_arrow_mirrored", "FoldableContainer", folded_arrow_mirrored_icon)

	var title_panel_stylebox: StyleBoxFlat = StyleBoxFlat.new()
	title_panel_stylebox.bg_color = bg_surface_color
	title_panel_stylebox.content_margin_top = margin_sm.y
	title_panel_stylebox.content_margin_bottom = margin_sm.y
	title_panel_stylebox.content_margin_left = margin_sm.x
	title_panel_stylebox.content_margin_right = margin_sm.x
	theme.set_stylebox("title_panel", "FoldableContainer", title_panel_stylebox)

	var title_hover_panel_stylebox: StyleBoxFlat = title_panel_stylebox.duplicate()
	theme.set_stylebox("title_hover_panel", "FoldableContainer", title_hover_panel_stylebox)

	var title_collapsed_panel_stylebox: StyleBoxFlat = title_panel_stylebox.duplicate()
	theme.set_stylebox("title_collapsed_panel", "FoldableContainer", title_collapsed_panel_stylebox)

	var title_collapsed_hover_panel_stylebox: StyleBoxFlat = (
		title_collapsed_panel_stylebox.duplicate()
	)
	theme.set_stylebox(
		"title_collapsed_hover_panel", "FoldableContainer", title_collapsed_hover_panel_stylebox
	)

	var panel_stylebox: StyleBoxFlat = StyleBoxFlat.new()
	panel_stylebox.bg_color = bg_surface_color
	panel_stylebox.content_margin_top = margin_sm.y
	panel_stylebox.content_margin_bottom = margin_sm.y
	panel_stylebox.content_margin_left = margin_sm.x
	panel_stylebox.content_margin_right = margin_sm.x
	theme.set_stylebox("panel", "FoldableContainer", panel_stylebox)

	var focus_stylebox: StyleBoxEmpty = StyleBoxEmpty.new()
	theme.set_stylebox("focus", "FoldableContainer", focus_stylebox)

	theme.add_type("ProjectFoldableContainer")
	theme.set_type_variation("ProjectFoldableContainer", "FoldableContainer")


static func _setup_boxcontainer(theme: Theme) -> void:
	theme.add_type("HBoxContainer")
	theme.set_constant("separation", "HBoxContainer", spacing_sm)

	theme.add_type("HBoxContainerMedium")
	theme.set_type_variation("HBoxContainerMedium", "HBoxContainer")
	theme.set_constant("separation", "HBoxContainerMedium", spacing_md)

	theme.add_type("HBoxContainerLarge")
	theme.set_type_variation("HBoxContainerLarge", "HBoxContainer")
	theme.set_constant("separation", "HBoxContainerLarge", spacing_lg)

	theme.add_type("HBoxContainerCompact")
	theme.set_type_variation("HBoxContainerCompact", "HBoxContainer")
	theme.set_constant("separation", "HBoxContainerCompact", 0)

	theme.add_type("VBoxContainer")
	theme.set_constant("separation", "VBoxContainer", spacing_sm)

	theme.add_type("VBoxContainerMedium")
	theme.set_type_variation("VBoxContainerMedium", "VBoxContainer")
	theme.set_constant("separation", "VBoxContainerMedium", spacing_md)

	theme.add_type("VBoxContainerLarge")
	theme.set_type_variation("VBoxContainerLarge", "VBoxContainer")
	theme.set_constant("separation", "VBoxContainerLarge", spacing_lg)

	theme.add_type("VBoxContainerCompact")
	theme.set_type_variation("VBoxContainerCompact", "VBoxContainer")
	theme.set_constant("separation", "VBoxContainerCompact", 0)


static func _setup_graphnode(theme: Theme) -> void:
	theme.add_type("GraphNode")
	theme.set_constant("separation", "GraphNode", spacing_sm)

	var panel_stylebox: StyleBoxFlat = StyleBoxFlat.new()
	panel_stylebox.set_corner_radius_all(radius_md)
	panel_stylebox.set_border_width_all(1)
	panel_stylebox.bg_color = bg_surface_color
	panel_stylebox.content_margin_top = margin_md.y
	panel_stylebox.content_margin_bottom = margin_md.y
	panel_stylebox.content_margin_left = margin_md.x
	panel_stylebox.content_margin_right = margin_md.x
	panel_stylebox.border_color = border_color
	panel_stylebox.shadow_color = Color("000000", 0.1)
	panel_stylebox.shadow_size = 12

	var panel_selected_stylebox: StyleBoxFlat = panel_stylebox.duplicate()
	panel_selected_stylebox.bg_color = bg_elevated_color
	panel_selected_stylebox.border_color = bg_elevated_color

	theme.set_stylebox("panel", "GraphNode", panel_stylebox)
	theme.set_stylebox("panel_selected", "GraphNode", panel_selected_stylebox)
	theme.set_stylebox("titlebar", "GraphNode", StyleBoxEmpty.new())
	theme.set_stylebox("titlebar_selected", "GraphNode", StyleBoxEmpty.new())
	theme.set_stylebox("slot", "GraphNode", StyleBoxEmpty.new())


static func _setup_graphedit(theme: Theme) -> void:
	theme.add_type("GraphEdit")
	theme.set_color("grid_major", "GraphEdit", Color("ffffff", 0.1))
	theme.set_color("grid_minor", "GraphEdit", Color("ffffff", 0.1))

	var stylebox := StyleBoxFlat.new()
	stylebox.bg_color = bg_primary_color
	stylebox.set_corner_radius_all(0)
	theme.set_stylebox("panel", "GraphEdit", stylebox)


static func _setup_splitcontainer(theme: Theme) -> void:
	theme.add_type("SplitContainer")
	theme.set_constant("separation", "SplitContainer", spacing_md)
	theme.set_constant("minimum_grab_thickness", "SplitContainer", spacing_lg)


static func _setup_tree(theme: Theme) -> void:
	theme.add_type("Tree")
	theme.set_constant("icon_max_width", "Tree", 14)
	theme.set_constant("h_separation", "Tree", margin_sm.x as int)
	theme.set_constant("v_separation", "Tree", margin_sm.y as int)
	theme.set_constant("inner_item_margin_bottom", "Tree", margin_sm.x as int)
	theme.set_constant("inner_item_margin_left", "Tree", margin_sm.x as int)
	theme.set_constant("inner_item_margin_top", "Tree", margin_sm.x as int)
	theme.set_constant("inner_item_margin_right", "Tree", margin_sm.x as int)
	theme.set_constant("draw_relationship_lines", "Tree", 1)
	theme.set_constant("draw_guides", "Tree", 0)
	theme.set_constant("relationship_line_width", "Tree", 0)
	theme.set_constant("parent_hl_line_width", "Tree", 1)
	theme.set_constant("children_hl_line_width", "Tree", 0)
	theme.set_icon("checked", "Tree", preload("res://ui/assets/icons/checked.svg"))
	#theme.set_icon("unchecked", "Tree", preload("res://ui/assets/icons/unchecked.svg"))
	theme.set_icon(
		"checked_disabled", "Tree", preload("res://ui/assets/icons/checked_disabled.svg")
	)
	#theme.set_icon(
	#"unchecked_disabled",
	#"Tree",
	#preload("res://ui/assets/icons/unchecked_disabled.svg")
	#)

	var tree_stylebox: StyleBoxFlat = StyleBoxFlat.new()
	tree_stylebox.bg_color = bg_surface_color
	tree_stylebox.set_corner_radius_all(radius_sm)
	tree_stylebox.content_margin_top = margin_sm.y
	tree_stylebox.content_margin_bottom = margin_sm.y
	tree_stylebox.content_margin_left = margin_sm.x
	tree_stylebox.content_margin_right = margin_sm.x
	theme.set_stylebox("panel", "Tree", tree_stylebox)


static func _setup_popupmenu(theme: Theme) -> void:
	theme.add_type("PopupMenu")
	theme.set_color("font_color", "PopupMenu", text_primary_color)
	theme.set_color("font_accelerator_color", "PopupMenu", text_muted_color)
	theme.set_color("font_disabled_color", "PopupMenu", text_muted_color)
	theme.set_color("font_hover_color", "PopupMenu", text_primary_color)
	theme.set_color("font_separator_color", "PopupMenu", border_color)
	theme.set_constant("indent", "PopupMenu", spacing_md)
	theme.set_constant("h_separation", "PopupMenu", int(margin_md.x))
	theme.set_constant("v_separation", "PopupMenu", int(margin_md.y))
	theme.set_constant("outline_size", "PopupMenu", 0)
	theme.set_constant("separator_outline_size", "PopupMenu", 0)
	theme.set_constant("item_start_padding", "PopupMenu", int(margin_md.x))
	theme.set_constant("item_end_padding", "PopupMenu", int(margin_md.x))
	theme.set_constant("icon_max_width", "PopupMenu", icon_xs)
	theme.set_constant("gutter_compact", "PopupMenu", 0)
	theme.set_font("font", "PopupMenu", font_main)
	theme.set_font("font_separator", "PopupMenu", font_main)
	theme.set_font_size("font_size", "PopupMenu", font_size_sm)
	theme.set_font_size("font_separator_size", "PopupMenu", font_size_sm)

	# preload() hands back the cached resource instance, so each recoloured icon takes a
	# duplicate() of its source. color_map is assigned whole rather than mutated in place:
	# only the setter re-rasterises the SVG, and it early-outs when handed the dictionary
	# it already holds, so `icon.color_map[key] = value` alone is a no-op.
	var menu_checked_source: DPITexture = preload("res://ui/assets/theme/menu_checked.svg")

	var menu_checked_icon: DPITexture = menu_checked_source.duplicate()
	menu_checked_icon.color_map = {Color.WHITE: text_primary_color, Color.BLACK: bg_primary_color}
	theme.set_icon("checked", "PopupMenu", menu_checked_icon)

	var menu_checked_disabled_icon: DPITexture = menu_checked_source.duplicate()
	menu_checked_disabled_icon.color_map = {
		Color.WHITE: text_muted_color, Color.BLACK: bg_primary_color
	}
	theme.set_icon("checked_disabled", "PopupMenu", menu_checked_disabled_icon)

	var menu_unchecked_source: DPITexture = preload("res://ui/assets/theme/menu_unchecked.svg")

	var menu_unchecked_icon: DPITexture = menu_unchecked_source.duplicate()
	menu_unchecked_icon.color_map = {Color.WHITE: text_muted_color}
	theme.set_icon("unchecked", "PopupMenu", menu_unchecked_icon)

	var menu_unchecked_disabled_icon: DPITexture = menu_unchecked_source.duplicate()
	menu_unchecked_disabled_icon.color_map = {Color.WHITE: text_muted_color}
	theme.set_icon("unchecked_disabled", "PopupMenu", menu_unchecked_disabled_icon)

	theme.set_icon("radio_checked", "PopupMenu", radio_checked_icon)

	var menu_radio_checked_disabled_icon: DPITexture = (
		preload("res://ui/assets/theme/menu_radio_checked.svg").duplicate()
	)
	menu_radio_checked_disabled_icon.color_map = {
		Color.WHITE: text_muted_color, Color.BLACK: bg_primary_color
	}
	theme.set_icon("radio_checked_disabled", "PopupMenu", menu_radio_checked_disabled_icon)

	theme.set_icon("radio_unchecked", "PopupMenu", radio_unchecked_icon)

	var menu_radio_unchecked_disabled_icon: DPITexture = (
		preload("res://ui/assets/theme/menu_radio_unchecked.svg").duplicate()
	)
	menu_radio_unchecked_disabled_icon.color_map = {Color.WHITE: text_muted_color}
	theme.set_icon("radio_unchecked_disabled", "PopupMenu", menu_radio_unchecked_disabled_icon)

	theme.set_icon("submenu", "PopupMenu", folded_arrow_icon)
	theme.set_icon("submenu_mirrored", "PopupMenu", folded_arrow_mirrored_icon)

	var panel_stylebox: StyleBoxFlat = StyleBoxFlat.new()
	panel_stylebox.bg_color = bg_primary_color
	panel_stylebox.set_corner_radius_all(radius_md)
	panel_stylebox.set_border_width_all(1)
	panel_stylebox.border_color = border_color
	panel_stylebox.content_margin_top = margin_md.y
	panel_stylebox.content_margin_bottom = margin_md.y
	panel_stylebox.content_margin_left = margin_md.x
	panel_stylebox.content_margin_right = margin_md.x
	theme.set_stylebox("panel", "PopupMenu", panel_stylebox)

	var hover_stylebox: StyleBoxFlat = StyleBoxFlat.new()
	hover_stylebox.bg_color = bg_surface_color
	panel_stylebox.set_corner_radius_all(radius_sm)
	panel_stylebox.set_border_width_all(1)
	panel_stylebox.border_color = border_color
	panel_stylebox.content_margin_top = margin_md.y
	panel_stylebox.content_margin_bottom = margin_md.y
	panel_stylebox.content_margin_left = margin_md.x
	panel_stylebox.content_margin_right = margin_md.x
	theme.set_stylebox("hover", "PopupMenu", hover_stylebox)

	var separator_stylebox: StyleBoxLine = StyleBoxLine.new()
	separator_stylebox.color = border_color
	separator_stylebox.thickness = 1
	theme.set_stylebox("separator", "PopupMenu", separator_stylebox)
	theme.set_stylebox("labeled_separator_left", "PopupMenu", separator_stylebox)
	theme.set_stylebox("labeled_separator_right", "PopupMenu", separator_stylebox)
