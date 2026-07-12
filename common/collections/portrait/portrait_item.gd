class_name PortraitCollectionItem extends CollectionItem


func initialize_properties() -> void:
	define_property(
		"name",
		"new portrait",
		"text",
		{
			"required": true,
			"unique": true,
			"protect": true,
			"validation": {"min_length": 1},
		},
	)
	define_property("protected", false, "bool", { "visible_in_inspector": false }, "Extra")


func get_type() -> String:
	return "portrait"


func _on_property_changed(_pname: String) -> void:
	pass


func get_preview_property_names() -> Array[String]:
	return ["name"]
