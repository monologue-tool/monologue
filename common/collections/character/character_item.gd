class_name CharacterCollectionItem extends CollectionItem


func initialize_properties() -> void:
	var default_portrait: CollectionItem = MonologueRegistry.get_instance().create_collection_item(
		"portraits", history
	)
	default_portrait.set_property_value("name", "default")
	default_portrait.set_property_value("protected", true)

	define_name_property(NameGenerator.generate)

	define_property(Property.new("display_name")
		.set_type("text"))

	define_property(Property.new("nicknames")
		.set_type("text"))

	define_property(Property.new("portraits/default_portrait")
		.set_type("dropdown")
		.source("self:portraits"))

	define_property(Property.new("portraits/portraits")
		.set_type("collection")
		.default([default_portrait._to_dict()])
		.collection("portraits"))

	define_property(Property.new("extra/description")
		.set_type("textarea"))

	define_property(Property.new("extra/protected")
		.set_type("bool")
		.hidden_in_inspector())


func get_type() -> String:
	return "character"


func get_preview_property_names() -> Array[String]:
	return ["name", "description"]
