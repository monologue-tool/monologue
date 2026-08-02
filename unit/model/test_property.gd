# gdlint: disable=max-public-methods
extends GdUnitTestSuite

## Property is pure data: no SceneTree, no widgets, no autoloads beyond the type
## registry, which bootstraps itself.


func test_a_path_splits_into_category_and_name() -> void:
	var notes := Property.new("extra/notes").set_type("textarea")

	assert_str(notes.name).is_equal("notes")
	assert_str(notes.get_category()).is_equal("Extra")


func test_a_bare_name_lands_in_general() -> void:
	var text := Property.new("text").set_type("text")

	assert_str(text.name).is_equal("text")
	assert_str(text.get_category()).is_equal("General")


func test_the_category_segment_is_title_cased_for_display() -> void:
	assert_str(Property.new("advanced/one_shot").set_type("bool").get_category()).is_equal("Advanced")
	assert_str(Property.new("general/text").set_type("text").get_category()).is_equal("General")


func test_only_the_last_slash_separates_the_name() -> void:
	var nested := Property.new("a/b/c").set_type("text")

	assert_str(nested.name).is_equal("c")


func test_category_can_still_be_overridden_after_the_path() -> void:
	var property := Property.new("extra/notes").set_type("text").category("Speaker")

	assert_str(property.get_category()).is_equal("Speaker")


func test_get_path_rebuilds_what_was_declared() -> void:
	assert_str(Property.new("extra/notes").set_type("text").get_path()).is_equal("Extra/notes")


func test_set_type_brings_in_that_types_defaults() -> void:
	var line := Property.new("line").set_type("textarea")

	# From PropertySettings.DEFAULTS.
	assert_bool(line.get_settings_value(PropertySettings.KEY_EDITABLE)).is_true()
	# From the textarea field type.
	assert_bool(line.get_settings_value(PropertySettings.KEY_MULTILINE)).is_true()
	assert_int(line.get_settings_value(PropertySettings.KEY_ROWS)).is_equal(3)


func test_the_field_types_default_value_is_used_when_none_is_given() -> void:
	# text is translated, so it starts as no translations rather than an empty string.
	assert_dict(Property.new("a").set_type("text").get_value()).is_empty()
	assert_str(Property.new("a").set_type("text").plain().get_value()).is_equal("")
	assert_int(Property.new("b").set_type("int").get_value()).is_equal(0)
	assert_bool(Property.new("c").set_type("bool").get_value()).is_false()


func test_whether_text_is_translated_does_not_depend_on_declaration_order() -> void:
	var type_first := Property.new("p").set_type("text").plain()
	var plain_first := Property.new("p").plain().set_type("text")

	for property: Property in [type_first, plain_first]:
		assert_bool(property.is_translatable()).is_false()
		assert_str(property.get_value()).is_equal("")


func test_textarea_is_authoring_text_and_is_not_translated() -> void:
	assert_bool(Property.new("notes").set_type("textarea").is_translatable()).is_false()
	assert_bool(Property.new("line").set_type("text").is_translatable()).is_true()
	# A multi-line property the player reads asks for it explicitly.
	assert_bool(
		Property.new("d").set_type("textarea").translatable().is_translatable()
	).is_true()


func test_an_explicit_default_beats_the_field_types() -> void:
	assert_str(
		Property.new("a").set_type("text").plain().default("hello").get_value()
	).is_equal("hello")


func test_declaration_order_does_not_matter() -> void:
	# set_type() folds the type's defaults in underneath what is already declared,
	# so these two spellings have to agree.
	var type_first := Property.new("p").set_type("textarea").multiline(9).default("x")
	var type_last := Property.new("p").multiline(9).default("x").set_type("textarea")

	for property: Property in [type_first, type_last]:
		assert_int(property.get_settings_value(PropertySettings.KEY_ROWS)).is_equal(9)
		assert_str(property.get_value()).is_equal("x")
		assert_bool(property.get_settings_value(PropertySettings.KEY_MULTILINE)).is_true()


func test_set_type_never_overwrites_an_explicit_default() -> void:
	assert_bool(Property.new("p").default(true).set_type("bool").get_value()).is_true()


