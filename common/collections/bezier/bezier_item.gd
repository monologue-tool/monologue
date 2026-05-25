class_name BezierCollectionItem extends ListItem


func initialize_properties() -> void:
	define_property(
		"name",
		"new bezier",
		"text",
		{
			"required": true,
			"unique": true,
			"protect": true,
			"validation": {"min_length": 1},
		},
	)
	define_property("bezier", [0.25, 0.10, 0.25, 1.0], "bezier")


func get_type() -> String:
	return "bezier"


func _on_property_changed(_pname: String) -> void:
	pass


func get_preview_property_names() -> Array[String]:
	return ["name"]
