class_name TimelineSection extends PortraitEditSection

@warning_ignore("unused_signal")
signal changed

#var animation := OldProperty.new(Field.TIMELINE, {}, {})

var id: String
var base_path: String:
	set = _set_base_path


func _ready() -> void:
	super._ready()
	#animation.setters["preview_section"] = %PreviewSection


func _set_base_path(val: String) -> void:
	base_path = val
	#animation.setters["base_path"] = val


func _from_dict(dict: Dictionary = {}) -> void:
	super._from_dict(dict)


func _to_dict() -> Dictionary:
	return super._to_dict()
