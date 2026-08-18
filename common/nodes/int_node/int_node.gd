## A whole number, fed into whatever reads it.
class_name IntNode extends InspectableNode


func initialize_properties() -> void:
	define_property(Property.new("int")
		.set_type("int")
		.main_property()
		.editable()
		.exposed(false)
		.exported())


func get_type() -> String:
	return "int"
