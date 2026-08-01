class_name OptionCollectionItem extends CollectionItem


func initialize_properties() -> void:
	# Exported as a sub-port on the choice node that owns this option list.
	define_property(Property.new("option")
		.set_type("option")
		.main_property())

	define_property(Property.new("text")
		.set_type("translatable")
		.default({})
		.multiline())

	define_property(Property.new("correspondent")
		.set_type("reference")
		.reference_scope("characters")
		.label_property("name"))

	define_property(Property.new("advanced/enabled")
		.set_type("bool")
		.default(true))

	define_property(Property.new("advanced/one_shot")
		.set_type("bool"))

	define_property(Property.new("advanced/enable_condition")
		.set_type("bool"))

	define_property(Property.new("advanced/condition")
		.set_type("condition")
		.default({}))

	define_property(Property.new("extra/description")
		.set_type("textarea"))


func get_type() -> String:
	return "option"


func get_preview_property_names() -> Array[String]:
	return ["text"]
