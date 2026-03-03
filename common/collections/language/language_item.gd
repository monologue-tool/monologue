class_name LanguageCollectionItem extends ListItem


func initialize_properties() -> void:
	define_property(
		"name",
		"New Language",
		"text",
		{
			"unique": true,
			"placeholder": "English",
			"validation": {"min_length": 1},
		}
	)
	define_property(
		"code",
		"nl",
		"text",
		{
			"unique": true,
			"placeholder": "en",
			"validation": {"min_length": 1, "max_length": 4},
		}
	)
	define_property("protected", false, "bool", {"visible_in_inspector": false}, "Extra")


func get_type() -> String:
	return "language"
