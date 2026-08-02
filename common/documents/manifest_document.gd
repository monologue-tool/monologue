class_name ManifestDocument extends InspectableDocument

## 2: ids carry a type prefix and are immutable, references store an id instead of a
## display name, and a storyline writes one "connections" list instead of a copy on
## each property. Version 1 files are refused rather than half-read.
const FORMAT_VERSION: int = 2


func initialize_properties() -> void:
	define_property(Property.new("format_version")
		.set_type("int")
		.default(FORMAT_VERSION)
		.read_only()
		.hidden_in_inspector())

	var editor_version: Array = ProjectSettings.get_setting("application/config/version").split(".")

	define_property(Property.new("editor_version")
		.set_type("list")
		.default(editor_version)
		.hidden_in_inspector())

	define_property(Property.new("entry_point")
		.set_type("reference")
		.reference_scope("storylines")
		.tooltip("Storyline the project starts from."))

	define_property(Property.new("author")
		.set_type("text")
		.plain())

	define_property(Property.new("description")
		.set_type("textarea"))


func get_type() -> String:
	return "manifest"
