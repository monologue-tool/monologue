# Monologue Theme System

This directory contains the modular theme system for Monologue, designed to be robust, maintainable, and elegant.

## Architecture

The theme system follows a clean separation of concerns:

### 1. Theme Palettes (Settings)
Theme palettes define all colors for different theme variants:

**`theme_palette_dark.gd` - ThemePaletteDark**
- **Base Colors**: `text`, `primary`, `secondary`, `graph_bg`, `accent`, `warning`
- **Semantic Colors**: `surface`, `surface_variant`, `border`, `text_secondary`, `text_disabled`
- **Interactive States**: `hover_overlay`, `pressed_overlay`, `disabled_overlay`
- **Component Colors**: `button_background`, `button_hover`, `button_pressed`, `input_background`, `panel_background`

**`theme_palette_light.gd` - ThemePaletteLight**
- Same structure as dark theme with inverted color relationships
- Light backgrounds with dark text
- Adjusted interactive overlays for light theme

### 2. `theme_styles.gd` - ThemeStyles
Utility class for creating consistent StyleBox objects. Provides factory methods:

- `create_panel()` - Creates panel StyleBoxes
- `create_button()` - Creates button StyleBoxes
- `create_input()` - Creates input field StyleBoxes
- `create_empty()` - Creates empty/transparent StyleBoxes
- `create_separator()` - Creates separator StyleBoxLines

### 3. `theme_builder.gd` - ThemeBuilder
Static builder that generates Theme objects from theme palettes:

**Usage:**
```gdscript
var palette = ThemePaletteDark.new()
var theme = ThemeBuilder.build_theme(palette)
```

Builds all UI components:
- Buttons, checkboxes, inputs, panels, scrollbars
- Separators, sliders, tabs, trees, graphs
- Popup menus, labels, and more

### 4. `theme_manager.gd` - ThemeManager (Autoload)
Manages theme generation, application, and switching:

- Generates themes on startup using `ThemeBuilder`
- Applies themes globally to the scene tree
- Provides API for theme switching
- Handles theme saving

### 5. `theme_default.gd` - MonologueTheme
Wrapper class for compatibility with saved `.tres` resources. Uses `ThemeBuilder` internally.

## Key Improvements

### Before
- 916 lines in a single file
- Complex opacity/contrast calculations scattered throughout (`_get_primary_color(contrast + 0.05)`)
- Hard to maintain and understand color relationships
- Difficult to modify or extend

### After
- Modular architecture split across 4 files (845 lines total, better organized)
- Clear semantic color names (`palette.button_hover` instead of `_get_primary_color(contrast + 0.05)`)
- Direct color usage without messy calculations
- Easy to maintain, extend, and customize
- Better separation of concerns

## How It Works

1. **Theme Palettes** define color settings for different themes
2. **ThemeBuilder** takes a palette and returns a complete Theme object
3. **ThemeManager** generates themes on startup and applies them globally
4. **Themes can be saved** to disk for faster loading

## Customizing the Theme

### Creating Custom Theme Palettes
Create a new palette class by extending `RefCounted`:

```gdscript
class_name MyCustomPalette extends RefCounted

var text: Color = Color("...")
var primary: Color = Color("...")
# ... define all required colors

func _calculate_semantic_colors() -> void:
	# Derive semantic colors from base colors
	pass
```

### Generating Themes from Palettes
Use `ThemeBuilder` to generate themes:

```gdscript
var my_palette = MyCustomPalette.new()
var my_theme = ThemeBuilder.build_theme(my_palette)
```

### Switching Themes at Runtime
Use `ThemeManager` to switch themes:

```gdscript
# Generate and apply dark theme
ThemeManager.generate_and_apply_theme(false)

# Generate and apply light theme
ThemeManager.generate_and_apply_theme(true)

# Toggle between themes
ThemeManager.toggle_theme()

# Save current theme
ThemeManager.save_current_theme()
```

### Modifying Existing Palettes
Edit `theme_palette_dark.gd` or `theme_palette_light.gd`:

```gdscript
# Dark theme (theme_palette_dark.gd)
var text: Color = Color("e3e4eb")
var primary: Color = Color.from_hsv(0.667, 0.12, 0.14, 1.0)
var accent: Color = Color("af4548")
```

### Adding New UI Components
1. Add a static method to `theme_builder.gd`: `_build_my_component(theme, palette, styles)`
2. Call it from `build_theme()` method
3. Use `theme.set_stylebox()`, `theme.set_color()`, etc.

## Theme Generation and Application

### Automatic Theme Generation (Recommended)
Themes are automatically generated on application startup by `ThemeManager`:

1. `ThemeManager._ready()` is called when Monologue loads
2. It creates a theme palette (dark or light)
3. Calls `ThemeBuilder.build_theme(palette)` to generate the Theme object
4. Applies the theme globally to the scene tree
5. Optionally saves the theme to disk

### Manual Theme Generation (Editor Tool)
To manually regenerate and save themes:

1. Open the project in Godot Editor
2. Open `ui/theme_generator.gd` in the script editor
3. Run the script (File → Run)

This generates both themes from their palettes and saves them to:
- Dark theme: `ui/theme_default/main.tres`
- Light theme: `ui/theme_default/main_light.tres`

### Theme Application Flow

```
Startup → ThemeManager._ready()
        → Select Palette (Dark/Light)
        → ThemeBuilder.build_theme(palette)
        → Returns Theme object
        → Apply to scene tree
        → (Optional) Save to disk
```

### ThemeManager API

```gdscript
# Generate theme from palette and apply
ThemeManager.generate_and_apply_theme(true)  # Light theme
ThemeManager.generate_and_apply_theme(false) # Dark theme

# Load saved theme and apply
ThemeManager.load_and_apply_theme(true)  # Load light theme
ThemeManager.load_and_apply_theme(false) # Load dark theme

# Save current theme
ThemeManager.save_current_theme()

# Toggle between themes
ThemeManager.toggle_theme()

# Get current theme/palette
var theme = ThemeManager.get_current_theme()
var palette = ThemeManager.get_current_palette()
```
