class_name FilePicker extends MonologueField

const AUDIO = ["*.mp3,*.ogg,*.wav;Sound Files"]
const IMAGE = ["*.bmp,*.jpg,*.jpeg,*.png,*.svg,*.webp;Image Files"]

@export var base_path: String
@export var filters: PackedStringArray

@onready var line_edit: LineEdit = $HBox/LineEdit
@onready var picker_button: Button = $HBox/FilePickerButton
@onready var warn_label: Label = $WarnLabel


func propagate(value: Variant) -> void:
	super.propagate(value)
	line_edit.text = value
	validate(value)


func validate(path: String) -> bool:
	warn_label.hide()
	var is_valid = true
	path = path.lstrip(" ")
	path = path.rstrip(" ")
	if path and filters:
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
	return is_valid


func _on_file_selected(path: String):
	line_edit.text = Path.absolute_to_relative(path, base_path)
	_on_focus_exited()


func _on_focus_exited() -> void:
	_on_text_submitted(line_edit.text)


func _on_picker_button_pressed():
	GlobalSignal.emit("open_file_request", [_on_file_selected, filters, base_path.get_base_dir()])


func _on_text_changed(new_text: String) -> void:
	validate(new_text)
	field_changed.emit(new_text)


func _on_text_submitted(file_path: String) -> void:
	validate(file_path)
	field_updated.emit(file_path)


func _split_match(filter: String) -> Array:
	return filter.split(";")[0].split(",")
