extends GdUnitTestSuite


## Scene runner for LanguageSwitcher.
var runner


func before_test():
	runner = scene_runner("res://common/layouts/language_switcher/language_switcher.tscn")


func test_language_set_value_locale_dictionary():
	# this scenario happens when .json is first loaded and the value
	# is the entire raw locale dictionary rather than the actual value
	runner.invoke("load_languages", [])
	var localizable = auto_free(Localizable.new(null))
	localizable.value = {"English": "test"}
	assert_str(localizable.value).is_equal("test")


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


func test_first_language_does_not_show_delete_button():
	runner.invoke("load_languages", ["Sindarin", "Khuzdul"])
	var option: LanguageOption = runner.get_property("vbox").get_child(0)
	assert_str(option.line_edit.text).is_equal("Sindarin")
	assert_bool(option.del_button.visible).is_false()


func after_test():
	GlobalVariables.is_exporting_properties = false
	GlobalVariables.language_switcher = null
