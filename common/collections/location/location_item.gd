## A place the story happens in. Locations may nest, so a room can name the building
## it sits in.
class_name LocationCollectionItem extends CollectionItem


func initialize_properties() -> void:
	define_name_property()

	define_property(Property.new("display_name")
		.set_type("text"))

	define_property(Property.new("image")
		.set_type("file")
		.file_filters(["*.png", "*.jpg", "*.jpeg", "*.webp"])
		.tooltip("Shown when the story moves here."))

	define_property(Property.new("parent")
		.set_type("reference")
		.reference_scope("locations")
		.label_property("name")
		.tooltip("The place this one is inside of."))

	define_property(Property.new("extra/description")
		.set_type("textarea"))

	define_property(Property.new("extra/tags")
		.set_type("list")
		.item_type("text"))


func get_type() -> String:
	return "location"


func get_preview_property_names() -> Array[String]:
	return ["name", "description"]


## A place inside itself has no depth to walk, and nothing downstream would notice.
func validate_object(result: ValidationResult, _context: ValidationContext) -> void:
	if str(get_property_value("parent")) == str(get_property_value("id")):
		result.add(
			ValidationIssue.error(
				"A location cannot be inside itself.", &"self_nested_location"
			).at(self, "parent")
		)
