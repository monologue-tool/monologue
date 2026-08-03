## Carries translations in and out of the project, in formats other tools read.
##
## CSV is the one to hand a translator with a spreadsheet, JSON the one to hand a
## program, and Portable Object the one Poedit and Weblate speak.
##
## All three round-trip through the key on each entry, never through row order or line
## numbers, so a translator may sort, filter or delete rows without the import landing
## the text in the wrong place.
class_name TranslationIO

const KEY_COLUMN: String = "key"
const CONTEXT_COLUMN: String = "context"

enum Format { CSV, JSON, PO }

const EXTENSIONS: Dictionary = {Format.CSV: "csv", Format.JSON: "json", Format.PO: "po"}
const FILTERS: Dictionary = {
	Format.CSV: "*.csv;Comma-separated values",
	Format.JSON: "*.json;JSON",
	Format.PO: "*.po;Portable Object",
}


static func format_for_path(path: String) -> Format:
	match path.get_extension().to_lower():
		"json":
			return Format.JSON
		"po":
			return Format.PO
	return Format.CSV


## Writes [param languages] out. Portable Object carries one language against a source,
## so it takes the first of [param languages] as its target and [param source_language]
## as the text being translated from.
static func write(
	table: TranslationTable,
	languages: PackedStringArray,
	path: String,
	source_language: String = ""
) -> ValidationResult:
	var result: ValidationResult = ValidationResult.ok()
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		result.add_error("Could not write to '%s'." % path, &"translation_export_failed")
		return result

	match format_for_path(path):
		Format.JSON:
			file.store_string(JSON.stringify(to_json(table, languages), "\t"))
		Format.PO:
			if languages.is_empty():
				result.add_error(
					"A Portable Object file needs a language to write.",
					&"translation_export_no_language"
				)
			else:
				file.store_string(to_po(table, source_language, languages[0]))
		_:
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

	var format: Format = format_for_path(path)

	if format == Format.PO:
		var po_text: String = file.get_as_text()
		file.close()
		return from_po(po_text, result)

	if format == Format.JSON:
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


# --- Portable Object --------------------------------------------------------------


## The key goes in msgctxt rather than msgid: msgid holds the source text, and two
## different lines are perfectly entitled to read the same.
static func to_po(
	table: TranslationTable, source_language: String, target_language: String
) -> String:
	var lines: PackedStringArray = [
		'msgid ""',
		'msgstr ""',
		'"Content-Type: text/plain; charset=UTF-8' + _ESCAPED_NEWLINE + '"',
		'"Language: %s%s"' % [target_language, _ESCAPED_NEWLINE],
		"",
	]

	for entry: TranslationEntry in table.entries:
		if not entry.context.is_empty():
			lines.append("#. %s" % entry.context)
		lines.append("msgctxt %s" % _quote(entry.key))
		lines.append("msgid %s" % _quote(entry.get_text(source_language)))
		lines.append("msgstr %s" % _quote(entry.get_text(target_language)))
		lines.append("")

	return "\n".join(lines)


## Reads a .po back. The language comes from the header, since nothing else in the file
## says which one the translations are in.
static func from_po(text: String, result: ValidationResult) -> Dictionary:
	var language: String = ""
	var by_key: Dictionary = {}
	var context: String = ""
	var target: String = ""
	var in_target: bool = false

	for raw_line: String in text.split("\n"):
		var line: String = raw_line.strip_edges()

		if line.begins_with('"Language:'):
			language = _unquote(line).trim_prefix("Language:").strip_edges()
			continue

		if line.begins_with("msgctxt "):
			context = _unquote(line.trim_prefix("msgctxt "))
			in_target = false
		elif line.begins_with("msgstr "):
			target = _unquote(line.trim_prefix("msgstr "))
			in_target = true
		elif line.begins_with("msgid "):
			in_target = false
		elif in_target and line.begins_with('"'):
			# A long entry is wrapped over several quoted lines, all of them ours.
			target += _unquote(line)
		elif line.is_empty():
			if not context.is_empty():
				by_key[context] = target
			context = ""
			target = ""
			in_target = false

	if not context.is_empty():
		by_key[context] = target

	if language.is_empty():
		result.add_error(
			"This file does not say what language it is in.",
			&"translation_import_no_language"
		)
		return {}

	return {language: by_key}


const _ESCAPED_NEWLINE: String = "\\n"
const _ESCAPED_QUOTE: String = "\\\""
const _ESCAPED_BACKSLASH: String = "\\\\"


static func _quote(text: String) -> String:
	var escaped: String = text.replace("\\", _ESCAPED_BACKSLASH)
	escaped = escaped.replace('"', _ESCAPED_QUOTE)
	return '"%s"' % escaped.replace("\n", _ESCAPED_NEWLINE)


static func _unquote(text: String) -> String:
	var body: String = text.strip_edges()
	if body.length() >= 2 and body.begins_with('"') and body.ends_with('"'):
		body = body.substr(1, body.length() - 2)
	body = body.replace(_ESCAPED_QUOTE, '"')
	body = body.replace(_ESCAPED_NEWLINE, "\n")
	return body.replace(_ESCAPED_BACKSLASH, "\\")
