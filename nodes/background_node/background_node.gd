class_name BackgroundNode extends MonologueGraphNode


var image := Property.new(FILE, { "filters": FilePicker.IMAGE })
var transition := Property.new(DROPDOWN, {}, "No Transition")
var duration := Property.new(SPINBOX, { "step": 0.1, "minimum": 0.0 }, 0.0)

@onready var _path_label = $VBox/HBox/PathLabel
@onready var _preview_rect = $VBox/PreviewRect


func _ready():
	node_type = "NodeBackground"
	transition.callers["set_items"] = [[
		{ "id": 0, "text": "No Transition" },
		{ "id": 1, "text": "Push Down"     },
		{ "id": 1, "text": "Push Left"     },
		{ "id": 1, "text": "Push Right"    },
		{ "id": 1, "text": "Push Up"       },
		{ "id": 1, "text": "Simple Fade"   },
	]]
	transition.connect("preview", _update)
	
	super._ready()
	image.setters["base_path"] = get_parent().file_path
	image.connect("preview", _on_path_preview)
	_update()


func _load_image():
	_path_label.text = image.value if image.value else "nothing"
	_preview_rect.hide()
	size.y = 0
	var base = image.setters.get("base_path")
	var path = Path.relative_to_absolute(image.value, base)
	
	if FileAccess.file_exists(path):
		var img = Image.load_from_file(path)
		if img:
			_preview_rect.show()
			_preview_rect.texture = ImageTexture.create_from_image(img)
			_path_label.text = image.value.get_file()
		else:
			_preview_rect.hide()


func _on_path_preview(path: Variant):
	_path_label.text = str(path).get_file()
	_load_image.call_deferred()


func _update(_value: Variant = null):
	_path_label.text = image.value
	_load_image()
	super._update()


func _get_field_groups() -> Array:
	return ["image", {"Transition": ["transition", "duration"]}]
