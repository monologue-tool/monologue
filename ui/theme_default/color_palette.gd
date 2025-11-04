@tool
class_name ThemeColorPalette extends RefCounted
## A semantic color palette for the Monologue theme.
## Provides clear, direct color definitions without opacity/contrast calculations.

# Base colors - defined by user preference
var background: Color = Color("1a1a1f")  # Main background
var text: Color = Color("e3e4eb")  # Primary text color
var primary: Color = Color("a9a8c0")  # Primary UI elements
var secondary: Color = Color("676278")  # Secondary UI elements
var accent: Color = Color("d15050")  # Accent/highlight color
var warning: Color = Color("c42e40")  # Warning/danger color

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
	# Surface colors - lighter than background for elevation
	surface = background.lightened(0.08)
	surface_variant = background.lightened(0.12)
	
	# Border color - subtle, based on text color
	border = Color(text, 0.15)
	
	# Text variations
	text_secondary = Color(text, 0.7)
	text_disabled = Color(text, 0.3)
	
	# Interactive overlays - semi-transparent for layering
	hover_overlay = Color(1, 1, 1, 0.05)
	pressed_overlay = Color(1, 1, 1, 0.1)
	disabled_overlay = Color(0, 0, 0, 0.5)
	
	# UI element colors - direct, no calculations needed at use site
	button_background = primary
	button_hover = primary.lightened(0.1)
	button_pressed = primary.lightened(0.15)
	
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
