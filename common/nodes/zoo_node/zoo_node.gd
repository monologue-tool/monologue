class_name ZooNode extends InspectableNode


func initialize_properties() -> void:
	define_main_property("zoo", "context", false, null, {"exposed": false, "export": true})

	# Text
	define_property("text", "", "text", {}, "Text")
	define_property("textarea", "", "textarea", {}, "Text")
	define_property(
		"translatable",
		{"en": ""},
		"translatable",
		{},
		"Text"
	)
	define_property(
		"translatable_multiline",
		{"en": ""},
		"translatable",
		{PropertySettings.KEY_MULTILINE: true},
		"Text"
	)

	# Values
	define_property("bool", false, "bool", {}, "Values")
	define_property("color2", "#3b5dc9", "color", {}, "Values")
	define_property("vector2", [0.0, 0.0], "vector2", {}, "Values")
	define_property("bezier", [0.25, 0.10, 0.25, 1.0], "bezier", {}, "Values")

	# References
	define_property("file", "", "file", {}, "References")
	define_property(
		"dropdown",
		"",
		"dropdown",
		{"source": "characters"},
		"References"
	)

	# List
	define_property(
		"list",
		[],
		"list",
		{"collection": "characters"},
		"List"
	)
	define_property(
		"list_dropdown",
		"",
		"dropdown",
		{"source": "self:list"},
		"List"
	)


func get_type() -> String:
	return "zoo"


func get_settings() -> Dictionary:
	return {}


func get_icon() -> Texture2D:
	return Texture2D.new()


func get_color() -> Color:
	return Color.WHITE


func _on_property_changed(_pname: String, _old_value: Variant, _new_value: Variant) -> void:
	pass
