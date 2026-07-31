class_name VariableCollectionItem extends CollectionItem


func initialize_properties() -> void:
	define_property(
		"name",
		"new variable",
		"text",
		{
			"required": true,
			"unique": true,
			"protect": true,
			"validation": {"min_length": 1},
		},
	)
	define_property(
		"type",
		"string",
		"dropdown",
		{"required": true, "options": ["bool", "string", "int", "float"]}
	)
	define_property(
		"value",
		"",
		"dynamic",
		{
			PropertySettings.KEY_CASE_PROPERTY: "type",
			PropertySettings.KEY_CASES:
			{
				"bool": {"type": "bool", "default": false},
				"string": {"type": "text", "default": "", "coerce": "string"},
				"int": {"type": "int", "default": 0, "coerce": "int"},
				"float": {"type": "float", "default": 0.0, "coerce": "float"}
			}
		}
	)
	define_property("description", "", "textarea", {}, "Extra")


func get_type() -> String:
	return "variable"


func _on_property_changed(_pname: String) -> void:
	pass


func get_preview_property_names() -> Array[String]:
	return ["name", "type", "value"]
