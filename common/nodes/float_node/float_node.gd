## A number with decimals, fed into whatever reads it.
class_name FloatNode extends InspectableNode


func initialize_properties() -> void:
	define_property(Property.new("float")
		.set_type("float")
		.main_property()
		.editable()
		.exposed(false)
		.exported())


func get_type() -> String:
	return "float"