func test_a_callable_default_is_evaluated_per_instance() -> void:
	var counter: Array[int] = [0]
	var generator := func() -> int:
		counter[0] += 1
		return counter[0]

	assert_int(Property.new("n").set_type("int").default(generator).get_value()).is_equal(1)
	assert_int(Property.new("n").set_type("int").default(generator).get_value()).is_equal(2)


func test_container_defaults_are_not_shared_between_instances() -> void:
	# Without a deep copy, two nodes of the same type would push into one Array.
	var shared: Array = []
	var first: Array = Property.new("tags").set_type("list").default(shared).get_value()
	var second: Array = Property.new("tags").set_type("list").default(shared).get_value()

	first.append("x")

	assert_int(second.size()).is_equal(0)


func test_two_properties_of_one_type_do_not_share_settings() -> void:
	# The regression: settings used to alias the field type's own defaults dict, so
	# one property's change leaked into every other property of that type.
	var first := Property.new("a").set_type("textarea")
	var second := Property.new("b").set_type("textarea")

	first.multiline(42)

	assert_int(second.get_settings_value(PropertySettings.KEY_ROWS)).is_equal(3)
	var type_defaults: Dictionary = (
		MonologueRegistry.get_instance().get_field("textarea").default_settings
	)
	assert_int(type_defaults[PropertySettings.KEY_ROWS]).is_equal(3)


func test_a_declaration_reads_top_to_bottom() -> void:
	var speaker := (
		Property
		. new("speaker/name")
		. set_type("text")
		. label("Who speaks")
		. required()
		. min_length(2)
		. tooltip("Shown before the line.")
	)

	assert_str(speaker.get_display_name()).is_equal("Who Speaks")
	assert_str(speaker.get_category()).is_equal("Speaker")
	assert_bool(speaker.get_settings_value(PropertySettings.KEY_REQUIRED)).is_true()
	assert_int(speaker.get_settings_value(PropertySettings.KEY_VALIDATION)["min_length"]).is_equal(2)


func test_repeated_rules_accumulate_rather_than_replace() -> void:
	var code := Property.new("code").set_type("text").min_length(1).max_length(4)

	var rules: Dictionary = code.get_settings_value(PropertySettings.KEY_VALIDATION)
	assert_int(rules["min_length"]).is_equal(1)
	assert_int(rules["max_length"]).is_equal(4)


func test_bounds_sets_the_widget_range_and_the_check_together() -> void:
	# A number that stops at 60 and a rule that allows 200 would disagree, and only one
	# of the two would be visible.
	var seconds := Property.new("seconds").set_type("float").bounds(0.0, 60.0, 0.1)

	assert_float(seconds.get_settings_value(PropertySettings.KEY_MIN_VALUE)).is_equal(0.0)
	assert_float(seconds.get_settings_value(PropertySettings.KEY_MAX_VALUE)).is_equal(60.0)
	assert_float(seconds.get_settings_value(PropertySettings.KEY_STEP)).is_equal(0.1)

	var rules: Dictionary = seconds.get_settings_value(PropertySettings.KEY_VALIDATION)
	assert_float(rules["min"]).is_equal(0.0)
	assert_float(rules["max"]).is_equal(60.0)


func test_a_number_without_bounds_declares_none() -> void:
	# This is what tells the widget to drag freely and draw no fill bar, so an absent
	# range must stay absent rather than defaulting to 0..100.
	var count := Property.new("count").set_type("int")

	assert_bool(count.has_settings(PropertySettings.KEY_MIN_VALUE)).is_false()
	assert_bool(count.has_settings(PropertySettings.KEY_MAX_VALUE)).is_false()
	# The step still comes from the type, which is what rounds an int to whole numbers.
	assert_bool(count.get_settings_value(PropertySettings.KEY_ROUNDED)).is_true()


