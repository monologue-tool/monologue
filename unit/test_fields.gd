extends GdUnitTestSuite


func test_create_all_fields() -> void:
	for field_name: String in FieldBucket._descriptors:
		var field: Variant = auto_free(FieldBucket.safe_create_field(field_name))
		assert_object(field).is_not_null()
