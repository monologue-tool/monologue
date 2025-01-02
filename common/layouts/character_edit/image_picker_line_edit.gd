extends HBoxContainer


const IMAGE = ["*.bmp,*.jpg,*.jpeg,*.png,*.svg,*.webp;Image Files"]

var filters: Array = ["*.bmp", "*.jpg", "*.jpeg", "*.png", "*.svg", "*.webp"]

@onready var line_edit := $VBox/LineEdit
@onready var warn_label := $VBox/WarnLabel
@onready var preview_section := %PreviewSection

var value: String : set = _set_value, get = _get_value
var base_path: String


func _set_value(val: String) -> void:
	value = val
	line_edit.text = val
	_update()

func _get_value() -> String:
	return line_edit.text


func _ready() -> void:
	_update()


func _update() -> void:
	var path: String = line_edit.text
	var texture: Texture2D = PlaceholderTexture2D.new()
	if validate(path):
		var img := Image.load_from_file(path)
		if img != null:
			texture = ImageTexture.create_from_image(img)
	preview_section.update_preview(texture)


func validate(path: String) -> bool:
	warn_label.hide()
	var is_valid = true
	path = path.lstrip(" ")
	path = path.rstrip(" ")
	
	if path:
		var absolute_path = Path.relative_to_absolute(path, base_path)
		if not FileAccess.file_exists(absolute_path):
			warn_label.show()
			warn_label.text = "File path not found!"
			is_valid = false
		else:
			var correct_suffix: bool = false
			var file_name: String = absolute_path.get_file()
			for filter in filters:
				var targets = _split_match(filter)
				for target in targets:
					if file_name.match(target):
						correct_suffix = true
						break
			
			if not correct_suffix:
				warn_label.show()
				var formats = Array(filters).map(_split_match)
				var text = ", ".join(formats.map(func(f): return ", ".join(f)))
				warn_label.text = "File must match: %s" % text
				is_valid = false
	else:
		is_valid = false
	return is_valid


func _on_line_edit_text_submitted(path: String) -> void:
	value = path
	line_edit.text = path
	_update()


func _on_line_edit_focus_exited() -> void:
	_on_line_edit_text_submitted(line_edit.text)


func _on_file_picker_button_pressed() -> void:
	GlobalSignal.emit("open_file_request",
			[_on_file_selected, IMAGE, base_path.get_base_dir()])

func _on_file_selected(path: String):
	line_edit.text = Path.absolute_to_relative(path, base_path)
	_on_line_edit_focus_exited()

func _split_match(filter: String) -> Array:
	return filter.split(";")[0].split(",")


func _on_line_edit_text_changed(new_text: String) -> void:
	_update()
