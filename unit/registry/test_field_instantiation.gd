extends GdUnitTestSuite

## Replaces the old unit/test_fields.gd, whose assertion could not fail: it checked that
## safe_create_field() was non-null against a function designed to always return a Control
## (a warning Label on failure). These assert the real property instead.

var _registry: MonologueRegistry


func before_test() -> void:
	MonologueRegistry.reset_instance()
	_registry = MonologueRegistry.get_instance()


func after_test() -> void:
	MonologueRegistry.reset_instance()


func test_a_field_type_produces_a_widget_exactly_when_it_is_meant_to() -> void:
	for indexer: MonologueIndexer in _registry.list(MonologueObjectType.FIELD):
		var field_indexer: FieldIndexer = indexer
		var widget: Variant = FieldWidgetFactory.create(field_indexer.name)

		if field_indexer.is_port_only:
			assert_object(widget).override_failure_message(
				"Port-only type '%s' produced a widget." % field_indexer.name
			).is_null()
			continue

		assert_object(auto_free(widget)).override_failure_message(
			"Field type '%s' did not instantiate a Field." % field_indexer.name
		).is_instanceof(Field)

	# A type nobody registered still has to draw something, or the inspector goes blank.
	var placeholder: Control = auto_free(FieldWidgetFactory.create_or_placeholder("nope"))
	assert_object(placeholder).is_not_null()
	assert_object(placeholder).is_not_instanceof(Field)


func test_widgets_do_not_share_their_settings_dictionary() -> void:
	# field.settings used to be assigned by reference from the type defaults, so one widget
	# mutating it corrupted every other instance of that type.
	var first: Field = auto_free(FieldWidgetFactory.create("textarea"))
	var second: Field = auto_free(FieldWidgetFactory.create("textarea"))

	first.settings[PropertySettings.KEY_ROWS] = 99

	assert_int(second.settings[PropertySettings.KEY_ROWS]).is_equal(3)
	assert_int(
		_registry.get_field("textarea").default_settings[PropertySettings.KEY_ROWS]
	).is_equal(3)