func test_int_and_float_differ_only_by_rounding_and_step() -> void:
	var whole := Property.new("a").set_type("int")
	var fractional := Property.new("b").set_type("float")

	assert_bool(whole.get_settings_value(PropertySettings.KEY_ROUNDED)).is_true()
	assert_bool(fractional.get_settings_value(PropertySettings.KEY_ROUNDED)).is_false()
	assert_float(whole.get_settings_value(PropertySettings.KEY_STEP)).is_equal(1.0)
	assert_float(fractional.get_settings_value(PropertySettings.KEY_STEP)).is_equal(0.1)


func test_main_property_can_be_corrected_afterwards() -> void:
	var root := Property.new("root").set_type("context").main_property().exposed(false).exported()

	assert_bool(root.is_main_property()).is_true()
	assert_bool(root.get_settings_value(PropertySettings.KEY_EXPOSED)).is_false()
	assert_bool(root.get_settings_value(PropertySettings.KEY_EXPORT)).is_true()
	# main_property() hides it from the inspector by default.
	assert_bool(root.get_settings_value(PropertySettings.KEY_VISIBLE_IN_INSPECTOR)).is_false()


func test_editable_reopens_a_main_property_for_the_inspector() -> void:
	var text := Property.new("text").set_type("text").main_property().editable()

	assert_bool(text.get_settings_value(PropertySettings.KEY_VISIBLE_IN_INSPECTOR)).is_true()
	assert_bool(text.get_settings_value(PropertySettings.KEY_EDITABLE)).is_true()


func test_header_puts_a_property_in_the_inspector_strip() -> void:
	var color := Property.new("color").set_type("color").header()

	assert_str(color.get_category()).is_equal("Special:Header")
	assert_bool(color.get_settings_value(PropertySettings.KEY_FLAT)).is_true()
	assert_bool(color.is_visible_in_graph()).is_false()


func test_a_frozen_property_refuses_further_declaration() -> void:
	var frozen := Property.new("p").set_type("text")
	frozen.freeze()

	frozen.required()
	frozen.set_type("int")

	assert_bool(frozen.get_settings_value(PropertySettings.KEY_REQUIRED, false)).is_false()
	assert_str(frozen.type).is_equal("text")


func test_a_frozen_property_still_accepts_user_overrides() -> void:
	# Freezing locks the declaration, not the user's own choices.
	var frozen := Property.new("p").set_type("text")
	frozen.freeze()

	frozen.set_settings_value(PropertySettings.KEY_EXPOSED, true)

	assert_bool(frozen.get_settings_value(PropertySettings.KEY_EXPOSED)).is_true()


func test_overrides_win_over_the_declaration_and_can_be_taken_back() -> void:
	var property := Property.new("p").set_type("text")
	assert_bool(property.get_settings_value(PropertySettings.KEY_EDITABLE)).is_true()

	property.set_settings_value(PropertySettings.KEY_EDITABLE, false)
	assert_bool(property.get_settings_value(PropertySettings.KEY_EDITABLE)).is_false()

	property.erase_settings_value(PropertySettings.KEY_EDITABLE)
	assert_bool(property.get_settings_value(PropertySettings.KEY_EDITABLE)).is_true()


func test_changing_a_setting_notifies_listeners() -> void:
	# How a bound field refreshes, now that the model holds no widget references.
	var property := Property.new("p").set_type("text")
	var monitor: Object = monitor_signals(property)

	property.set_settings_value(PropertySettings.KEY_EXPOSED, true)

	assert_signal(monitor).is_emitted("settings_changed")


func test_a_property_restores_its_value_and_its_overrides() -> void:
	var property := Property.new("line").set_type("text").plain()

	property._restore("hi", {PropertySettings.KEY_EXPOSED: true})

	assert_str(property.get_value()).is_equal("hi")
	assert_bool(property.get_settings_value(PropertySettings.KEY_EXPOSED)).is_true()


func test_an_untouched_property_has_no_overrides_to_save() -> void:
	# The owning object only writes an _editor_settings entry for properties that have
	# one, which is almost none of them.
	var property := Property.new("line").set_type("text").plain().default("hi")

	assert_dict(property._get_overrides()).is_empty()

	property.set_settings_value(PropertySettings.KEY_EXPOSED, true)

	assert_dict(property._get_overrides()).is_not_empty()
