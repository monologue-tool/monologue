## Moves the story to a place.
class_name LocationNode extends InspectableNode


func initialize_properties() -> void:
	define_property(Property.new("location")
		.set_type("context")
		.main_property()
		.exposed()
		.exported())

	define_property(Property.new("target")
		.set_type("reference")
		.reference_scope("locations")
		.label_property("name")
		.required()
		.tooltip("Where the story moves to."))

	define_property(Property.new("variation")
		.set_type("reference")
		.reference_scope("ref:target:variations")
		.label_property("name")
		.shown_by("show_image")
		.hidden_in_graph()
		.tooltip("Which state to show the place in. Falls back to its default variation."))


func get_type() -> String:
	return "location"


## A variation belongs to one place, so naming another one leaves the node pointing at a
## picture its place does not have.
func validate_object(result: ValidationResult, context: ValidationContext) -> void:
	var variation_id: String = str(get_property_value("variation"))
	if variation_id.is_empty() or get_property_value("show_image") != true:
		return

	if not ReferenceResolver.exists(context.project, "ref:target:variations", variation_id, self):
		result.add(
			ValidationIssue.error(
				"This variation does not belong to the place named here.", &"foreign_variation"
			).at(self, "variation")
		)
