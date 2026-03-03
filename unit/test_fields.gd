extends GdUnitTestSuite


func test_create_all_fields():
	for field_name: String in FieldBucket._descriptors:
		if field_name == "context":
			continue
		
		var field: Field = auto_free(FieldBucket.create_field(field_name))
		assert_object(field).is_not_null()
