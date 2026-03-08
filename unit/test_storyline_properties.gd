extends GdUnitTestSuite


func test_can_add_character_to_storyline() -> void:
	var storyline: StorylineDocument = auto_free(StorylineDocument.new("Test Story"))
	var character: Variant = CollectionBucket.create_item("characters", CommandManager.new())
	character.set_property_value("name", "Alice")
	storyline.set_property_value("characters", [character._to_dict()])
	var characters: Property = storyline.get_property("characters")
	var result: Variant = characters.get_value()
	assert_array(result).has_size(1)
	assert_str(result[0]["name"]["value"]).is_equal("Alice")


func test_can_add_variable_to_storyline() -> void:
	var storyline: StorylineDocument = auto_free(StorylineDocument.new("Test Story"))
	var variable: ListItem = CollectionBucket.create_item("variables", CommandManager.new())
	variable.set_property_value("name", "score")
	storyline.set_property_value("variables", [variable._to_dict()])
	var variables: Property = storyline.get_property("variables")
	var result: Variant = variables.get_value()
	assert_array(result).has_size(1)
	assert_str(result[0]["name"]["value"]).is_equal("score")
