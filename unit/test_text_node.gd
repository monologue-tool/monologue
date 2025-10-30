extends GdUnitTestSuite


func test_get_title_type():
	var node = auto_free(TextNode.new())
	assert_str(node.get_title_type()).is_equal("")
