@tool
class_name MonologueTheme extends Theme
## Modern, modular theme for Monologue with semantic color usage

# Explicit preloads to ensure dependencies are loaded in correct order
const Styles = preload("res://ui/theme_default/theme_styles.gd")
const Builder = preload("res://ui/theme_default/theme_builder.gd")

# Theme configuration
var scale: float = 1.0
var base_font_size: int = 14

# Core theme components
var palette: ThemeColorPalette
var builder: ThemeBuilder


func _init() -> void:
	# Initialize color palette
	palette = ThemeColorPalette.new()
	
	# Initialize theme builder
	builder = Builder.new(self, palette)
	
	# Generate the complete theme
	_generate_theme()


func _generate_theme() -> void:
	# Build all theme components using the modular builder
	builder.build()
