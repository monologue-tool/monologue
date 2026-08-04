class_name BezierCollectionItem extends CollectionItem


func initialize_properties() -> void:
	define_name_property()

	define_property(Property.new("bezier")
		.set_type("bezier"))

	define_default_property()


func get_type() -> String:
	return "bezier"


func get_preview_property_names() -> Array[String]:
	return ["name"]
