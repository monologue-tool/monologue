# Monologue Theme System

This directory contains the modular theme system for Monologue, designed to be robust, maintainable, and elegant.

## Architecture

The theme system is split into four main components:

### 1. `color_palette.gd` - ThemeColorPalette
The semantic color palette that defines all colors used in the theme. Instead of using messy opacity and contrast calculations, colors are defined clearly and semantically:

- **Base Colors**: `background`, `text`, `primary`, `secondary`, `accent`, `warning`
- **Semantic Colors**: `surface`, `surface_variant`, `border`, `text_secondary`, `text_disabled`
- **Interactive States**: `hover_overlay`, `pressed_overlay`, `disabled_overlay`
- **Component Colors**: `button_background`, `button_hover`, `button_pressed`, `input_background`, `panel_background`

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
The main theme class that coordinates everything. Reduced from 916 lines to just 27 lines by delegating to the modular components.

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

### Changing Colors
Edit `color_palette.gd` to change the base colors. All derived colors will be automatically calculated:

```gdscript
var background: Color = Color("1a1a1f")  # Dark background
var primary: Color = Color("a9a8c0")     # Purple-gray
var accent: Color = Color("d15050")      # Red accent
```

### Adding New Components
1. Add a new method to `theme_builder.gd` (e.g., `_build_my_component()`)
2. Call it from the `build()` method
3. Use `theme.set_stylebox()`, `theme.set_color()`, etc. to configure the component

### Modifying Styles
Edit the factory methods in `theme_styles.gd` to change default spacing, radius, or other style properties.

## Generating the Theme

The theme is automatically generated when Godot loads. To manually regenerate:

1. Open the project in Godot Editor
2. Open `ui/theme_generator.gd` in the script editor
3. Run the script (File → Run)

This will save the generated theme to `ui/theme_default/main.tres`.
