class_name DocumentTabManager extends PanelContainer

signal add_document

@warning_ignore("unused_private_class_variable")
var _static_container: bool = true

@onready var tab_bar: TabBar = %TabBar

var _last_opened_tab: int = 0
var _reloading_ui: bool = false


func _ready() -> void:
	StorylineManager.storyline_changed.connect(_on_storyline_changed)
	StorylineManager.storyline_created.connect(_on_storyline_created)


func _reload_ui() -> void:
	_reloading_ui = true
	tab_bar.clear_tabs()
	for document_id: String in StorylineManager.get_storyline_ids():
		var document: StorylineDocument = StorylineManager.get_storyline(document_id)

		var tab_title: String = document.name
		if document.file_path.is_empty():
			tab_title = "<%s>" % tab_title
		if document.is_dirty:
			tab_title += "*"

		tab_bar.add_tab(tab_title)
		tab_bar.set_tab_metadata(tab_bar.tab_count - 1, document_id)

	tab_bar.current_tab = _last_opened_tab

	tab_bar.add_tab("", preload("res://ui/assets/icons/plus.svg"))
	_reloading_ui = false


func _on_storyline_created() -> void:
	_reload_ui()


func _on_storyline_changed() -> void:
	_reload_ui()


func _on_tab_bar_tab_changed(tab: int) -> void:
	if tab >= tab_bar.tab_count - 1:
		tab_bar.current_tab = _last_opened_tab
		if _reloading_ui:
			return
		add_document.emit()
		return

	if tab_bar.current_tab != _last_opened_tab:
		StorylineManager.storyline_switched.emit()

	_last_opened_tab = tab_bar.current_tab
