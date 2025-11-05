@tool
class_name MonologueTheme extends Theme
## Modern, modular theme for Monologue with semantic color usage

# Explicit preloads to ensure dependencies are loaded in correct order
const ColorPaletteDark = preload("res://ui/theme_default/color_palette.gd")
const ColorPaletteLight = preload("res://ui/theme_default/color_palette_light.gd")
const Styles = preload("res://ui/theme_default/theme_styles.gd")
const Builder = preload("res://ui/theme_default/theme_builder.gd")

# Theme configuration
var scale: float = 1.0
var base_font_size: int = 14
var is_light_theme: bool = true  # Toggle between light and dark theme

# Core theme components
var palette: RefCounted  # Can be either ThemeColorPalette or ThemeColorPaletteLight
var builder: ThemeBuilder


func _init(light_theme: bool = false) -> void:
	is_light_theme = light_theme
	
	# Initialize color palette based on theme type
	if is_light_theme:
		palette = ColorPaletteLight.new()
	else:
		palette = ColorPaletteDark.new()
	
	# Initialize theme builder
	builder = Builder.new(self, palette)
	
	# Generate the complete theme
	_generate_theme()


func _generate_theme() -> void:
	# Clear existing theme to ensure fresh generation
	clear()
	
	# Build all theme components using the modular builder
	builder.build()


## Regenerate the theme with a different color scheme
func regenerate(light_theme: bool = false) -> void:
	is_light_theme = light_theme
	
	# Reinitialize color palette
	if is_light_theme:
		palette = ColorPaletteLight.new()
	else:
		palette = ColorPaletteDark.new()
	
	# Reinitialize builder with new palette
	builder = Builder.new(self, palette)
	
	# Regenerate theme
	_generate_theme()
	
	# Emit change signal to notify UI
	emit_changed()
