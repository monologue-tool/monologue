extends GdUnitTestSuite

## Property is pure data: no SceneTree, no widgets, no autoloads beyond the type registry,
## which bootstraps itself.
##
## One test per invariant rather than one per method. What a given field type happens to
## default to is the registry's contents, not an invariant, and is not checked here.


func test_a_path_declares_a_category_and_a_name() -> void:
	var notes := Property.new("extra/notes").set_type("textarea")
	assert_str(notes.name).is_equal("notes")
	assert_str(notes.get_category()).is_equal("Extra")
	assert_str(notes.get_path()).is_equal("Extra/notes")

	# Only the last slash separates, and a bare name lands in the general group.
	assert_str(Property.new("a/b/c").set_type("text").name).is_equal("c")
	assert_str(Property.new("text").set_type("text").get_category()).is_equal("General")

	var speaker := (
		Property.new("speaker/name").set_type("text").label("Who speaks").category("Cast")
	)
	assert_str(speaker.get_display_name()).is_equal("Who Speaks")
	assert_str(speaker.get_category()).is_equal("Cast")


func test_the_order_a_declaration_is_written_in_has_no_effect() -> void:
	# set_type() folds the type's defaults in underneath what is already declared, so every
	# spelling of one declaration has to agree.
	for property: Property in [
		Property.new("p").set_type("textarea").multiline(9).default("x"),
		Property.new("p").multiline(9).default("x").set_type("textarea"),
	]:
		assert_int(property.get_settings_value(PropertySettings.KEY_ROWS)).is_equal(9)
		assert_str(property.get_value()).is_equal("x")

	for property: Property in [
		Property.new("p").set_type("text").plain(),
		Property.new("p").plain().set_type("text"),
	]:
		assert_bool(property.is_translatable()).is_false()
		assert_str(property.get_value()).is_equal("")

	# A later call corrects an earlier one. The type's own default never wins over either.
	assert_bool(Property.new("p").default(true).set_type("bool").get_value()).is_true()
	var reopened := Property.new("text").set_type("text").main_property().editable()
	assert_bool(reopened.get_settings_value(PropertySettings.KEY_VISIBLE_IN_INSPECTOR)).is_true()
	var hidden := Property.new("root").set_type("context").main_property()
	assert_bool(hidden.get_settings_value(PropertySettings.KEY_VISIBLE_IN_INSPECTOR)).is_false()


func test_nothing_is_shared_between_two_properties_of_one_type() -> void:
	# The regression: settings used to alias the field type's own defaults dict, so one
	# property's change leaked into every other property of that type.
	var first := Property.new("a").set_type("textarea")
	var second := Property.new("b").set_type("textarea")
	first.multiline(42)

	assert_int(second.get_settings_value(PropertySettings.KEY_ROWS)).is_equal(3)
	var type_defaults: Dictionary = (
		MonologueRegistry.get_instance().get_field("textarea").default_settings
	)
	assert_int(type_defaults[PropertySettings.KEY_ROWS]).is_equal(3)

	# Nor do two properties share a default container, or a value computed per instance.
	var shared: Array = []
	var mine: Array = Property.new("tags").set_type("list").default(shared).get_value()
	var yours: Array = Property.new("tags").set_type("list").default(shared).get_value()
	mine.append("x")
	assert_int(yours.size()).is_equal(0)

	var counter: Array[int] = [0]
	var generator := func() -> int:
		counter[0] += 1
		return counter[0]
	assert_int(Property.new("n").set_type("int").default(generator).get_value()).is_equal(1)
	assert_int(Property.new("n").set_type("int").default(generator).get_value()).is_equal(2)


func test_freezing_locks_the_declaration_and_leaves_the_user_their_overrides() -> void:
	var property := Property.new("p").set_type("text")
	property.freeze()

	property.required()
	property.set_type("int")
	assert_bool(property.get_settings_value(PropertySettings.KEY_REQUIRED, false)).is_false()
	assert_str(property.type).is_equal("text")

	# An override wins over the declaration, announces itself, and can be taken back.
	assert_dict(property._get_overrides()).is_empty()
	var monitor: Object = monitor_signals(property)
	property.set_settings_value(PropertySettings.KEY_EDITABLE, false)

	assert_signal(monitor).is_emitted("settings_changed")
	assert_bool(property.get_settings_value(PropertySettings.KEY_EDITABLE)).is_false()
	assert_dict(property._get_overrides()).is_not_empty()

	property.erase_settings_value(PropertySettings.KEY_EDITABLE)
	assert_bool(property.get_settings_value(PropertySettings.KEY_EDITABLE)).is_true()

	property._restore("hi", {PropertySettings.KEY_EXPOSED: true})
	assert_str(property.get_value()).is_equal("hi")
	assert_bool(property.get_settings_value(PropertySettings.KEY_EXPOSED)).is_true()


func test_a_declared_rule_reaches_both_the_widget_and_the_check() -> void:
	# A number that stops at 60 and a rule that allows 200 would disagree, and only one of
	# the two would be visible.
	var seconds := Property.new("seconds").set_type("float").bounds(0.0, 60.0, 0.1)

	assert_float(seconds.get_settings_value(PropertySettings.KEY_MIN_VALUE)).is_equal(0.0)
	assert_float(seconds.get_settings_value(PropertySettings.KEY_MAX_VALUE)).is_equal(60.0)
	assert_float(seconds.get_settings_value(PropertySettings.KEY_STEP)).is_equal(0.1)

	var bounds: Dictionary = seconds.get_settings_value(PropertySettings.KEY_VALIDATION)
	assert_float(bounds["min"]).is_equal(0.0)
	assert_float(bounds["max"]).is_equal(60.0)

	# Rules accumulate rather than replace one another.
	var code := Property.new("code").set_type("text").required().min_length(1).max_length(4)
	var rules: Dictionary = code.get_settings_value(PropertySettings.KEY_VALIDATION)
	assert_int(rules["min_length"]).is_equal(1)
	assert_int(rules["max_length"]).is_equal(4)
	assert_bool(code.get_settings_value(PropertySettings.KEY_REQUIRED)).is_true()

	# An unbounded number declares no range at all, which is what tells the widget to drag
	# freely and draw no fill bar.
	var count := Property.new("count").set_type("int")
	assert_bool(count.has_settings(PropertySettings.KEY_MIN_VALUE)).is_false()
	assert_bool(count.has_settings(PropertySettings.KEY_MAX_VALUE)).is_false()
