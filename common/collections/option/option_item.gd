class_name OptionCollectionItem extends CollectionItem


static func get_option_properties() -> Array[Property]:
	return [
		Property.new("option")
			.set_type("option")
			.main_property()
			.exposed(false)
			.exported(),

		Property.new("speaker")
			.set_type("reference")
			.reference_scope("characters")
			.label_property("name")
			.hidden_in_graph(),

		Property.new("text")
			.set_type("translatable")
			.default({})
			.multiline(),

		#Property.new("correspondent")
			#.set_type("reference")
			#.reference_scope("characters")
			#.label_property("name")
			#.hidden_in_graph(),

		Property.new("advanced/enabled")
			.set_type("bool")
			.default(true)
			.hidden_in_graph(),

		Property.new("advanced/one_shot")
			.set_type("bool")
			.hidden_in_graph(),

		Property.new("advanced/enable_condition")
			.set_type("bool")
			.hidden_in_graph(),

		Property.new("advanced/condition")
			.set_type("condition")
			.default({})
			.hidden_in_graph()
	]


func initialize_properties() -> void:
	# Exported as a sub-port on the choice node that owns this option list.
	for property: Property in get_option_properties():
		define_property(property)

	define_property(Property.new("extra/description")
		.set_type("textarea")
		.hidden_in_graph())


func get_type() -> String:
	return "option"


func get_preview_property_names() -> Array[String]:
	return ["text"]
