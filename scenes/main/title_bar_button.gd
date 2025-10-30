## A custom button for the title bar with icon and hover effects.
##
## Provides a styled button with a texture icon and configurable hover color.
## Works in the editor (@tool) for visual feedback during design.
@tool
extends Button

## The texture/icon to display on the button.
@export var texture: Texture:
	set = _set_button_texture

## The color overlay to show when hovering over the button.
@export var hover_color: Color = Color("ffffff20")

## Reference to the internal TextureRect displaying the icon.
@onready var texture_rect: TextureRect = $MarginContainer/TextureRect


## Sets the button texture and reloads it.
##
## [param val] The new texture to use.
func _set_button_texture(val: Texture) -> void:
	texture = val
	reload_texture()


## Initializes the button with texture and hover styling.
func _ready() -> void:
	reload_texture()

	var hover_stylebox: StyleBoxFlat = StyleBoxFlat.new()
	hover_stylebox.bg_color = hover_color
	add_theme_stylebox_override("hover", hover_stylebox)

	connect("pressed", release_focus)


## Reloads and applies the texture to the TextureRect.
##
## Waits for the node to be ready if called before initialization.
func reload_texture() -> void:
	if texture is not Texture:
		return

	if not is_node_ready():
		await ready

	texture_rect.texture = texture
