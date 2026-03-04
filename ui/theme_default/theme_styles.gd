@tool
class_name ThemeStyles extends RefCounted
## Utility class for creating common StyleBox objects with consistent parameters

var settings: ThemeSettings
var base_spacing: int = 6
var corner_radius: int = 5
var border_width: int = 1


func _init(color_settings: ThemeSettings) -> void:
	settings = color_settings


## Creates a basic panel StyleBoxFlat
func create_panel(bg_color: Color, with_border: bool = false) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.set_corner_radius_all(corner_radius)
	style.set_content_margin_all(base_spacing)

	if with_border:
		style.set_border_width_all(border_width)
		style.border_color = settings.border

	return style


## Creates a button StyleBoxFlat
func create_button(bg_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.set_corner_radius_all(corner_radius)
	style.content_margin_left = base_spacing * 2.0
	style.content_margin_right = base_spacing * 2.0
	style.content_margin_top = base_spacing
	style.content_margin_bottom = base_spacing
	return style


## Creates an input field StyleBoxFlat
func create_input(bg_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.set_corner_radius_all(corner_radius)
	style.content_margin_left = base_spacing * 2.0
	style.content_margin_right = base_spacing * 2.0
	style.content_margin_top = base_spacing
	style.content_margin_bottom = base_spacing
	#style.set_border_width_all(border_width)
	style.border_color = settings.border
	return style


## Creates an empty StyleBoxFlat (no background)
func create_empty() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.draw_center = false
	style.set_content_margin_all(base_spacing)
	style.set_corner_radius_all(corner_radius)
	return style


## Creates a separator StyleBoxLine
func create_separator(vertical: bool = false) -> StyleBoxLine:
	var style := StyleBoxLine.new()
	style.color = settings.border
	style.vertical = vertical
	style.grow_begin = 0
	style.grow_end = 0
	return style
