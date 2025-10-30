@tool
extends Button

@export var texture: Texture:
	set = _set_button_texture
@export var hover_color: Color = Color("ffffff20")

@onready var texture_rect: TextureRect = $MarginContainer/TextureRect


func _set_button_texture(val: Texture) -> void:
	texture = val
	reload_texture()


func _ready() -> void:
	reload_texture()

	var hover_stylebox: StyleBoxFlat = StyleBoxFlat.new()
	hover_stylebox.bg_color = hover_color
	add_theme_stylebox_override("hover", hover_stylebox)

	connect("pressed", release_focus)


func reload_texture() -> void:
	if texture is not Texture:
		return

	if not is_node_ready():
		await ready

	texture_rect.texture = texture
