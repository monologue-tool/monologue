class_name EmptyTemplate extends ProjectTemplate

func setup_collection(project: MonologueProject) -> void:
	var command_manager: CommandManager = project.command_manager

	var default_narrator: CollectionItem = MonologueRegistry.get_instance().create_collection_item(
		"characters", command_manager
	)
	default_narrator.set_property_value("name", "Narrator")
	default_narrator.set_property_value("protected", true)

	var default_language: CollectionItem = MonologueRegistry.get_instance().create_collection_item(
		"languages", command_manager
	)
	default_language.set_property_value("name", "English")
	default_language.set_property_value("code", "en")
	default_language.set_property_value("protected", true)

	var ease_item: CollectionItem = MonologueRegistry.get_instance().create_collection_item(
		"eases", command_manager
	)
	ease_item.set_property_value("name", "Linear")
	ease_item.set_property_value("ease", [0.0, 0.0, 1.0, 1.0])
	ease_item.set_property_value("is_default", true)
	var linear_ease_data: Dictionary = ease_item._to_dict()

	project.collections.append(
		CollectionDocument.new("characters", [default_narrator._to_dict()], command_manager)
	)
	project.collections.append(CollectionDocument.new("variables", [], command_manager))
	project.collections.append(CollectionDocument.new("items", [], command_manager))
	project.collections.append(CollectionDocument.new("locations", [], command_manager))
	project.collections.append(
		CollectionDocument.new("languages", [default_language._to_dict()], command_manager)
	)
	project.collections.append(CollectionDocument.new("eases", [linear_ease_data], command_manager))

func setup_default_storyline(storyline: StorylineDocument) -> void:
	var history: CommandManager = storyline.history
	var root_node: InspectableNode = MonologueRegistry.get_instance().create_node("root", history)
	storyline.register_node(root_node)
