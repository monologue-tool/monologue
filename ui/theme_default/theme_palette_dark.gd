@tool
class_name ThemePaletteDark extends RefCounted
## Dark theme palette for Monologue with semantic color definitions

# Base colors - defined by user preference
#var background: Color = Color("2c2c2c")
var text: Color = Color("e3e4eb")
var primary: Color = Color.from_hsv(0.667, 0.12, 0.14, 1.0)
var secondary: Color = Color.from_hsv(0.661, 0.15, 0.19, 1.0)  # Fields etc..
var graph_bg: Color = Color.from_hsv(0.656, 0.10, 0.10, 1.0)
var accent: Color = Color("af4548")
var warning: Color = Color("c42e40")

# Semantic colors - derived from base colors for specific purposes
var surface: Color  # Primary surface (panels, containers)
var surface_variant: Color  # Secondary surface (inputs, fields)
var border: Color  # Borders and separators
var text_secondary: Color  # Secondary/dimmed text
var text_disabled: Color  # Disabled text

# Interactive state colors
var hover_overlay: Color  # Overlay for hover states
var pressed_overlay: Color  # Overlay for pressed states
var disabled_overlay: Color  # Overlay for disabled states

# UI element specific colors
var button_background: Color
var button_hover: Color
var button_pressed: Color
var input_background: Color
var panel_background: Color


func _init() -> void:
	_calculate_semantic_colors()


## Calculates semantic colors from base colors
func _calculate_semantic_colors() -> void:
	# Surface colors - lighter than background for elevation with better distinction
	surface = primary
	surface_variant = secondary

	# Border color - slightly more visible for better UI definition
	border = primary

	# Text variations - adjusted for better readability hierarchy
	text_secondary = Color(text, 0.75)
	text_disabled = Color(text, 0.35)

	# Interactive overlays - subtle but noticeable
	hover_overlay = secondary.lightened(0.02)
	pressed_overlay = secondary.lightened(0.05)
	disabled_overlay = secondary.lightened(0.25)

	# UI element colors - harmonized with better visual feedback
	button_background = secondary
	button_hover = secondary.lightened(0.02)
	button_pressed = secondary.lightened(0.05)

	input_background = surface_variant
	panel_background = surface


## Creates a lighter variant of a color
func lighten(color: Color, amount: float = 0.1) -> Color:
	return color.lightened(amount)


## Creates a darker variant of a color
func darken(color: Color, amount: float = 0.1) -> Color:
	return color.darkened(amount)


## Creates a color with adjusted alpha
func with_alpha(color: Color, alpha: float) -> Color:
	return Color(color, alpha)
