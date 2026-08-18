class_name EaseCollectionItem extends CollectionItem


func initialize_properties() -> void:
	define_name_property()

	define_property(Property.new("ease")
		.set_type("ease"))

	define_default_property()


func get_type() -> String:
	return "ease"


func get_preview_property_names() -> Array[String]:
	return ["name"]
