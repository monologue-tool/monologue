## One state a place can be seen in. A location is a single place all the way through the
## story, but not the same picture: morning, ruined, on fire.
class_name VariationCollectionItem extends CollectionItem


func initialize_properties() -> void:
	define_name_property()

	define_property(Property.new("image")
		.set_type("file")
		.file_filters(["*.png", "*.jpg", "*.jpeg", "*.webp"])
		.required()
		.tooltip("Shown when the story is here and this variation is the one asked for."))

	define_property(Property.new("extra/protected")
		.set_type("bool")
		.hidden_in_inspector())

	define_default_property()


func get_type() -> String:
	return "variation"


func get_preview_property_names() -> Array[String]:
	return ["name"]
