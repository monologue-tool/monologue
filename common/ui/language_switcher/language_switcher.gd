class_name LanguageSwitcher extends OptionButton

## Current graph edit which has the loaded languages.
var graph_edit: MonologueGraphEdit
var _is_applying: bool = false


func _ready() -> void:
	item_selected.connect(_on_item_selected)
	ProjectManager.project_loaded.connect(_on_project_loaded)
	EventBus.refresh.connect(_on_global_refresh)
	EventBus.enable_language_switcher.connect(set_enabled)
	EventBus.disable_language_switcher.connect(set_enabled.bind(false))
	load_languages()


func _on_project_loaded() -> void:
	var project: MonologueProject = ProjectManager.current_project
	project.get_collection("languages").content_changed.connect(_on_languages_content_changed)
	_on_languages_content_changed()


func _on_languages_content_changed() -> void:
	var project: MonologueProject = ProjectManager.current_project
	var languages: Array = project.get_collection_value("languages")
	load_languages(languages)


func load_languages(languages: Array = []) -> void:
	clear()

	var seen_codes: PackedStringArray = []
	for i: int in languages.size():
		var lang: Dictionary = languages[i]
		var lang_code: String = lang.get("code", {}).get("value", "en")
		var lang_name: String = lang.get("name", {}).get("value", "Language %d" % (i + 1))
		if seen_codes.has(lang_code):
			continue
		seen_codes.append(lang_code)
		add_item(lang_name)
		set_item_metadata(item_count - 1, lang_code)

	var restore_idx: int = 0
	if item_count > 0:
		select(restore_idx)
		_apply_selection(restore_idx)


func select_by_locale(locale_code: String) -> void:
	for i: int in item_count:
		if get_item_metadata(i) == locale_code:
			select(i)
			_apply_selection(i)
			return


func set_enabled(active: bool = true) -> void:
	disabled = not active


func _on_item_selected(idx: int) -> void:
	_apply_selection(idx)


func _on_global_refresh() -> void:
	# Another source (e.g. TranslatableField LocalizationOption) changed the language;
	# update our selection to match without re-emitting refresh.
	if _is_applying:
		return
	var project: MonologueProject = ProjectManager.current_project
	var active: String = project.active_language_code if project else "en"
	for i: int in item_count:
		if get_item_metadata(i) == active:
			if selected != i:
				select(i)
				if graph_edit:
					graph_edit.current_language_index = i
			return


func _apply_selection(idx: int) -> void:
	if idx < 0 or idx >= item_count:
		return
	_is_applying = true
	var code: String = get_item_metadata(idx)
	var project: MonologueProject = ProjectManager.current_project
	if graph_edit:
		graph_edit.current_language_index = idx
	if project:
		project.active_language_code = code
	EventBus.refresh.emit()
	_is_applying = false
