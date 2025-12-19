extends GdUnitTestSuite


func test_list_field_exists():
	var descriptor = FieldBucket.get_descriptor("list")
	assert_object(descriptor).is_not_null()
	assert_str(descriptor.name).is_equal("list")


func test_list_field_can_be_created():
	var field = FieldBucket.create_field("list")
	assert_object(field).is_not_null()


func test_list_field_handles_empty_array():
	var field = auto_free(FieldBucket.create_field("list"))
	field.set_value([])
	var result = field.get_value()
	assert_array(result).is_empty()


func test_list_field_handles_array_with_items():
	var field = auto_free(FieldBucket.create_field("list"))
	var test_data = [
		{"name": "Item 1", "value": "A"},
		{"name": "Item 2", "value": "B"}
	]
	field.set_value(test_data)
	var result = field.get_value()
	assert_array(result).has_size(2)
