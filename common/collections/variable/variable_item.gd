class_name VariableCollectionItem extends CollectionItem

const VALUE_TYPES: Array[String] = ["bool", "string", "int", "float"]


func initialize_properties() -> void:
	define_name_property("new variable")

	define_property(Property.new("type")
		.set_type("dropdown")
		.default("string")
		.required()
		.options(VALUE_TYPES))

	# The widget used for "value" follows whatever "type" is set to.
	define_property(Property.new("value")
		.set_type("dynamic")
		.default("")
		.cases("type", _value_cases()))

	define_property(Property.new("extra/description")
		.set_type("textarea"))


func get_type() -> String:
	return "variable"


func get_preview_property_names() -> Array[String]:
	return ["name", "type", "value"]


func _value_cases() -> Dictionary:
	return {
		"bool": {"type": "bool", "default": false},
		"string": {"type": "text", "default": "", "coerce": "string"},
		"int": {"type": "int", "default": 0, "coerce": "int"},
		"float": {"type": "float", "default": 0.0, "coerce": "float"},
	}
