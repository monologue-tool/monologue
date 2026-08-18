## Something the story can give, take or check for.
class_name ItemCollectionItem extends CollectionItem


func initialize_properties() -> void:
	define_name_property()

	define_property(Property.new("display_name")
		.set_type("text"))

	define_property(Property.new("icon")
		.set_type("file")
		.file_filters(["*.png", "*.svg", "*.jpg", "*.webp"]))

	define_property(Property.new("inventory/stackable")
		.set_type("bool")
		.default(true)
		.tooltip("Whether several of these occupy one slot."))

	define_property(Property.new("inventory/max_stack")
		.set_type("int")
		.default(99)
		.bounds(1, 9999)
		.tooltip("Ignored when the item does not stack."))

	define_property(Property.new("inventory/value")
		.set_type("int")
		.tooltip("What the item is worth, in whatever the game counts in."))

	define_property(Property.new("extra/description")
		.set_type("textarea"))

	define_property(Property.new("extra/tags")
		.set_type("list")
		.item_type("text")
		.tooltip("Free labels the game can filter on. Monologue never reads them."))


func get_type() -> String:
	return "item"


func get_preview_property_names() -> Array[String]:
	return ["name", "description"]


## A stack size on an item that does not stack is a setting nobody will honour.
func validate_object(result: ValidationResult, _context: ValidationContext) -> void:
	if get_property_value("stackable") == true:
		return
	if int(get_property_value("max_stack")) > 1:
		result.add(
			ValidationIssue.warning(
				"This item does not stack, so its stack size is never used.",
				&"unused_max_stack"
			).at(self, "max_stack")
		)
