class_name RecentFilesContainer extends VBoxContainer

@export var button_container: Control
@export var save_path: String = Constants.HISTORY_PATH

@onready var button_scene: PackedScene = preload("uid://dqp3uifnpuc3b")


func _ready() -> void:
	refresh()


func create_button(filepath: String) -> Button:
	var btn: Button = button_scene.instantiate()
	var path: String = filepath.replace("\\", "/")
	path = path.replace("//", "/")
	var paths: Array = path.split("/")
	var btn_text: String = ""
	btn_text = paths.back()

	btn.text = btn_text
	btn.flat = true
	btn.pressed.connect(_on_project_btn_pressed.bind(filepath))
	btn.tooltip_text = filepath
	button_container.add_child(btn)
	return btn


## Load the recent file history save and create buttons for it.
func load_history() -> void:
	var data: Array = ProjectManager.get_history()

	for path: Variant in data.slice(0, 3):
		create_button(path)


## Remake the recent file list.
func refresh() -> void:
	for child: Node in button_container.get_children():
		child.queue_free()
	
	load_history()


func _on_project_btn_pressed(path: String) -> void:
	ProjectManager.load_project_from_path(path)
	
