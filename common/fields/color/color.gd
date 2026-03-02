extends Field

# Sweetie 16 Palette by GrafxKid
const COLORS = [
	"#000000",
	"#b13e53",
	"#ef7d57",
	"#ffcd75",
	"#a7f070",
	"#38b764",
	"#257179",
	"#3b5dc9",
	"#41a6f6",
	"#73eff7",
	"#94b0c2",
	"#566c86"
]

@onready var color_preview: ColorRect = %ColorPreview
@onready var color_popup: PopupPanel = %ColorPopup
@onready var color_selector: GridContainer = %ColorSelector

@onready var Swatch: PackedScene = preload("uid://psbrljdmbtg6")

var color: Color = Color(COLORS[0])


func _ready() -> void:
	for color_string in COLORS:
		var swatch: ColorSwatch = Swatch.instantiate()
		swatch.color = color_string
		color_selector.add_child(swatch)
		swatch.pressed.connect(_on_color_swatch_pressed.bind(color_string))
	_update_preview()


func set_value(value: Variant) -> void:
	color = Color(value)
	_update_preview()


func get_value() -> Variant:
	return color.to_html()


func _on_color_picker_button_pressed() -> void:
	color_popup.position = global_position + Vector2(0, size.y)
	color_popup.popup()


func _on_color_swatch_pressed(color_string: String) -> void:
	color = Color(color_string)
	color_popup.hide()
	_update_preview()

	emit_value_changed(color_string)
	emit_value_committed(color_string)
	emit_preview_changed()


func _update_preview() -> void:
	color_preview.color = color

	custom_minimum_size.x = size.y


func _on_resized() -> void:
	if not is_node_ready():
		return

	_update_preview()
