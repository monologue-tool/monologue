extends GdUnitTestSuite


func test_sentence_node_main_property():
	var node = auto_free(SentenceNode.new())
	var main_prop = node.get_property("sentence")
	assert_object(main_prop).is_not_null()
	assert_str(main_prop.type).is_equal("context")
	assert_bool(main_prop.settings.get("visible_in_graph")).is_true()
	assert_bool(main_prop.settings.get("is_main_property")).is_true()
	# SentenceNode main property should not be editable
	assert_bool(main_prop.settings.get("editable")).is_false()


func test_text_node_main_property():
	var node = auto_free(TextNode.new())
	var main_prop = node.get_property("text")
	assert_object(main_prop).is_not_null()
	assert_str(main_prop.type).is_equal("text")
	assert_bool(main_prop.settings.get("visible_in_graph")).is_true()
	assert_bool(main_prop.settings.get("is_main_property")).is_true()
	# TextNode main property should be editable
	assert_bool(main_prop.settings.get("editable")).is_true()


func test_root_node_main_property():
	var node = auto_free(RootNode.new())
	var main_prop = node.get_property("root")
	assert_object(main_prop).is_not_null()
	assert_str(main_prop.type).is_equal("context")
	assert_bool(main_prop.settings.get("visible_in_graph")).is_true()
	assert_bool(main_prop.settings.get("is_main_property")).is_true()
	# RootNode main property should not be editable
	assert_bool(main_prop.settings.get("editable")).is_false()


func test_connection_tracking():
	var node = auto_free(SentenceNode.new())
	var main_prop = node.get_property("sentence")
	
	# Initially no connections
	assert_bool(main_prop.is_port_connected()).is_false()
	
	# Add a connection
	main_prop.add_connection_to("node2", "prop2", 0)
	assert_bool(main_prop.is_port_connected()).is_true()
	assert_int(main_prop.connected_to.size()).is_equal(1)
	
	# Remove connection
	main_prop.remove_connection_to("node2", 0)
	assert_bool(main_prop.is_port_connected()).is_false()
