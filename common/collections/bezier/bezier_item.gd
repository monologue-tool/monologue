class_name BezierCollectionItem extends CollectionItem


func initialize_properties() -> void:
	define_name_property("new bezier")

	define_property(Property.new("bezier")
		.set_type("bezier"))


func get_type() -> String:
	return "bezier"


func get_preview_property_names() -> Array[String]:
	return ["name"]
