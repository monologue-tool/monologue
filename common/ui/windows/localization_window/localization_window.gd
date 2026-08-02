## Every translatable line in the project, side by side across languages.
##
## The editor's other surfaces show one object at a time, which is the wrong shape for
## translating: a translator works down a column, not around a graph. This shows the
## column.
class_name LocalizationWindow extends MonologueWindow

const KEY_COLUMN: int = 0
const SOURCE_COLUMN: int = 1
const TARGET_COLUMN: int = 2

const EXPORT_FILTERS: PackedStringArray = [
	"*.csv;Comma-separated values", "*.json;JSON"
]

@onready var tree: Tree = %Tree
@onready var source_option: OptionButton = %SourceLanguage
@onready var target_option: OptionButton = %TargetLanguage
@onready var missing_only: CheckBox = %MissingOnly
@onready var coverage_label: Label = %Coverage
@onready var search_bar: LineEdit = %SearchBar

var _table: TranslationTable
var _languages: PackedStringArray = []


func _ready() -> void:
	super._ready()
	hide()
	force_native = true
	EventBus.open_localization.connect(open)
	tree.item_edited.connect(_on_item_edited)
	source_option.item_selected.connect(_on_language_selected)
	target_option.item_selected.connect(_on_language_selected)
	missing_only.toggled.connect(_on_filter_changed)
	search_bar.text_changed.connect(_on_search_changed)


func open() -> void:
	reload()
	popup()
	move_to_center()
	search_bar.grab_focus()


## Rereads the project. Cheap enough to do on every open, and that is the only way the
## table can be trusted after the graph has been edited behind it.
func reload() -> void:
	var project: MonologueProject = ProjectManager.current_project
	if project == null:
		return

	_table = TranslationTable.collect(project)
	_languages = TranslationTable.languages_of(project)
	_fill_language_options()
	_rebuild_rows()


func _fill_language_options() -> void:
	for option: OptionButton in [source_option, target_option]:
		var previous: String = _selected_language(option)
		option.clear()
		for language: String in _languages:
			option.add_item(language)
			option.set_item_metadata(option.item_count - 1, language)
		_select_language(option, previous)

	# A translator reads one language and writes another, so the two start apart.
	if _languages.size() > 1 and _selected_language(source_option) == _selected_language(
		target_option
	):
		target_option.select(1)


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


# --- rows ---------------------------------------------------------------------


func _rebuild_rows() -> void:
	tree.clear()
	if _table == null:
		return

	var source: String = _selected_language(source_option)
	var target: String = _selected_language(target_option)
	var query: String = search_bar.text.strip_edges()

	tree.set_column_title(KEY_COLUMN, "Line")
	tree.set_column_title(SOURCE_COLUMN, source)
	tree.set_column_title(TARGET_COLUMN, target)

	var root: TreeItem = tree.create_item()
	var shown: int = 0
	for entry: TranslationEntry in _table.entries:
		if missing_only.button_pressed and entry.has_text(target):
			continue
		if not query.is_empty() and not _matches(entry, query, source, target):
			continue
		_create_row(root, entry, source, target)
		shown += 1

	_update_coverage(target, shown)


func _create_row(
	root: TreeItem, entry: TranslationEntry, source: String, target: String
) -> void:
	var item: TreeItem = tree.create_item(root)
	item.set_text(KEY_COLUMN, entry.context)
	item.set_tooltip_text(KEY_COLUMN, "%s · %s" % [entry.document_name, entry.key])
	item.set_custom_color(KEY_COLUMN, ThemeLayout.text_muted_color)

	item.set_text(SOURCE_COLUMN, entry.get_text(source))
	item.set_selectable(SOURCE_COLUMN, false)
	item.set_custom_color(SOURCE_COLUMN, ThemeLayout.text_muted_color)

	item.set_text(TARGET_COLUMN, entry.get_text(target))
	item.set_editable(TARGET_COLUMN, true)
	if not entry.has_text(target):
		item.set_custom_color(TARGET_COLUMN, ThemeLayout.fail_color)

	item.set_metadata(KEY_COLUMN, entry.key)


static func _matches(
	entry: TranslationEntry, query: String, source: String, target: String
) -> bool:
	for candidate: String in [
		entry.context, entry.key, entry.get_text(source), entry.get_text(target)
	]:
		if candidate.containsn(query):
			return true
	return false


func _update_coverage(target: String, shown: int) -> void:
	if _table == null:
		return
	coverage_label.text = "%d of %d lines translated into %s — showing %d" % [
		_table.entries.size() - _table.missing(target).size(),
		_table.entries.size(),
		target,
		shown,
	]


# --- editing ------------------------------------------------------------------


func _on_item_edited() -> void:
	var item: TreeItem = tree.get_edited()
	if item == null or _table == null:
		return

	var key: String = str(item.get_metadata(KEY_COLUMN))
	var target: String = _selected_language(target_option)
	if _table.apply(key, target, item.get_text(TARGET_COLUMN)):
		item.clear_custom_color(TARGET_COLUMN)
		_update_coverage(target, tree.get_root().get_child_count())


func _on_language_selected(_index: int) -> void:
	_rebuild_rows()


func _on_filter_changed(_pressed: bool) -> void:
	_rebuild_rows()


func _on_search_changed(_text: String) -> void:
	_rebuild_rows()


# --- import and export --------------------------------------------------------


func _on_export_pressed() -> void:
	EventBus.save_file_request.emit(_export_to, EXPORT_FILTERS, "", [])


func _export_to(path: String) -> void:
	var result: ValidationResult = TranslationIO.write(_table, _languages, path)
	if result.is_valid():
		Log.info("Exported %d lines to '%s'." % [_table.entries.size(), path])
		return
	for issue: ValidationIssue in result.errors():
		Log.error(str(issue))


func _on_import_pressed() -> void:
	EventBus.open_file_request.emit(_import_from, EXPORT_FILTERS, "", [])


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
