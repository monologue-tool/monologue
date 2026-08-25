## Which language the editor is written in. One choice for the whole project, in the header.
##
## A translated value holds every language at once and shows one of them, so the choice
## belongs to the project rather than to each field that happens to display text.
class_name LanguageSwitcher extends OptionButton

## True while this switcher is the one making the change, so its own echo is ignored.
var _is_applying: bool = false


func _ready() -> void:
	item_selected.connect(_on_item_selected)
	ProjectManager.project_loaded.connect(_on_project_loaded)
	EventBus.language_changed.connect(_on_language_changed)


func _on_project_loaded() -> void:
	var languages: CollectionDocument = ProjectManager.current_project.get_collection("languages")
	if languages == null:
		Log.error("The project carries no languages, so there is nothing to switch between.")
		return

	if not languages.content_changed.is_connected(_on_languages_content_changed):
		languages.content_changed.connect(_on_languages_content_changed)
	_on_languages_content_changed()


## Fills the list and keeps the language already being read.
##
## Adding or renaming a language used to send the editor back to the first one: the list was
## rebuilt and its first entry applied, whatever was on screen.
func load_languages(languages: Array) -> void:
	clear()

	var project: MonologueProject = ProjectManager.current_project
	var reading: String = project.active_language_code if project else ""

	var seen: PackedStringArray = []
	for index: int in languages.size():
		var language: Dictionary = languages[index]
		var code: String = str(language.get("code", "en"))
		if seen.has(code):
			continue

		seen.append(code)
		add_item(str(language.get("name", "Language %d" % (index + 1))))
		set_item_metadata(item_count - 1, code)

	if item_count == 0:
		return

	var still_here: int = _index_of(reading)
	if still_here >= 0:
		select(still_here)
		return

	# What was being read is gone, so the editor has to move to something that is left.
	select(0)
	_apply_selection(0)


func _index_of(code: String) -> int:
	for index: int in item_count:
		if get_item_metadata(index) == code:
			return index
	return -1


func _on_languages_content_changed() -> void:
	load_languages(ProjectManager.current_project.get_collection_value("languages"))


func _on_item_selected(index: int) -> void:
	_apply_selection(index)


## Somebody else moved the language on. The list catches up without saying it again.
func _on_language_changed(code: String) -> void:
	if _is_applying:
		return

	var index: int = _index_of(code)
	if index >= 0 and selected != index:
		select(index)


func _apply_selection(index: int) -> void:
	if index < 0 or index >= item_count:
		return

	var code: String = str(get_item_metadata(index))
	var project: MonologueProject = ProjectManager.current_project
	if project == null or project.active_language_code == code:
		return

	_is_applying = true
	project.active_language_code = code
	EventBus.language_changed.emit(code)
	_is_applying = false
