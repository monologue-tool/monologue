class_name LocationCollectionItem extends CollectionItem


func initialize_properties() -> void:
	define_name_property("new location")

	define_property(Property.new("display_name")
		.set_type("text"))

	define_property(Property.new("extra/description")
		.set_type("textarea"))


func get_type() -> String:
	return "location"


func get_preview_property_names() -> Array[String]:
	return ["name", "description"]
