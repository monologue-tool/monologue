class_name PortraitCollectionItem extends CollectionItem


func initialize_properties() -> void:
	define_name_property("new portrait")

	define_property(Property.new("extra/protected")
		.set_type("bool")
		.hidden_in_inspector())


func get_type() -> String:
	return "portrait"


func get_preview_property_names() -> Array[String]:
	return ["name"]
