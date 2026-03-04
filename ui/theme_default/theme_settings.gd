@abstract
class_name ThemeSettings extends RefCounted

var text: Color = Color("e3e4eb")
var primary: Color = Color.from_hsv(0.667, 0.12, 0.14, 1.0)
var secondary: Color = Color.from_hsv(0.661, 0.15, 0.19, 1.0)
var tertiary: Color = Color.from_hsv(0.656, 0.10, 0.10, 1.0)
var accent: Color = Color("af4548")
var warning: Color = Color("c42e40")

# Semantic colors - derived from base colors for  purposes
var surface: Color        # Primary surface (panels, containers)
var surface_variant: Color  # Secondary surface (inputs, fields)
var border: Color           # Subtle alpha-based borders
var border_strong: Color    # Focused / selected borders
var text_secondary: Color  # Secondary/dimmed text
var text_disabled: Color   # Disabled text

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
	define_settings()
	_calculate_semantic_colors()


@abstract func define_settings() -> void
@abstract func get_path() -> String


## Calculates semantic colors from base colors
func _calculate_semantic_colors() -> void:
	surface = primary
	surface_variant = secondary

	# Alpha-based borders: subtle panel edges without heavy outlines
	border = Color(text, 0.08)
	border_strong = Color(text, 0.18)

	text_secondary = Color(text, 0.70)
	text_disabled = Color(text, 0.35)

	hover_overlay = secondary.lightened(0.035)
	pressed_overlay = secondary.lightened(0.07)
	disabled_overlay = secondary.lightened(0.20)

	button_background = secondary
	button_hover = secondary.lightened(0.035)
	button_pressed = secondary.lightened(0.07)

	input_background = tertiary
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
