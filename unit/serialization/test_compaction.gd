extends GdUnitTestSuite

## Making a document smaller on disk without changing a word of it.
##
## Everything here rests on one property: unpacking what was packed gives back exactly what
## went in. A failure names the path it diverged at rather than saying no, since a document
## holds thousands of values and a boolean says nothing about which one moved.

var _project: MonologueProject


func before_test() -> void:
	MonologueRegistry.reset_instance()
	_project = auto_free(MonologueProject.new())
	await _project.ready


func after_test() -> void:
	MonologueRegistry.reset_instance()


## The shipped project as one document, sections included.
func _document() -> Dictionary:
	return ProjectWriter.written_with_sections(_project, _project.storylines[0])


## The first place two documents differ, as a readable path, or "" when they are the same.
static func _first_difference(before: Variant, after: Variant, path: String = "") -> String:
	var here: String = path if not path.is_empty() else "<root>"

	if typeof(before) != typeof(after):
		return "%s: %s is a %s, came back a %s" % [
			here,
			JSON.stringify(before),
			type_string(typeof(before)),
			type_string(typeof(after)),
		]

	if before is Dictionary:
		return _first_difference_in_dict(before, after, path)
	if before is Array:
		return _first_difference_in_array(before, after, path)
	return "" if before == after else "%s: %s vs %s" % [
		here, JSON.stringify(before), JSON.stringify(after)
	]


static func _first_difference_in_dict(
	before: Dictionary, after: Dictionary, path: String
) -> String:
	for key: Variant in before:
		if not after.has(key):
			return "%s.%s went missing" % [path, key]
		var found: String = _first_difference(before[key], after[key], "%s.%s" % [path, key])
		if not found.is_empty():
			return found

	for key: Variant in after:
		if not before.has(key):
			return "%s.%s appeared from nowhere" % [path, key]
	return ""


static func _first_difference_in_array(before: Array, after: Array, path: String) -> String:
	if before.size() != after.size():
		return "%s: %d before, %d after" % [path, before.size(), after.size()]

	for index: int in before.size():
		var found: String = _first_difference(
			before[index], after[index], "%s[%d]" % [path, index]
		)
		if not found.is_empty():
			return found
	return ""


## The compactor's own contract, with nothing else in the way: what goes in comes back as the
## very same values.
func test_unpacking_what_was_packed_gives_back_what_went_in() -> void:
	var doc_before: Dictionary = _document()
	var packed: Dictionary = MonologueCompactor.pack(doc_before.duplicate(true))

	var found: String = _first_difference(doc_before, MonologueCompactor.unpack(packed))
	assert_str(found).override_failure_message(
		"Packing and unpacking changed the document at %s" % found
	).is_empty()


func test_what_the_writer_puts_on_disk_reads_back_the_same() -> void:
	var doc_before: Dictionary = _document()
	var through_json: Variant = JSON.parse_string(JSON.stringify(doc_before))

	var renderings: Dictionary = {
		"archive": ProjectWriter.compacted,
		"folder": ProjectWriter.laid_out,
	}

	for shape: String in renderings:
		var on_disk: String = (renderings[shape] as Callable).call(doc_before.duplicate(true))
		var parsed: Variant = JSON.parse_string(on_disk)

		assert_bool(parsed is Dictionary).override_failure_message(
			"The %s rendering is not valid JSON." % shape
		).is_true()

		var found: String = _first_difference(through_json, MonologueCompactor.unpack(parsed))
		assert_str(found).override_failure_message(
			"The %s rendering came back changed at %s" % [shape, found]
		).is_empty()


func test_an_archive_is_written_on_one_line_and_a_folder_is_not() -> void:
	var doc: Dictionary = _document()

	assert_str(ProjectWriter.compacted(doc)).override_failure_message(
		"The archive was indented, which costs bytes nobody reads."
	).not_contains("\n")
	assert_str(ProjectWriter.laid_out(doc)).override_failure_message(
		"The folder was written on one line, which makes it undiffable."
	).contains("\n")
