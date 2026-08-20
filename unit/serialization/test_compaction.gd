extends GdUnitTestSuite

## Making a document smaller on disk without changing a word of it.
##
## Everything here rests on one property: unpacking what was packed gives back exactly what
## went in. A document is compared as text rather than with ==, so a difference anywhere in
## the tree shows up rather than being swallowed by a shallow comparison.

var _project: MonologueProject


func before_test() -> void:
	MonologueRegistry.reset_instance()
	_project = auto_free(MonologueProject.new())
	await _project.ready


func after_test() -> void:
	MonologueRegistry.reset_instance()


func _as_text(value: Variant) -> String:
	return JSON.stringify(value, "\t")


## The shipped project as one document, sections included.
func _document() -> Dictionary:
	return ProjectWriter.written_with_sections(_project, _project.storylines[0])


func test_unpacking_what_was_packed_gives_back_what_went_in() -> void:
	var doc_before: Dictionary = _document()
	var packed: Dictionary = MonologueCompactor.pack(doc_before.duplicate(true))

	assert_str(_as_text(MonologueCompactor.unpack(packed))).override_failure_message(
		"A document did not survive being shortened and put back."
	).is_equal(_as_text(doc_before))


func test_what_the_writer_puts_on_disk_reads_back_the_same() -> void:
	var doc_before: Dictionary = _document()
	var on_disk: String = ProjectWriter.written(doc_before.duplicate(true))

	var parsed: Variant = JSON.parse_string(on_disk)
	assert_object(parsed).override_failure_message(
		"What the writer produced is not valid JSON."
	).is_not_null()

	assert_str(_as_text(MonologueCompactor.unpack(parsed))).override_failure_message(
		"What came off disk is not what went on it."
	).is_equal(_as_text(doc_before))
