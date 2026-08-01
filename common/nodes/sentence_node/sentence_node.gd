class_name SentenceNode extends InspectableNode


func initialize_properties() -> void:
	define_property(Property.new("sentence")
		.set_type("context")
		.main_property()
		.exposed()
		.exported())

	define_property(Property.new("line")
		.set_type("translatable")
		.default({})
		.multiline())

	define_property(Property.new("speaker/speaker")
		.set_type("reference")
		.reference_scope("characters")
		.label_property("name")
		.exported())

	define_property(Property.new("speaker/display_name")
		.set_type("translatable")
		.default({})
		.hidden_in_graph())

	define_property(Property.new("speaker/voiceline")
		.set_type("file")
		.hidden_in_graph())


func get_type() -> String:
	return "sentence"
