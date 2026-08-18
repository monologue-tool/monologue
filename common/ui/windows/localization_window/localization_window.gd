## Every translatable line in the project, side by side across languages.
##
## A translator works down a column, not around a graph, which is the shape every other
## surface has.
##
## Rows are built by hand and not by a Tree, so the translation cell can be a real editable
## field instead of one that turns into one.
class_name LocalizationWindow extends MonologueWindow

## In the order they appear. A new one is named here and read in [method _cell_text].
const COLUMNS: Array[Dictionary] = [
	{"id": "type", "title": "Type", "stretch": 2, "shown": true},
	{"id": "property", "title": "Property", "stretch": 2, "shown": true},
	{"id": "speaker", "title": "Speaker", "stretch": 2, "shown": true},
	{"id": "storyline", "title": "Storyline", "stretch": 2, "shown": false},
	{"id": "key", "title": "Key", "stretch": 4, "shown": false},
	{"id": "source", "title": "Source Text", "stretch": 5, "shown": true},
	{"id": "target", "title": "Translation", "stretch": 5, "shown": true},
]
const TARGET_COLUMN: String = "target"
const MISSING_TEXT: String = "missing"
## Stands in for the translation column when it is showing a language against itself.
const SAME_LANGUAGE_TEXT: String = "—"

@onready var header: HBoxContainer = %Header
@onready var rows: VBoxContainer = %Rows
@onready var source_option: OptionButton = %SourceLanguage
@onready var target_option: OptionButton = %TargetLanguage
@onready var missing_only: CheckBox = %MissingOnly
@onready var coverage_label: Label = %Coverage
@onready var search_bar: LineEdit = %SearchBar

var _table: TranslationTable
var _languages: PackedStringArray = []
var _visible_columns: Dictionary[String, bool] = {}
var _sort_column: String = ""
var _sort_descending: bool = false


func _ready() -> void:
	super._ready()
	hide()
	force_native = true
	for column: Dictionary in COLUMNS:
		_visible_columns[str(column["id"])] = column["shown"]

	EventBus.open_localization.connect(open)
	source_option.item_selected.connect(_on_language_selected)
	target_option.item_selected.connect(_on_language_selected)
	missing_only.toggled.connect(_on_filter_changed)
	search_bar.text_changed.connect(_on_search_changed)


func open() -> void:
	reload()
	popup_centered()
	search_bar.grab_focus()


## Rereads the project. The only way the table can be trusted after the graph was edited
## behind it.
func reload() -> void:
	var project: MonologueProject = ProjectManager.current_project
	if project == null:
		return

	_table = TranslationTable.collect(project)
	_languages = TranslationTable.languages_of(project)
	_fill_language_options()
	rebuild()


# --- columns ------------------------------------------------------------------


func is_column_visible(column_id: String) -> bool:
	return _visible_columns.get(column_id, false)


func set_column_visible(column_id: String, shown: bool) -> void:
	# The translation is the point of the window. Hiding it would leave nothing to do.
	if column_id == TARGET_COLUMN and not shown:
		return
	_visible_columns[column_id] = shown
	rebuild()


func get_columns() -> Array[Dictionary]:
	return COLUMNS


func _shown_columns() -> Array[Dictionary]:
	var shown: Array[Dictionary] = []
	for column: Dictionary in COLUMNS:
		if is_column_visible(str(column["id"])):
			shown.append(column)
	return shown


# --- languages ----------------------------------------------------------------


func _fill_language_options() -> void:
	for option: OptionButton in [source_option, target_option]:
		var previous: String = _selected_language(option)
		option.clear()
		for language: String in _languages:
			option.add_item(language)
			option.set_item_metadata(option.item_count - 1, language)
		_select_language(option, previous)

	# A translator reads one language and writes another, so the two start apart.
	var same: bool = _selected_language(source_option) == _selected_language(target_option)
	if _languages.size() > 1 and same:
		target_option.select(1)


func get_source_language() -> String:
	return _selected_language(source_option)


func get_target_language() -> String:
	return _selected_language(target_option)


## True when the two selectors name the same language, in which case there is nothing
## to translate and the column says so rather than inviting an edit.
func is_same_language() -> bool:
	return get_source_language() == get_target_language()


func _selected_language(option: OptionButton) -> String:
	if option.selected < 0:
		return _languages[0] if not _languages.is_empty() else ""
	return str(option.get_item_metadata(option.selected))


func _select_language(option: OptionButton, language: String) -> void:
	for index: int in option.item_count:
		if option.get_item_metadata(index) == language:
			option.select(index)
			return
	if option.item_count > 0:
		option.select(0)


# --- building -----------------------------------------------------------------


