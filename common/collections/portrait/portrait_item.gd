## One face a character can wear. The runtime reads several frames as an animation, so
## a portrait is a set of images rather than a single one.
class_name PortraitCollectionItem extends CollectionItem


func initialize_properties() -> void:
	define_name_property()

	define_property(Property.new("image")
		.set_type("file")
		.file_filters(["*.png", "*.jpg", "*.jpeg", "*.webp"])
		.required()
		.tooltip("Shown when this portrait is on screen."))

	define_property(Property.new("animation/frames")
		.set_type("list")
		.item_type("file")
		.hidden_in_inspector()
		.tooltip("Extra images, played in order. Leave empty for a still portrait."))

	define_property(Property.new("animation/fps")
		.set_type("int")
		.default(12)
		.bounds(1, 60)
		.suffix("fps")
		.tooltip("Only used when there is more than one frame."))

	define_property(Property.new("display/mirrored")
		.set_type("bool")
		.tooltip("Flips the image, for a character facing the other way."))

	define_property(Property.new("display/offset")
		.set_type("vector2")
		.tooltip("Nudges the image from where it would otherwise sit."))

	define_property(Property.new("extra/protected")
		.set_type("bool")
		.hidden_in_inspector())


func get_type() -> String:
	return "portrait"


func get_preview_property_names() -> Array[String]:
	return ["name"]
