## Carries translations in and out of the project, in formats other tools read.
##
## CSV is the one to hand a translator: every spreadsheet opens it, and Godot's own
## importer reads the same shape. JSON is the one to hand a program.
##
## Both round-trip through the key on each row, never through row order or line
## numbers, so a translator may sort, filter or delete rows without the import landing
## the text in the wrong place.
class_name TranslationIO

const KEY_COLUMN: String = "key"
const CONTEXT_COLUMN: String = "context"

enum Format { CSV, JSON }

const EXTENSIONS: Dictionary = {Format.CSV: "csv", Format.JSON: "json"}


static func format_for_path(path: String) -> Format:
	return Format.JSON if path.get_extension().to_lower() == "json" else Format.CSV


static func write(
	table: TranslationTable, languages: PackedStringArray, path: String
) -> ValidationResult:
	var result: ValidationResult = ValidationResult.ok()
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		result.add_error(
			"Could not write to '%s'." % path, &"translation_export_failed"
		)
		return result

	if format_for_path(path) == Format.JSON:
		file.store_string(JSON.stringify(to_json(table, languages), "\t"))
	else:
		for line: PackedStringArray in to_csv_lines(table, languages):
			file.store_csv_line(line)
	file.close()
	return result


## Reads a file into {language: {key: text}}. Records what it could not make sense of
## rather than raising: a half-readable file still delivers the half that reads.
static func read(path: String, result: ValidationResult) -> Dictionary:
	if not FileAccess.file_exists(path):
		result.add_error("There is no file at '%s'." % path, &"translation_import_missing")
		return {}

	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		result.add_error("Could not read '%s'." % path, &"translation_import_failed")
		return {}

	if format_for_path(path) == Format.JSON:
		var parsed: Variant = JSON.parse_string(file.get_as_text())
		file.close()
		if parsed is not Dictionary:
			result.add_error(
				"'%s' does not contain a translation object." % path.get_file(),
				&"translation_import_shape"
			)
			return {}
		return _normalise(parsed, result)

	var lines: Array[PackedStringArray] = []
	while not file.eof_reached():
		var line: PackedStringArray = file.get_csv_line()
		if line.size() > 1 or (line.size() == 1 and not line[0].is_empty()):
			lines.append(line)
	file.close()
	return from_csv_lines(lines, result)


# --- CSV --------------------------------------------------------------------------


static func to_csv_lines(
	table: TranslationTable, languages: PackedStringArray
) -> Array[PackedStringArray]:
	var header: PackedStringArray = [KEY_COLUMN, CONTEXT_COLUMN]
	header.append_array(languages)

	var lines: Array[PackedStringArray] = [header]
	for entry: TranslationEntry in table.entries:
		var row: PackedStringArray = [entry.key, entry.context]
		for language: String in languages:
			row.append(entry.get_text(language))
		lines.append(row)
	return lines


static func from_csv_lines(
	lines: Array[PackedStringArray], result: ValidationResult
) -> Dictionary:
	if lines.size() < 2:
		result.add_warning("The file has no rows to import.", &"translation_import_empty")
		return {}

	var header: PackedStringArray = lines[0]
	var key_column: int = header.find(KEY_COLUMN)
	if key_column == -1:
		result.add_error(
			"The first row must name a '%s' column." % KEY_COLUMN,
			&"translation_import_no_key"
		)
		return {}

	var batch: Dictionary = {}
	for index: int in range(1, lines.size()):
		var row: PackedStringArray = lines[index]
		if key_column >= row.size():
			continue
		var key: String = row[key_column].strip_edges()
		if key.is_empty():
			continue

		for column: int in range(header.size()):
			var language: String = header[column].strip_edges()
			if column == key_column or language == CONTEXT_COLUMN or language.is_empty():
				continue
			if column >= row.size():
				continue
			(batch.get_or_add(language, {}) as Dictionary)[key] = row[column]

	return batch


# --- JSON -------------------------------------------------------------------------


## {language: {key: text}} -- the shape most translation tools expect, and the one that
## diffs cleanly when only one language moves.
static func to_json(table: TranslationTable, languages: PackedStringArray) -> Dictionary:
	var out: Dictionary = {}
	for language: String in languages:
		var by_key: Dictionary = {}
		for entry: TranslationEntry in table.entries:
			by_key[entry.key] = entry.get_text(language)
		out[language] = by_key
	return out


static func _normalise(parsed: Dictionary, result: ValidationResult) -> Dictionary:
	var batch: Dictionary = {}
	for language: Variant in parsed:
		if parsed[language] is not Dictionary:
			result.add_warning(
				"'%s' does not hold a set of translations; it was skipped." % str(language),
				&"translation_import_shape"
			)
			continue
		var by_key: Dictionary = {}
		for key: Variant in parsed[language]:
			by_key[str(key)] = str(parsed[language][key])
		batch[str(language)] = by_key
	return batch