func rebuild() -> void:
	if _table == null:
		return

	for child: Node in header.get_children():
		child.queue_free()
	for child: Node in rows.get_children():
		child.queue_free()

	var columns: Array[Dictionary] = _shown_columns()
	_build_header(columns)

	var listed: Array[TranslationEntry] = _filtered()
	_sort(listed)
	for index: int in listed.size():
		_build_row(listed[index], columns, index)

	_update_coverage(listed.size())


func _build_header(columns: Array[Dictionary]) -> void:
	for column: Dictionary in columns:
		var column_id: String = str(column["id"])
		var button: Button = Button.new()
		button.theme_type_variation = "PlainButton"
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.size_flags_stretch_ratio = float(column["stretch"])
		button.text = _header_text(column)
		button.tooltip_text = "Sort by %s" % column["title"]
		button.pressed.connect(_on_header_pressed.bind(column_id))
		header.add_child(button)


func _header_text(column: Dictionary) -> String:
	var text: String = str(column["title"])
	match str(column["id"]):
		"source":
			text = "%s  %s" % [text, get_source_language()]
		TARGET_COLUMN:
			text = "%s  %s" % [text, get_target_language()]
	if _sort_column == str(column["id"]):
		text += "  ▼" if _sort_descending else "  ▲"
	return text


func _build_row(entry: TranslationEntry, columns: Array[Dictionary], index: int) -> void:
	var panel: PanelContainer = PanelContainer.new()
	panel.theme_type_variation = "ListItemOddPanel" if index % 2 else "ListItemPanel"
	rows.add_child(panel)

	var line: HBoxContainer = HBoxContainer.new()
	panel.add_child(line)

	for column: Dictionary in columns:
		var column_id: String = str(column["id"])
		var cell: Control = (
			_build_target_cell(entry) if column_id == TARGET_COLUMN else _build_label(entry, column_id)
		)
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cell.size_flags_stretch_ratio = float(column["stretch"])
		line.add_child(cell)


func _build_label(entry: TranslationEntry, column_id: String) -> Control:
	var label: Label = Label.new()
	label.text = _cell_text(entry, column_id)
	label.tooltip_text = label.text
	# Only the text columns wrap. The narrow ones read better on one line.
	if column_id in ["source", "key"]:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	if column_id == "type":
		label.add_theme_color_override("font_color", _type_color(entry))
	else:
		label.add_theme_color_override("font_color", ThemeLayout.text_muted_color)
	return label


## The translation is a real field rather than a cell that becomes one, so a translator
## can tab down the column without a click between each line.
##
## Which field depends on what the property asked for: a line that was declared
## multi-line gets an editor that can hold a line break, because a LineEdit would
## swallow it and the text would come back one line shorter than it went in.
func _build_target_cell(entry: TranslationEntry) -> Control:
	if is_same_language():
		return _build_untranslatable_cell()

	var target: String = get_target_language()
	if entry.is_multiline():
		return _build_multiline_cell(entry, target)

	var field: LineEdit = LineEdit.new()
	field.text = entry.get_text(target)
	field.placeholder_text = MISSING_TEXT
	field.set_meta("key", entry.key)
	field.text_submitted.connect(_on_translation_submitted.bind(field))
	field.focus_exited.connect(_on_translation_focus_lost.bind(field))
	if not entry.has_text(target):
		field.add_theme_color_override("font_placeholder_color", ThemeLayout.fail_color)
	return field


func _build_multiline_cell(entry: TranslationEntry, target: String) -> Control:
	var field: TextEdit = TextEdit.new()
	field.text = entry.get_text(target)
	field.placeholder_text = MISSING_TEXT
	field.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	field.scroll_fit_content_height = true
	field.custom_minimum_size.y = float(entry.get_rows()) * field.get_line_height()
	field.set_meta("key", entry.key)
	# Enter inserts a line break here, so the only moment the text is done is when the
	# field is left.
	field.focus_exited.connect(_on_translation_focus_lost.bind(field))
	if not entry.has_text(target):
		field.add_theme_color_override("font_placeholder_color", ThemeLayout.fail_color)
	return field


## Reading and writing the same language is a column with nothing to do in it.
func _build_untranslatable_cell() -> Control:
	var label: Label = Label.new()
	label.text = SAME_LANGUAGE_TEXT
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", ThemeLayout.text_muted_color)
	return label


func _cell_text(entry: TranslationEntry, column_id: String) -> String:
	match column_id:
		"type":
			return Util.to_readable_name(entry.object_type)
		"property":
			return entry.property_name
		"speaker":
			return entry.speaker
		"storyline":
			return entry.document_name
		"key":
			return entry.key
		"source":
			return entry.get_text(get_source_language())
	return entry.get_text(get_target_language())


