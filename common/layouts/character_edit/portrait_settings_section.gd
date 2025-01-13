class_name PortraitSettingsSection extends PortraitEditSection


signal changed

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
	image_path.setters["base_path"] = val


func _from_dict(dict: Dictionary = {}) -> void:
	super._from_dict(dict)
	timeline_section._from_dict(dict.get("Animation", {}))


func _to_dict() -> Dictionary:
	#var portrait_type_string: String = portrait_type_field.value
	#var dict: Dictionary = {
		#"PortraitType": portrait_type_string,
		#"Offset": offset_vector_field.value,
		#"Mirror": mirror_cb.button_pressed
	#}
	#
	#match portrait_type_string:
		#"Image":
			#dict["ImagePath"] = image_path_fp.value
		#"Animation":
			#dict["Animation"] = timeline_section._to_dict()
	#
	return super._to_dict()


func _on_check_button_toggled(toggled_on: bool) -> void:
	preview_section.update_mirror(toggled_on)
