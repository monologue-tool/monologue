class_name ManifestDocument extends InspectableDocument


func initialize_properties() -> void:
	var editor_version: Array = ProjectSettings.get_setting("application/config/version").split(".")
	define_property("editor_version", editor_version, "list", {"show_in_inspector": false})
	define_property("entry_point", "", "dropdown")  # Storyline entry point
	define_property("author", "", "text")
	define_property("description", "", "textarea")


func get_type() -> String:
	return "manifest"
