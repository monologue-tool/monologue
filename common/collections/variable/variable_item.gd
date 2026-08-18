class_name VariableCollectionItem extends CollectionItem

const VALUE_TYPES: Array[String] = ["bool", "string", "int", "float"]


func initialize_properties() -> void:
	define_name_property().validate(_must_be_an_identifier, &"variable_name")

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

	define_property(Property.new("persistent")
		.set_type("bool")
		.tooltip("Kept between runs rather than reset when the story restarts."))

	define_property(Property.new("extra/description")
		.set_type("textarea"))


func get_type() -> String:
	return "variable"


func get_preview_property_names() -> Array[String]:
	return ["name", "type", "value"]


## Variable names are written verbatim into conditions and setters, so a name with a
## space or a leading digit would produce something unparseable downstream.
func _must_be_an_identifier(context: ValidationContext) -> Variant:
	if str(context.value).is_valid_identifier():
		return null
	return "Use letters, digits and underscores only, and don't start with a digit."


func _value_cases() -> Dictionary:
	return {
		"bool": {"type": "bool", "default": false},
		"string": {"type": "text", "default": "", "coerce": "string"},
		"int": {"type": "int", "default": 0, "coerce": "int"},
		"float": {"type": "float", "default": 0.0, "coerce": "float"},
	}
