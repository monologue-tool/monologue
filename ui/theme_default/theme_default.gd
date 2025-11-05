@tool
class_name MonologueTheme extends Theme
## Wrapper class for Monologue themes - uses ThemeBuilder to generate from palettes
## This class exists for compatibility with saved .tres resources

const PaletteDark = preload("res://ui/theme_default/theme_palette_dark.gd")
const PaletteLight = preload("res://ui/theme_default/theme_palette_light.gd")
const Builder = preload("res://ui/theme_default/theme_builder.gd")


func _init(light_theme: bool = false) -> void:
	# Select the appropriate palette
	var palette: RefCounted
	if light_theme:
		palette = PaletteLight.new()
	else:
		palette = PaletteDark.new()
	
	# Build theme using ThemeBuilder
	var generated_theme = Builder.build_theme(palette)
	
	# Merge the generated theme into this instance
	if generated_theme:
		merge_with(generated_theme)
