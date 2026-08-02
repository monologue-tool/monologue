extends FieldIndexer


func _init() -> void:
	name = "reference"
	display_name = "Reference"
	description = "Points at another object by its id, whatever that object is called."
	color = MonologuePalette.REFERENCE
	scene_uid = "uid://bqr7n2v5xk8dm"
	default_value = ""
	default_settings = {
		PropertySettings.KEY_LABEL_PROPERTY: ReferenceResolver.DEFAULT_LABEL_PROPERTY,
		PropertySettings.KEY_ALLOW_EMPTY: true,
	}


## The value is the target id itself, so there is exactly one reference to report.
func extract_references(value: Variant) -> PackedStringArray:
	if value is String and not (value as String).is_empty():
		return PackedStringArray([value])
	return PackedStringArray()
