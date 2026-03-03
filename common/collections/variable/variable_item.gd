class_name VariableCollectionItem extends ListItem


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
		{
			"required": true,
			"options": ["bool", "string", "int", "float"]
		}
	)
	define_property(
		"value",
		"",
		"dynamic",
		{
			"case_property": "type",
			"cases": {
				"bool": {"type": "bool", "default": false},
				"string": {"type": "text", "default": "", "coerce": "string"},
				"int": {"type": "number", "default": 0, "coerce": "int"},
				"float": {"type": "number", "default": 0.0, "coerce": "float"}
			}
		}
	)
	define_property("description", "", "textarea", {}, "Extra")


func get_type() -> String:
	return "variable"

func _on_property_changed(_pname: String, _old_value: Variant, _new_value: Variant) -> void:
	pass
