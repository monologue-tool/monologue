extends GdUnitTestSuite


func test_storyline_has_characters_property():
	var storyline = auto_free(StorylineDocument.new("Test Story"))
	var characters_prop = storyline.get_property("characters")
	assert_object(characters_prop).is_not_null()
	assert_str(characters_prop.type).is_equal("list")


func test_storyline_has_variables_property():
	var storyline = auto_free(StorylineDocument.new("Test Story"))
	var variables_prop = storyline.get_property("variables")
	assert_object(variables_prop).is_not_null()
	assert_str(variables_prop.type).is_equal("list")


func test_characters_property_has_schema():
	var storyline = auto_free(StorylineDocument.new("Test Story"))
	var characters_prop = storyline.get_property("characters")
	var schema = characters_prop.get_settings_value("data_schema", {})
	assert_bool(schema.has("name")).is_true()
	assert_bool(schema.has("color")).is_true()


func test_variables_property_has_schema():
	var storyline = auto_free(StorylineDocument.new("Test Story"))
	var variables_prop = storyline.get_property("variables")
	var schema = variables_prop.get_settings_value("data_schema", {})
	assert_bool(schema.has("name")).is_true()
	assert_bool(schema.has("value")).is_true()


func test_can_add_character_to_storyline():
	var storyline = auto_free(StorylineDocument.new("Test Story"))
	var characters = [{"name": "Alice", "color": "#FF0000"}]
	storyline.set_property_value("characters", characters)
	var result = storyline.get_property_value("characters")
	assert_array(result).has_size(1)
	assert_str(result[0]["name"]).is_equal("Alice")


func test_can_add_variable_to_storyline():
	var storyline = auto_free(StorylineDocument.new("Test Story"))
	var variables = [{"name": "score", "value": "0"}]
	storyline.set_property_value("variables", variables)
	var result = storyline.get_property_value("variables")
	assert_array(result).has_size(1)
	assert_str(result[0]["name"]).is_equal("score")