## The colour the type already has in the graph, so a row and its node read the same.
## Collections are found by asking each one what its items call themselves, never by
## guessing a plural off the type name.
static func _type_color(entry: TranslationEntry) -> Color:
	var registry: MonologueRegistry = MonologueRegistry.get_instance()

	var node_indexer: NodeIndexer = registry.get_node(entry.object_type)
	if node_indexer:
		return node_indexer.color

	for indexer: MonologueIndexer in registry.list(MonologueObjectType.COLLECTION):
		if (indexer as CollectionIndexer).get_item_type() == entry.object_type:
			return indexer.color

	return ThemeLayout.text_primary_color


# --- filtering and sorting ----------------------------------------------------


func _filtered() -> Array[TranslationEntry]:
	var query: String = search_bar.text.strip_edges()
	var target: String = get_target_language()

	var listed: Array[TranslationEntry] = []
	for entry: TranslationEntry in _table.entries:
		if missing_only.button_pressed and entry.has_text(target):
			continue
		if not query.is_empty() and not _matches(entry, query):
			continue
		listed.append(entry)
	return listed


func _matches(entry: TranslationEntry, query: String) -> bool:
	for column: Dictionary in COLUMNS:
		if _cell_text(entry, str(column["id"])).containsn(query):
			return true
	return false


func _sort(listed: Array[TranslationEntry]) -> void:
	if _sort_column.is_empty():
		return
	listed.sort_custom(_compare)


func _compare(a: TranslationEntry, b: TranslationEntry) -> bool:
	var left: String = _cell_text(a, _sort_column)
	var right: String = _cell_text(b, _sort_column)
	if _sort_descending:
		return left.naturalnocasecmp_to(right) > 0
	return left.naturalnocasecmp_to(right) < 0


## Clicking the column already sorted on turns the order around, which is what every
## table does and what nobody reads a tooltip to find out.
func _on_header_pressed(column_id: String) -> void:
	if _sort_column == column_id:
		_sort_descending = not _sort_descending
	else:
		_sort_column = column_id
		_sort_descending = false
	rebuild()


func _update_coverage(shown: int) -> void:
	var target: String = get_target_language()
	if is_same_language():
		coverage_label.text = (
			"Reading and writing %s — pick a different language to translate into" % target
		)
		return

	coverage_label.text = "%d of %d lines translated into %s — showing %d" % [
		_table.entries.size() - _table.missing(target).size(),
		_table.entries.size(),
		target,
		shown,
	]


# --- editing ------------------------------------------------------------------


func _on_translation_submitted(_text: String, field: Control) -> void:
	_commit(field)


func _on_translation_focus_lost(field: Control) -> void:
	if field.is_inside_tree():
		_commit(field)


func _commit(field: Control) -> void:
	if _table == null or not field.has_meta("key"):
		return
	if _table.apply(str(field.get_meta("key")), get_target_language(), field.text):
		field.remove_theme_color_override("font_placeholder_color")
		_update_coverage(rows.get_child_count())


func _on_language_selected(_index: int) -> void:
	rebuild()


func _on_filter_changed(_pressed: bool) -> void:
	rebuild()


func _on_search_changed(_text: String) -> void:
	rebuild()


# --- import and export --------------------------------------------------------


func import_translations() -> void:
	var filters: PackedStringArray = []
	for format: Variant in TranslationIO.FILTERS:
		filters.append(str(TranslationIO.FILTERS[format]))
	EventBus.open_file_request.emit(_import_from, filters, "", [])


func export_translations(format: TranslationIO.Format) -> void:
	EventBus.save_file_request.emit(
		_export_to.bind(format), [str(TranslationIO.FILTERS[format])], "", []
	)


## Portable Object holds one language against a source. The other two carry every
## language the project declares.
func _export_to(path: String, format: TranslationIO.Format) -> void:
	var languages: PackedStringArray = _languages
	if format == TranslationIO.Format.PO:
		languages = PackedStringArray([get_target_language()])

	var result: ValidationResult = TranslationIO.write(
		_table, languages, path, get_source_language()
	)
	if not result.is_valid():
		for issue: ValidationIssue in result.errors():
			Log.error(str(issue))
		return
	Log.info("Exported %d lines to '%s'." % [_table.entries.size(), path])


## Import never invents rows: a key the project does not have is reported and dropped,
## because there would be nowhere to put its text.
func _import_from(path: String) -> void:
	var result: ValidationResult = ValidationResult.ok()
	var batch: Dictionary = TranslationIO.read(path, result)
	var applied: int = _table.apply_batch(batch, result)

	for issue: ValidationIssue in result.issues:
		if issue.is_error():
			Log.error(str(issue))
		else:
			Log.warn(str(issue))

	Log.info("Imported %d line(s) from '%s'." % [applied, path])
	reload()


func _on_close_requested() -> void:
	hide()
