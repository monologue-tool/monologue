extends GdUnitTestSuite


func test_title_property():
	var node = auto_free(SentenceNode.new())
	var title_prop = node.get_property("sentence")
	assert_object(title_prop).is_not_null()
	assert_str(title_prop.type).is_equal("context")


func test_backwards_compatibility():
	var node = auto_free(SentenceNode.new())
	var ge = mock(MonologueGraphEdit, CALL_REAL_FUNC)
	ge.add_child(node)
	node._preview = mock(Label)

	node._from_dict(
		{
			"$type": "NodeSentence",
			"ID": "old-test-sentence",
			"NextID": "old-next-sentence",
			"Sentence": "monster",
			"SpeakerID": 3,
			"DisplaySpeakerName": "teela",
			"DisplayVariant": "kagha",
			"VoicelinePath": "../Voice/to_me.mp3",
			"EditorPosition": {"x": 2180, "y": 880}
		}
	)

	assert_int(node.speaker.value).is_equal(3)
	assert_str(node.display_name.value).is_equal("teela")
	assert_str(node.voiceline.value).is_equal("../Voice/to_me.mp3")
