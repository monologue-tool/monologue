class_name ManifestDocument extends InspectableDocument


func initialize_properties() -> void:
	var editor_version: Array = ProjectSettings.get_setting("application/config/version").split(".")

	# Was declared with a "show_in_inspector" key, which is not a real setting, so this
	# has been visible all along. The intent was clearly to hide it.
	define_property(Property.new("editor_version")
		.set_type("list")
		.default(editor_version)
		.hidden_in_inspector())

	define_property(Property.new("entry_point")
		.set_type("dropdown")
		.tooltip("Storyline the project starts from."))

	define_property(Property.new("author")
		.set_type("text"))

	define_property(Property.new("description")
		.set_type("textarea"))


func get_type() -> String:
	return "manifest"
