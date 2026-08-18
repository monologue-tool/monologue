class_name DefaultTemplate extends ProjectTemplate


func _get_default_eases() -> Dictionary:
	return {
		"Ease": [0.25, 0.10, 0.25, 1.0],
		"Linear": [0.0, 0.0, 1.0, 1.0],
		"Ease-In": [0.42, 0.0, 1.0, 1.0],
		"Ease-Out": [0.0, 0.0, 0.58, 1.0],
		"Ease-In-Out": [0.42, 0.0, 0.58, 1.0]
	}

func _get_default_languages() -> Dictionary:
	return { "en": "English" }

func setup_collection(project: MonologueProject) -> void:
	var command_manager: CommandManager = project.command_manager

	var default_narrator: CollectionItem = MonologueRegistry.get_instance().create_collection_item(
		"characters", command_manager
	)
	default_narrator.set_property_value("name", "Narrator")
	default_narrator.set_property_value("protected", true)

	var default_languages: Dictionary = _get_default_languages()
	var languages_data: Array = []
	for language_code: String in _get_default_languages():
		var language_name: String = default_languages[language_code]
		var language: CollectionItem = MonologueRegistry.get_instance().create_collection_item(
			"languages", command_manager
		)
		language.set_property_value("name", language_name)
		language.set_property_value("code", language_code)
		if language_code == "en":
			language.set_property_value("protected", true)

		languages_data.append(language._to_dict())

	var default_eases: Dictionary = _get_default_eases()
	var eases_data: Array = []
	for ease_name: String in default_eases:
		var ease_item: CollectionItem = MonologueRegistry.get_instance().create_collection_item(
			"eases", command_manager
		)
		ease_item.set_property_value("name", ease_name)
		ease_item.set_property_value("ease", default_eases.get(ease_name))
		ease_item.set_property_value("is_default", ease_name == "Ease")
		eases_data.append(ease_item._to_dict())

	project.collections.append(
		CollectionDocument.new("characters", [default_narrator._to_dict()], command_manager)
	)
	project.collections.append(CollectionDocument.new("variables", [], command_manager))
	project.collections.append(CollectionDocument.new("items", [], command_manager))
	project.collections.append(CollectionDocument.new("locations", [], command_manager))
	project.collections.append(
		CollectionDocument.new("languages", languages_data, command_manager)
	)
	project.collections.append(CollectionDocument.new("eases", eases_data, command_manager))

func setup_default_storyline(storyline: StorylineDocument) -> void:
	var history: CommandManager = storyline.history

	var root_node: InspectableNode = MonologueRegistry.get_instance().create_node("root", history)
	var root_mp: Property = root_node.get_main_property()

	var sent_node: InspectableNode = MonologueRegistry.get_instance().create_node(
		"sentence", history
	)
	var sent_mp: Property = sent_node.get_main_property()

	var option_node: InspectableNode = MonologueRegistry.get_instance().create_node(
		"option", history
	)
	var option_mp: Property = option_node.get_main_property()

	var choice_node: InspectableNode = MonologueRegistry.get_instance().create_node(
		"choice", history
	)
	var choice_mp: Property = choice_node.get_main_property()
	var choice_opt: Array[Dictionary] = []
	for _i: int in range(2):
		var choice_item: CollectionItem = MonologueRegistry.get_instance().create_collection_item(
			"options", history
		)
		choice_opt.append(choice_item._to_dict())

	sent_node.get_property("editor_position").set_value([240.0, 0])
	option_node.get_property("editor_position").set_value([240.0, 120.0])
	choice_node.get_property("editor_position").set_value([480.0, 0])
	choice_node.get_property("choices").set_value(choice_opt)
	choice_node.get_property("choices").set_settings_value("exposed", true)

	storyline.register_node(root_node)
	storyline.register_node(sent_node)
	storyline.register_node(option_node)
	storyline.register_node(choice_node)

	storyline.add_connection(
		NodeConnection.create(root_node.get_id(), root_mp.name, sent_node.get_id(), sent_mp.name)
	)
	storyline.add_connection(
		NodeConnection.create(sent_node.get_id(), sent_mp.name, choice_node.get_id(), choice_mp.name)
	)
	storyline.add_connection(
		NodeConnection.create(option_node.get_id(), option_mp.name, choice_node.get_id(), "choices")
	)
