## Passes the story straight through. Carries nothing of its own; it exists so a long
## wire can be bent around the rest of the graph instead of crossing it.
class_name RerouteNode extends InspectableNode


func initialize_properties() -> void:
	define_property(Property.new("reroute")
		.set_type("any")
		.main_property()
		.exposed()
		.exported())


func get_type() -> String:
	return "reroute"
