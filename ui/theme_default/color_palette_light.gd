@tool
class_name ThemeColorPaletteLight extends RefCounted
## A light semantic color palette for the Monologue theme.

# Base colors - light theme variant
var text: Color = Color("1a1a1f")  # Dark text for light background
var primary: Color = Color.from_hsv(0.667, 0.08, 0.92, 1.0)  # Light purple-gray
var secondary: Color = Color.from_hsv(0.661, 0.10, 0.88, 1.0)  # Slightly darker for contrast
var graph_bg: Color = Color.from_hsv(0.656, 0.05, 0.95, 1.0)  # Very light background
var accent: Color = Color("d86568")  # Lighter red for light theme
var warning: Color = Color("e84454")  # Brighter warning color

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
	# Surface colors - slightly darker than background for definition
	surface = primary
	surface_variant = secondary
	
	# Border color - more visible in light theme
	border = primary
	
	# Text variations - adjusted for light background
	text_secondary = Color(text, 0.65)
	text_disabled = Color(text, 0.4)
	
	# Interactive overlays - darkening for light theme
	hover_overlay = secondary.darkened(0.05)
	pressed_overlay = secondary.darkened(0.1)
	disabled_overlay = secondary.lightened(0.2)
	
	# UI element colors - harmonized for light theme
	button_background = secondary
	button_hover = secondary.darkened(0.05)
	button_pressed = secondary.darkened(0.1)
	
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
