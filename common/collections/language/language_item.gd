class_name LanguageCollectionItem extends CollectionItem


func initialize_properties() -> void:
	# Not define_name_property(): a language name is unique but neither required nor
	# protecting, since the user may rename or delete any language but the default.
	define_property(Property.new("name")
		.set_type("text")
		.default("New Language")
		.unique_among_siblings()
		.placeholder("English")
		.min_length(1))

	define_property(Property.new("code")
		.set_type("text")
		.default("nl")
		.unique_among_siblings()
		.placeholder("en")
		.min_length(1)
		.max_length(4))

	define_property(Property.new("extra/protected")
		.set_type("bool")
		.hidden_in_inspector())


func get_type() -> String:
	return "language"


func get_preview_property_names() -> Array[String]:
	return ["name", "code"]
