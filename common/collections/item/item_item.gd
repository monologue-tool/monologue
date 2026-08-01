class_name ItemCollectionItem extends CollectionItem


func initialize_properties() -> void:
	define_name_property()

	define_property(Property.new("display_name")
		.set_type("text"))

	define_property(Property.new("extra/description")
		.set_type("textarea"))


func get_type() -> String:
	return "item"


func get_preview_property_names() -> Array[String]:
	return ["name", "description"]
