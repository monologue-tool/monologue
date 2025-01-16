extends GdUnitTestSuite


## Scene runner for LanguageSwitcher.
var runner


func before_test():
	runner = scene_runner("res://common/layouts/language_switcher/language_switcher.tscn")
	var mock_graph_edit = mock(MonologueGraphEdit)
	runner.set_property("graph_edit", mock_graph_edit)


func test_first_language_does_not_show_delete_button():
	runner.invoke("load_languages", ["Sindarin", "Khuzdul"])
	var first_option: LanguageOption = runner.get_property("vbox").get_child(0)
	assert_str(first_option.line_edit.text).is_equal("Sindarin")
	assert_bool(first_option.del_button.visible).is_false()
	var second_option: LanguageOption = runner.get_property("vbox").get_child(1)
	assert_str(second_option.line_edit.text).is_equal("Khuzdul")
	assert_bool(second_option.del_button.visible).is_true()


func test_language_get_raw_data_deleted():
	# when user sets a value in a language and then deletes that language
	var localizable = auto_free(Localizable.new(null))
	localizable.value = "im a test"
	runner.invoke("add_language", "Finnish")
	runner.set_property("selected_index", 1)
	localizable.value = "olen testi"
	runner.get_property("vbox").get_child(1)._on_btn_delete_pressed()
	GlobalVariables.is_exporting_properties = true
	assert_dict(localizable.value).is_equal({"English": "im a test"})


func test_language_get_value_renamed():
	GlobalVariables.is_exporting_properties = true
	var localizable = auto_free(Localizable.new(null))
	localizable.value = "beep boop"
	assert_dict(localizable.value).is_equal({"English": "beep boop"})
	runner.get_property("vbox").get_child(0).set_language_name("Martian")
	assert_dict(localizable.value).is_equal({"Martian": "beep boop"})
	assert_array(runner.invoke("get_languages").keys()).is_equal(["Martian"])


func test_language_set_value_locale_dictionary():
	# this scenario happens when .json is first loaded and the value
	# is the entire raw locale dictionary rather than the actual value
	runner.invoke("load_languages", [])
	var localizable = auto_free(Localizable.new(null))
	localizable.value = {"English": "test"}
	assert_str(localizable.value).is_equal("test")


func test_language_set_value_locale_dictionary_non_default():
	runner.invoke("load_languages", ["Español", "Italiano"])
	runner.set_property("selected_index", 1)
	var localizable = auto_free(Localizable.new(null))
	localizable.value = {"Español": "hola soy una prueba", "Italiano": "ciao sono un test"}
	assert_str(localizable.value).is_equal("ciao sono un test")


func test_language_set_value_string():
	var localizable = auto_free(Localizable.new(null))
	localizable.value = "test"
	GlobalVariables.is_exporting_properties = true
	assert_dict(localizable.value).is_equal({"English": "test"})


func test_language_set_value_and_switch_locales():
	runner.invoke("load_languages", ["Deutsch", "Français", "日本語"])
	var localizable = auto_free(Localizable.new(null))
	var de = "hallo! ich bin ein test"
	localizable.value = de
	assert_str(localizable.value).is_equal(de)
	
	runner.set_property("selected_index", 1)
	var fr = "bonjour je suis un test"
	localizable.value = fr
	assert_str(localizable.value).is_equal(fr)
	
	runner.set_property("selected_index", 2)
	var jp = "ちゃっす、テストだよ"
	localizable.value = jp
	assert_str(localizable.value).is_equal(jp)
	
	GlobalVariables.is_exporting_properties = true
	assert_dict(localizable.value).is_equal({"Deutsch": de, "Français": fr, "日本語": jp})


func test_load_languages():
	runner.invoke("load_languages", ["English", "Spanish"])
	var vbox: VBoxContainer = runner.get_property("vbox")
	assert_int(vbox.get_child_count()).is_equal(2)
	assert_str(str(vbox.get_child(0))).is_equal("English")
	assert_str(str(vbox.get_child(1))).is_equal("Spanish")


func test_load_languages_duplicate():
	runner.invoke("load_languages", ["English", "Irish", "English", "English"])
	var vbox: VBoxContainer = runner.get_property("vbox")
	assert_int(vbox.get_child_count()).is_equal(2)
	assert_str(str(vbox.get_child(0))).is_equal("English")
	assert_str(str(vbox.get_child(1))).is_equal("Irish")


func after_test():
	GlobalVariables.is_exporting_properties = false
	GlobalVariables.language_switcher = null
