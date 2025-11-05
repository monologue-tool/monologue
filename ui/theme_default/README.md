# Monologue Theme System

This directory contains the modular theme system for Monologue, designed to be robust, maintainable, and elegant.

## Architecture

The theme system is split into multiple components:

### 1. Color Palettes
Two semantic color palettes define all colors used in the themes:

**`color_palette.gd` - ThemeColorPalette (Dark Theme)**
- **Base Colors**: `text`, `primary`, `secondary`, `graph_bg`, `accent`, `warning`
- **Semantic Colors**: `surface`, `surface_variant`, `border`, `text_secondary`, `text_disabled`
- **Interactive States**: `hover_overlay`, `pressed_overlay`, `disabled_overlay`
- **Component Colors**: `button_background`, `button_hover`, `button_pressed`, `input_background`, `panel_background`

**`color_palette_light.gd` - ThemeColorPaletteLight (Light Theme)**
- Same structure as dark theme but with inverted color relationships
- Light backgrounds with dark text
- Adjusted interactive overlays for light theme

### 2. `theme_styles.gd` - ThemeStyles
Utility class for creating consistent StyleBox objects. Provides factory methods for common UI patterns:

- `create_panel()` - Creates panel StyleBoxes
- `create_button()` - Creates button StyleBoxes
- `create_input()` - Creates input field StyleBoxes
- `create_empty()` - Creates empty/transparent StyleBoxes
- `create_separator()` - Creates separator StyleBoxLines

### 3. `theme_builder.gd` - ThemeBuilder
Modular theme builder that constructs all theme components. Each UI category has its own method:

- `_build_buttons()` - All button variants (regular, accent, warning, flat)
- `_build_checkboxes()` - Checkboxes and toggle buttons
- `_build_inputs()` - Text inputs, spinboxes, text editors
- `_build_panels()` - Panels, containers, backgrounds
- `_build_scrollbars()` - Scrollbar styles
- `_build_separators()` - Separators and dividers
- `_build_sliders()` - Slider controls
- `_build_tabs()` - Tab bars and containers
- `_build_tree()` - Tree view styles
- `_build_graph_elements()` - Graph editor and nodes
- `_build_popup_menu()` - Popup menus and option buttons
- `_build_labels()` - Label variants

### 4. `theme_default.gd` - MonologueTheme
The main theme class that coordinates everything. Reduced from 916 lines to ~60 lines by delegating to the modular components. Supports both light and dark themes.

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

## Customizing the Theme

### Switching Between Light and Dark Themes
The theme system now supports both light and dark themes:

```gdscript
# Create dark theme (default)
var dark_theme = MonologueTheme.new(false)

# Create light theme
var light_theme = MonologueTheme.new(true)

# Regenerate existing theme with different mode
theme.regenerate(true)  # Switch to light theme
```

### Changing Colors
Edit `color_palette.gd` (dark) or `color_palette_light.gd` (light) to change the base colors:

```gdscript
# Dark theme (color_palette.gd)
var text: Color = Color("e3e4eb")
var primary: Color = Color.from_hsv(0.667, 0.12, 0.14, 1.0)
var accent: Color = Color("af4548")

# Light theme (color_palette_light.gd)
var text: Color = Color("1a1a1f")  # Dark text for light background
var primary: Color = Color.from_hsv(0.667, 0.08, 0.92, 1.0)
var accent: Color = Color("d86568")  # Lighter accent
```

### Adding New Components
1. Add a new method to `theme_builder.gd` (e.g., `_build_my_component()`)
2. Call it from the `build()` method
3. Use `theme.set_stylebox()`, `theme.set_color()`, etc. to configure the component

### Modifying Styles
Edit the factory methods in `theme_styles.gd` to change default spacing, radius, or other style properties.

## Generating the Theme

The theme is automatically generated when Godot loads. To manually regenerate both themes:

1. Open the project in Godot Editor
2. Open `ui/theme_generator.gd` in the script editor
3. Run the script (File → Run)

This will:
- Generate and save the dark theme to `ui/theme_default/main.tres`
- Generate and save the light theme to `ui/theme_default/main_light.tres`
- Refresh the theme cache to ensure UI updates immediately

### Theme Cache Refresh

The generator now automatically refreshes the theme cache when regenerating themes. This ensures that:
1. The existing theme instance in memory is updated
2. Resource cache is cleared and refreshed
3. UI updates reflect the new theme immediately without requiring editor restart
