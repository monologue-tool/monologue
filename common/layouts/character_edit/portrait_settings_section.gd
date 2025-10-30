## Settings section for configuring portrait display options.
##
## Extends PortraitEditSection to provide configuration options for portrait rendering.
class_name PortraitSettingsSection extends PortraitEditSection

@warning_ignore("unused_signal")
signal changed

var portrait_type := OldProperty.new(Field.DROPDOWN, {}, "Image", "PortraitType")
var image_path := OldProperty.new(Field.FILE, {"filters": FilePicker.IMAGE}, "", "ImagePath")
var offset := OldProperty.new(Field.VECTOR, {}, [0, 0], "Offset")
var mirror := OldProperty.new(Field.TOGGLE, {}, false, "Mirror")
var one_shot := OldProperty.new(Field.TOGGLE, {}, false, "OneShot")

@onready var preview_section := %PreviewSection
@onready var timeline_section: TimelineSection = %TimelineSection

var id: String
var base_path: String:
	set = _set_base_path

var _control_groups = {
	"Image": [portrait_type, image_path, offset, mirror],
	"Animation": [portrait_type, offset, mirror, one_shot],
}


func _ready() -> void:
	portrait_type.callers["set_items"] = [
		[
			{"id": 0, "text": "Image"},
			{"id": 1, "text": "Animation"},
		]
	]
	portrait_type.change.connect(_on_portrait_type_change)
	portrait_type.connect("preview", _show_group)
	image_path.change.connect(_on_image_path_change)
	offset.change.connect(_on_offset_change)
	mirror.change.connect(_on_mirror_change)
	super._ready()


func _set_base_path(val: String) -> void:
	base_path = val
	if not image_path.field:
		image_path.setters["base_path"] = val
	else:
		image_path.field.base_path = val


func _from_dict(dict: Dictionary = {}) -> void:
	var portrait_list: Array = dict.get("Portraits", [])
	if (
		portrait_index >= 0
		and portrait_index < portrait_list.size()
		and portrait_index == %PortraitListSection.selected
	):
		var portrait_dict: Dictionary = portrait_list[portrait_index]["Portrait"]
		super._from_dict(portrait_dict)
		timeline_section._from_dict.bind(portrait_dict).call_deferred()
		timeline_section.portrait_index = portrait_index
		timeline_section.character_index = character_index
		timeline_section.base_path = base_path
	_on_portrait_type_change.call_deferred()


func _to_dict() -> Dictionary:
	return super._to_dict()


func _on_check_button_toggled(toggled_on: bool) -> void:
	preview_section.update_mirror(toggled_on)


func _on_portrait_type_change(_old_value: Variant = null, _new_value: Variant = null) -> void:
	var _process_type_change = func():
		if visible:
			timeline_section.visible = portrait_type.value == "Animation"
		if portrait_type.value == "Animation":
			preview_section.update_animation([])
		else:
			_on_image_path_change(null, image_path.value)
		_show_group()

	_process_type_change.call_deferred()


func _on_image_path_change(_old_value: Variant = null, new_value: Variant = null) -> void:
	if not new_value or not image_path.field:
		return

	var is_valid: bool = image_path.field.validate(image_path.value)
	if is_valid:
		var abs_image_path: String = Path.relative_to_absolute(new_value, base_path)
		var texture: ImageTexture = ImageLoader.load_image(abs_image_path)
		preview_section.update_preview(texture)
		return
	preview_section.update_preview(ImageTexture.new())


func _on_offset_change(_old_value: Variant = null, new_value: Variant = null) -> void:
	preview_section.update_offset(new_value)


func _on_mirror_change(_old_value: Variant = null, new_value: Variant = null) -> void:
	preview_section.update_mirror(new_value)


func _show_group(prt_type: Variant = portrait_type.value) -> void:
	var group = _control_groups.get(prt_type)
	for key in _control_groups.keys():
		for property: Property in _control_groups.get(key):
			property.set_visible(group.has(property))


func _on_delete_button_pressed() -> void:
	%PortraitListSection.references[portrait_index].custom_delete_button.pressed.emit()
