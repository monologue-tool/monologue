@warning_ignore_start("int_as_enum_without_match", "int_as_enum_without_cast")
extends EditorMenuButton

var recent_ids: Dictionary = {}

func _build_menu() -> void:
	recent_ids = {}
	
	add_row("New", _on_new, true, ["mnl_new"])
	add_row("Open...", _on_open, true, ["mnl_open"])
	
	var recent_files: PackedStringArray = ProjectManager.get_history()
	var recent_menu: PopupMenu = add_submenu_row("Open Recent", _on_open_recent, recent_files.size() > 0)
	for file: String in recent_files:
		var id: int = recent_menu.item_count
		recent_ids[id] = file
		recent_menu.add_item(file.get_file(), id)
	add_separator()
	
	add_row("Save", _on_save, true, ["mnl_save"])
	add_row("Save As...", _on_save_as, false, ["mnl_save_as"])
	#add_row("Save Copy...")
	#add_row("Save Version")
	add_separator()
	add_row("Quit", _on_quit, true, ["mnl_exit"])


func _on_new() -> void:
	var new_project: MonologueProject = MonologueProject.new()
	ProjectManager.load_project(new_project)


func _on_open() -> void:
	EventBus.open_file_request.emit(_on_open_dialog_callback, MonologueProject.FORMAT_FILTER)


func _on_open_dialog_callback(path: String) -> void:
	ProjectManager.load_project_from_path(path)


func _on_open_recent(_file: String) -> void:
	pass


func _on_save() -> void:
	ProjectManager.save_project(ProjectManager.current_project)


func _on_save_as() -> void:
	pass


func _on_quit() -> void:
	if await ProjectManager.close_current_project():
		get_tree().quit()
