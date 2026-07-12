class_name LocationCollectionItem extends CollectionItem


func initialize_properties() -> void:
	define_property(
		"name",
		"new location",
		"text",
		{
			"required": true,
			"unique": true,
			"protect": true,
			"validation": {"min_length": 1},
		},
	)
	define_property("display_name", "", "text")
	define_property("description", "", "textarea", {}, "Extra")


func get_type() -> String:
	return "location"


func _on_property_changed(_pname: String) -> void:
	pass


func get_preview_property_names() -> Array[String]:
	return ["name", "description"]
