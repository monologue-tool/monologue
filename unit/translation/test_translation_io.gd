extends GdUnitTestSuite

## A translation leaves the project and comes back through another tool's hands. What
## matters is that it lands where it left from, whatever happened to the rows in between:
## sorted, filtered, or half deleted.

var _project: MonologueProject
var _table: TranslationTable


func before_test() -> void:
	_project = auto_free(MonologueProject.new())
	await _project.ready
	ProjectManager.current_project = _project
	_table = TranslationTable.collect(_project)


func after_test() -> void:
	ProjectManager.current_project = null


func _path(extension: String) -> String:
	return "%s/translations.%s" % [create_temp_dir("translations"), extension]


func _first_key() -> String:
	return _table.entries[0].key


func test_every_format_brings_awkward_text_back_whole() -> void:
	# The payload differs per format because the hazards do: a CSV row cannot hold a raw
	# newline, and a PO entry has to escape the quotes it delimits with.
	var formats: Dictionary = {
		"csv": 'She said "wait, now", and left',
		"json": 'Braces {and} "quotes", together',
		"po": 'He said "no"\nand left',
	}

	for extension: String in formats:
		var key: String = _first_key()
		var awkward: String = formats[extension]
		var path: String = _path(extension)
		_table.apply(key, "en", "source")
		_table.apply(key, "fr", awkward)

		assert_bool(TranslationIO.write(_table, ["fr"], path, "en").is_valid()).is_true()
		var batch: Dictionary = TranslationIO.read(path, ValidationResult.ok())

		assert_str(str((batch["fr"] as Dictionary)[key])).override_failure_message(
			"A .%s round trip did not give the text back as it left." % extension
		).is_equal(awkward)


func test_an_import_lands_by_key_and_drops_what_has_no_home() -> void:
	var key: String = _first_key()

	# Position means nothing: only the key says which line a row belongs to.
	var batch: Dictionary = TranslationIO.from_csv_lines(
		[
			PackedStringArray(["key", "context", "en"]),
			PackedStringArray(["nonsense-key", "", "ignored"]),
			PackedStringArray([key, "", "Hello"]),
		],
		ValidationResult.ok()
	)
	assert_str(str((batch["en"] as Dictionary)[key])).is_equal("Hello")

	assert_int(_table.apply_batch({"fr": {key: "Bonjour"}})).is_equal(1)
	assert_str(_table.get_entry(key).get_text("fr")).is_equal("Bonjour")

	# Nothing in the project could hold an unknown key, so inventing a home would be worse.
	var result: ValidationResult = ValidationResult.ok()
	assert_int(_table.apply_batch({"en": {"no-such-line": "text"}}, result)).is_equal(0)
	assert_array(result.with_code(&"unknown_translation_key")).is_not_empty()


func test_a_file_that_is_not_a_translation_file_is_refused_by_name() -> void:
	var missing: ValidationResult = ValidationResult.ok()
	TranslationIO.read("res://nowhere/at/all.csv", missing)
	assert_array(missing.with_code(&"translation_import_missing")).is_not_empty()

	var keyless: ValidationResult = ValidationResult.ok()
	TranslationIO.from_csv_lines(
		[PackedStringArray(["context", "en"]), PackedStringArray(["a", "b"])], keyless
	)
	assert_array(keyless.with_code(&"translation_import_no_key")).is_not_empty()

	var languageless: ValidationResult = ValidationResult.ok()
	TranslationIO.from_po('msgctxt "a"\nmsgid "b"\nmsgstr "c"\n', languageless)
	assert_array(languageless.with_code(&"translation_import_no_language")).is_not_empty()
