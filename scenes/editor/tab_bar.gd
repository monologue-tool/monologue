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
	StorylineManager.storyline_switched.connect(_on_storyline_switched)


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


func _on_storyline_switched() -> void:
	_reload_ui()


func _on_tab_bar_tab_changed(tab: int) -> void:
	if _reloading_ui:
		return

	if tab >= tab_bar.tab_count - 1:
		tab_bar.current_tab = _last_opened_tab
		add_document.emit()
		return

	_last_opened_tab = tab
	var doc_id: String = tab_bar.get_tab_metadata(tab)
	StorylineManager.set_active_storyline(doc_id)
