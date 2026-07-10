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
	define_property(
		"dynamic_dropdown",
		"string",
		"dropdown",
		{
			"required": true,
			"options": ["bool", "string", "int", "float"]
		},
		"Values"
	)
	define_property(
		"dynamic", 
		"abc", 
		"dynamic",
		{
			"case_property": "dynamic_dropdown",
			"cases": {
				"bool": {"type": "bool", "default": false},
				"string": {"type": "text", "default": "", "coerce": "string"},
				"int": {"type": "int", "default": 0, "coerce": "int"},
				"float": {"type": "float", "default": 0.0, "coerce": "float"}
			}
		},
		"Values"
	)
	define_property("float", 10.0, "float", {}, "Values")
	define_property("int", 10, "int", {}, "Values")
	define_property("slider", 10.0, "slider", {}, "Values")
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
		"collection",
		{"item_type": "text"},
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
