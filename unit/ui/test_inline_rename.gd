extends GdUnitTestSuite

## Renaming in place, which the project explorer offers on a double click and anything else
## with a list of named things can offer the same way.

var _row: VBoxContainer
var _button: Button


func before_test() -> void:
	_row = auto_free(VBoxContainer.new())
	add_child(_row)

	_button = Button.new()
	_button.text = "main"
	_row.add_child(_button)


## The field, found the way anything looking at the row would find it rather than by reaching
## into the helper.
func _field() -> LineEdit:
	for child: Node in _row.get_children():
		if child is LineEdit:
			return child
	return null


func test_the_field_stands_where_the_button_stood_and_gives_the_place_back() -> void:
	# Laid over the top instead, the button would go on drawing itself underneath: pressed,
	# highlighted, with its own padding, behind a field lining up with none of it.
	var rename: InlineRename = InlineRename.attach(_button)
	assert_object(_field()).is_null()

	rename.open()

	assert_object(_field()).override_failure_message(
		"Nothing to type in appeared in the row."
	).is_not_null()
	assert_int(_field().get_index()).override_failure_message(
		"The field appeared somewhere other than where the button was."
	).is_equal(0)
	assert_bool(_button.visible).is_false()
	assert_str(_field().text).is_equal("main")

	rename.cancel()

	assert_object(_field()).override_failure_message(
		"The field stayed in the row after the edit was over."
	).is_null()
	assert_bool(_button.visible).is_true()


func test_a_name_is_announced_but_never_written() -> void:
	# The helper does not know what a rename means, and whoever attached it may refuse one.
	# So the button says what it said, and only the announcement says otherwise.
	var rename: InlineRename = InlineRename.attach(_button)
	var announced: Array[String] = []
	rename.committed.connect(func(to: String) -> void: announced.append(to))

	rename.open()
	_field().text = "  prologue  "
	_field().text_submitted.emit(_field().text)

	assert_array(announced).override_failure_message(
		"The name was not announced, or was announced with the spaces around it."
	).is_equal(["prologue"])
	assert_str(_button.text).override_failure_message(
		"The helper renamed the button itself; that was never its to decide."
	).is_equal("main")


func test_nothing_is_announced_for_a_name_that_says_nothing_new() -> void:
	var rename: InlineRename = InlineRename.attach(_button)
	var announced: Array[String] = []
	rename.committed.connect(func(to: String) -> void: announced.append(to))

	# Escape puts it back, whatever was typed.
	rename.open()
	_field().text = "elsewhere"
	rename.cancel()

	# So does agreeing to the name it already had, or to no name at all.
	for typed: String in ["main", "", "   "]:
		rename.open()
		_field().text = typed
		_field().text_submitted.emit(typed)

	assert_array(announced).override_failure_message(
		"Something was announced that nobody asked for: %s" % str(announced)
	).is_empty()


func test_the_field_belongs_to_the_button_and_goes_when_it_does() -> void:
	# It spends most of its life out of the row, so without an owner it would be left behind
	# every time a list is rebuilt.
	InlineRename.attach(_button)
	assert_int(_button.get_child_count()).override_failure_message(
		"The field is parked nowhere while idle, so nothing will ever free it."
	).is_greater(0)

	_row.remove_child(_button)
	_button.free()

	assert_object(_field()).is_null()
