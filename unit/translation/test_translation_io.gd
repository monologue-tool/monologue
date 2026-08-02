# gdlint: disable=max-public-methods
extends GdUnitTestSuite

## A translation leaves the project and comes back through another tool's hands. What
## matters is that it lands where it left from, whatever happened to the rows in
## between: sorted, filtered, or half deleted.

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


# --- round trips ------------------------------------------------------------------


func test_csv_survives_the_round_trip() -> void:
	_table.apply(_first_key(), "en", "Hello")
	var path: String = _path("csv")

	assert_bool(TranslationIO.write(_table, ["en"], path).is_valid()).is_true()
	var batch: Dictionary = TranslationIO.read(path, ValidationResult.ok())

	assert_str(str((batch["en"] as Dictionary)[_first_key()])).is_equal("Hello")


func test_json_survives_the_round_trip() -> void:
	_table.apply(_first_key(), "fr", "Bonjour")
	var path: String = _path("json")

	TranslationIO.write(_table, ["fr"], path)
	var batch: Dictionary = TranslationIO.read(path, ValidationResult.ok())

	assert_str(str((batch["fr"] as Dictionary)[_first_key()])).is_equal("Bonjour")


func test_text_with_commas_and_quotes_comes_back_whole() -> void:
	# The reason to use store_csv_line rather than joining strings by hand.
	var awkward: String = 'She said "wait, now", and left'
	_table.apply(_first_key(), "en", awkward)
	var path: String = _path("csv")

	TranslationIO.write(_table, ["en"], path)
	var batch: Dictionary = TranslationIO.read(path, ValidationResult.ok())

	assert_str(str((batch["en"] as Dictionary)[_first_key()])).is_equal(awkward)


# --- what an import does with a file it did not write -----------------------------


func test_rows_are_matched_by_key_not_by_position() -> void:
	var key: String = _first_key()
	var lines: Array[PackedStringArray] = [
		PackedStringArray(["key", "context", "en"]),
		PackedStringArray(["nonsense-key", "", "ignored"]),
		PackedStringArray([key, "", "Hello"]),
	]

	var batch: Dictionary = TranslationIO.from_csv_lines(lines, ValidationResult.ok())

	assert_str(str((batch["en"] as Dictionary)[key])).is_equal("Hello")


func test_an_unknown_key_is_reported_and_dropped() -> void:
	# Nothing in the project could hold it, so inventing a home would be worse.
	var result: ValidationResult = ValidationResult.ok()

	var applied: int = _table.apply_batch({"en": {"no-such-line": "text"}}, result)

	assert_int(applied).is_equal(0)
	assert_array(result.with_code(&"unknown_translation_key")).is_not_empty()


func test_a_file_without_a_key_column_is_refused() -> void:
	var result: ValidationResult = ValidationResult.ok()

	TranslationIO.from_csv_lines(
		[PackedStringArray(["context", "en"]), PackedStringArray(["a", "b"])], result
	)

	assert_array(result.with_code(&"translation_import_no_key")).is_not_empty()


func test_a_missing_file_is_reported_rather_than_crashing() -> void:
	var result: ValidationResult = ValidationResult.ok()

	TranslationIO.read("res://nowhere/at/all.csv", result)

	assert_array(result.with_code(&"translation_import_missing")).is_not_empty()


func test_importing_writes_into_the_project() -> void:
	var key: String = _first_key()

	var applied: int = _table.apply_batch({"fr": {key: "Bonjour"}})

	assert_int(applied).is_equal(1)
	assert_str(_table.get_entry(key).get_text("fr")).is_equal("Bonjour")
