## Gives a character an item, takes one away, or sets how many they hold.
class_name InventoryNode extends InspectableNode

const OPERATIONS: Array = ["Give", "Take", "Set"]


func initialize_properties() -> void:
	define_property(Property.new("inventory")
		.set_type("context")
		.main_property()
		.exposed()
		.exported())

	define_property(Property.new("who")
		.set_type("reference")
		.reference_scope("characters")
		.label_property("name")
		.required()
		.tooltip("Whose pockets this is about. Everyone carries their own."))

	define_property(Property.new("item")
		.set_type("reference")
		.reference_scope("items")
		.label_property("name")
		.required()
		.tooltip("Which item this is about."))

	define_property(Property.new("operation")
		.set_type("dropdown")
		.options(OPERATIONS)
		.default("Give")
		.required()
		.hidden_in_graph())

	define_property(Property.new("quantity")
		.set_type("int")
		.default(1)
		.bounds(0, 9999)
		.hidden_in_graph()
		.tooltip("How many. Setting zero is how an item is taken away entirely."))


func get_type() -> String:
	return "inventory"


## Giving or taking nothing is a node that runs and changes nothing, which reads as if
## it worked.
func validate_object(result: ValidationResult, _context: ValidationContext) -> void:
	if str(get_property_value("operation")) == "Set":
		return

	if int(get_property_value("quantity")) == 0:
		result.add(
			ValidationIssue.warning(
				"This moves none of the item, so nothing changes.", &"empty_transfer"
			).at(self, "quantity")
		)
