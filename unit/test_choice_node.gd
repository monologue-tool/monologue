extends GdUnitTestSuite


var switcher  # language switcher
var lang1     # language option 1
var lang2     # language option 2


func before_test():
	switcher = mock(LanguageSwitcher)
	lang1 = auto_free(LanguageOption.new())
	lang2 = auto_free(LanguageOption.new())
	lang1.line_edit = mock(LineEdit)
	lang2.line_edit = mock(LineEdit)
	lang1.name = "LanguageOption1"
	lang1.language_name = "Lang1"
	lang2.name = "LanguageOption2"
	lang2.language_name = "Lang2"
	do_return(lang1).on(switcher).get_by_node_name("LanguageOption1")
	do_return(lang2).on(switcher).get_by_node_name("LanguageOption2")
	do_return({"Lang1": lang1.name, "Lang2": lang2.name}).on(switcher).get_languages()
	
	do_return(lang1).on(switcher).get_current_language()
	GlobalVariables.language_switcher = switcher


func test_add_option():
	var runner = scene_runner("res://unit/empty_test.tscn")
	var choice_node = auto_free(ChoiceNode.new())
	var mock_graph_edit = mock(MonologueGraphEdit, CALL_REAL_FUNC)
	mock_graph_edit.add_child(choice_node)
	runner.invoke("add_child", mock_graph_edit)
	
	var option_node = choice_node.add_option({
		"$type": "NodeOption",
		"ID": "addid",
		"NextID": "nexop",
		"Option": {"Lang2": "lang2test"},
		"EnableByDefault": true,
		"OneShot": false
	})
	choice_node.options.value.append(option_node._to_dict())
	var option_dict = choice_node.options.value[2].get("Option")
	assert_dict(option_dict).is_equal({"Lang2": "lang2test"})


func test_to_fields():
	var runner = scene_runner("res://nodes/choice_node/choice_node.tscn")
	var test_dict = {}
	runner.invoke("_to_fields", test_dict)
	assert_dict(test_dict).contains_keys(["OptionsID"])
	
	var options_id = test_dict.get("OptionsID", [])
	assert_array(options_id).has_size(2)
	assert_bool(options_id[0] is String)
	assert_bool(options_id[1] is String)


func test_language_integration():
	# setup choice node
	var runner = scene_runner("res://unit/empty_test.tscn")
	var choice_node = auto_free(ChoiceNode.new())
	var mock_graph_edit = mock(MonologueGraphEdit, CALL_REAL_FUNC)
	mock_graph_edit.add_child(choice_node)
	runner.invoke("add_child", mock_graph_edit)
	var option1 = choice_node.get_child(0)
	var opt1_text = "we are number one"
	option1.choice_node = choice_node
	option1.option.value = (opt1_text)
	option1.update_parent("", opt1_text)  # simulate field update
	var option2 = choice_node.get_child(1)
	var opt2_text = "i am number two"
	option2.choice_node = choice_node
	option2.option.value = (opt2_text)
	option2.update_parent("", opt2_text) # simulate field update
	
	# check option preview text before language switch
	choice_node.reload_preview()
	assert_str(choice_node.get_child(0).preview_label.text).is_equal(opt1_text)
	assert_str(choice_node.get_child(1).preview_label.text).is_equal(opt2_text)
	var e1 = {"Lang1": "we are number one"}
	var e2 = {"Lang1": "i am number two"}
	assert_dict(choice_node.get_child(0).option.to_raw_value()).is_equal(e1)
	assert_dict(choice_node.get_child(1).option.to_raw_value()).is_equal(e2)
	
	# switch languages and reload_preview() should be empty string
	do_return(lang2).on(switcher).get_current_language()
	choice_node.reload_preview()
	assert_str(choice_node.get_child(0).preview_label.text).is_equal("")
	assert_str(choice_node.get_child(1).preview_label.text).is_equal("")

	var opt2_text2 = "they are twins"
	choice_node.get_child(1).option.value = (opt2_text2)
	choice_node.get_child(1).update_parent("", opt2_text2)
	var d2 = e2.merged({"Lang2": opt2_text2})
	assert_dict(choice_node.get_child(1).option.to_raw_value()).is_equal(d2)


func test_restore_options():
	var runner = scene_runner("res://unit/empty_test.tscn")
	var choice_node = auto_free(ChoiceNode.new())
	var mock_graph_edit = mock(MonologueGraphEdit, CALL_REAL_FUNC)
	mock_graph_edit.add_child(choice_node)
	runner.invoke("add_child", mock_graph_edit)
	var option1 = choice_node.get_child(0)
	var opt1_text = "first"
	option1.choice_node = choice_node
	option1.option.value = (opt1_text)
	option1.update_parent("", opt1_text)
	var option2 = choice_node.get_child(1)
	var opt2_text = "second"
	option2.choice_node = choice_node
	option2.option.raw_data = {"LanguageOption1": "bla bla bla", "LanguageOption2": opt2_text}
	option2.update_parent("", opt2_text)
	
	var test_option = auto_free(LanguageOption.new())
	do_return(test_option).on(switcher).add_language(lang2.language_name)
	var deletion = DeleteLanguageHistory.new(mock_graph_edit, lang2.language_name, lang2.name)
	choice_node.store_options(deletion.node_name, deletion.restoration, deletion.choices)
	deletion.redo()
	assert_object(lang2).is_queued_for_deletion()
	deletion.undo()
	var expected = {"Lang1": "bla bla bla", "Lang2": opt2_text}
	assert_dict(choice_node.options.value[1].get("Option")).is_equal(expected)


func test_update_parent():
	var option_node = auto_free(OptionNode.new())
	var choice_node = auto_free(ChoiceNode.new())
	choice_node.options.value = [{
		"$type": "NodeOption",
		"ID": "upid",
		"NextID": -1,
		"Option": {"Lang2": "tu vies bien"},
		"EnableByDefault": false,
		"OneShot": true
	}]
	
	var expected = {"Lang1": "whatever", "Lang2": "como sea"}
	option_node.choice_node = choice_node
	option_node.option.value = expected
	option_node.update_parent("before", "after")
	assert_dict(choice_node.options.value[0].get("Option")).is_equal(expected)


func after_test():
	GlobalVariables.language_switcher = null
