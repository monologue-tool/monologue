## Stops the story here.
class_name EndNode extends InspectableNode


func initialize_properties() -> void:
	define_property(Property.new("end")
		.set_type("context")
		.main_property()
		.exposed()
		.exported(false))

	define_property(Property.new("can_retrieve")
		.set_type("bool")
		.default(true)
		.exported(false)
		.hidden_in_graph())

	define_property(Property.new("extra/tags")
		.set_type("list")
		.item_type("text")
		.exported(false)
		.hidden_in_graph())


func get_type() -> String:
	return "end"
