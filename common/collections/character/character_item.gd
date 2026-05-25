class_name CharacterCollectionItem extends ListItem


func initialize_properties() -> void:
	var default_portrait: ListItem = CollectionBucket.create_item("portraits", history)
	default_portrait.set_property_value("name", "default")
	default_portrait.set_property_value("protected", true)
	
	define_property(
		"name",
		NameGenerator.generate,
		"text",
		{
			"required": true,
			"unique": true,
			"protect": true,
			"validation": {"min_length": 1},
		},
	)
	define_property("display_name", "", "text")
	define_property("nicknames", "", "text")
	define_property(
		"default_portrait",
		"",
		"dropdown",
		{ "source": "self:portraits" },
		"Portraits"
	)
	define_property(
		"portraits",
		[default_portrait._to_dict()],
		"list",
		{ "collection": "portraits" },
		"Portraits"
	)
	define_property("description", "", "textarea", {}, "Extra")
	define_property("protected", false, "bool", { "visible_in_inspector": false }, "Extra")


func get_type() -> String:
	return "character"


func _on_property_changed(_pname: String) -> void:
	pass


func get_preview_property_names() -> Array[String]:
	return ["name", "description"]
