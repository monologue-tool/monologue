class_name PortraitSettingsSection extends CharacterEditSection


signal changed

@onready var portrait_type_field := $MarginContainer/FieldVBox/PortraitTypeField
@onready var image_path_fp := $MarginContainer/FieldVBox/ImagePickerLineEdit
@onready var offset_vector_field := $MarginContainer/FieldVBox/OffsetVectorField
@onready var mirror_cb := $MarginContainer/FieldVBox/MonologueCheckButton/CheckButton

var portrait_type := Property.new(MonologueGraphNode.DROPDOWN, {}, "Image")
var image_path := Property.new(MonologueGraphNode.FILE, {})
var offset := Property.new(MonologueGraphNode.VECTOR, {}, [0, 0])
var mirror := Property.new(MonologueGraphNode.TOGGLE, {}, false)

@onready var field_vbox := $MarginContainer/FieldVBox
@onready var preview_section := %PreviewSection
@onready var timeline_section := %TimelineSection

var id: String
var base_path: String : set = _set_base_path


func _ready() -> void:
	portrait_type.callers["set_items"] = [[
		{ "id": 0, "text": "Image"     },
		{ "id": 1, "text": "Animation" },
	]]



func _set_base_path(val: String) -> void:
	base_path = val
	image_path_fp.base_path = val


func _from_dict(dict: Dictionary = {}) -> void:
	var portrait_type: String = dict.get("PortraitType", "Image")
	portrait_type_field.value = portrait_type
	offset_vector_field.value = dict.get("Offset", [0, 0])
	mirror_cb.button_pressed = dict.get("Mirror", false)

	if portrait_type == "Image":
		image_path_fp.value = dict.get("ImagePath", "")
	timeline_section._from_dict(dict.get("Animation", {}))


func _to_dict() -> Dictionary:
	var portrait_type: String = portrait_type_field.value
	var dict: Dictionary = {
		"PortraitType": portrait_type,
		"Offset": offset_vector_field.value,
		"Mirror": mirror_cb.button_pressed
	}
	
	match portrait_type:
		"Image":
			dict["ImagePath"] = image_path_fp.value
		"Animation":
			dict["Animation"] = timeline_section._to_dict()
	
	return dict


func _on_check_button_toggled(toggled_on: bool) -> void:
	preview_section.update_mirror(toggled_on)
