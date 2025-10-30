extends GdUnitTestSuite


func test_sentence_node_title_property():
	var node = auto_free(SentenceNode.new())
	var title_prop = node.get_property("title")
	assert_object(title_prop).is_not_null()
	assert_str(title_prop.get_value()).is_equal("Sentence")
	assert_str(title_prop.type).is_equal("context")
	assert_bool(title_prop.settings.get("display")).is_true()
	# SentenceNode title should not be editable
	assert_bool(title_prop.settings.get("protected")).is_true()


func test_text_node_title_property():
	var node = auto_free(TextNode.new())
	var title_prop = node.get_property("title")
	assert_object(title_prop).is_not_null()
	assert_str(title_prop.get_value()).is_equal("Text")
	assert_str(title_prop.type).is_equal("text")
	assert_bool(title_prop.settings.get("display")).is_true()
	# TextNode title should be editable
	assert_bool(title_prop.settings.get("protected")).is_false()


func test_root_node_title_property():
	var node = auto_free(RootNode.new())
	var title_prop = node.get_property("title")
	assert_object(title_prop).is_not_null()
	assert_str(title_prop.get_value()).is_equal("Root")
	assert_str(title_prop.type).is_equal("context")
	assert_bool(title_prop.settings.get("display")).is_true()
	# RootNode title should not be editable
	assert_bool(title_prop.settings.get("protected")).is_true()


func test_title_property_can_be_changed():
	var node = auto_free(SentenceNode.new())
	var title_prop = node.get_property("title")
	title_prop.set_value("Custom Title")
	assert_str(title_prop.get_value()).is_equal("Custom Title")
