extends GdUnitTestSuite


func test_dropdown_field_exists() -> void:
	var descriptor: BucketDescriptor = FieldBucket.get_descriptor("dropdown")
	assert_object(descriptor).is_not_null()
	assert_str(descriptor.name).is_equal("dropdown")


func test_sentence_node_speaker_is_dropdown() -> void:
	var node: SentenceNode = auto_free(SentenceNode.new())
	var speaker_prop: Property = node.get_property("speaker")
	assert_object(speaker_prop).is_not_null()
	assert_str(speaker_prop.type).is_equal("dropdown")


func test_dropdown_has_source_setting() -> void:
	var node: SentenceNode = auto_free(SentenceNode.new())
	var speaker_prop: Property = node.get_property("speaker")
	var source: String = speaker_prop.get_settings_value("source", "")
	assert_str(source).is_equal("characters")
