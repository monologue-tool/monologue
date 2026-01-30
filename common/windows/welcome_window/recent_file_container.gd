class_name RecentFilesContainer extends VBoxContainer

@export var button_container: Control
@export var save_path: String = Constants.HISTORY_PATH

@onready var button_scene: PackedScene = preload(
	"res://common/windows/welcome_window/recent_file_button.tscn"
)

var recent_filepaths: Array = []


func _ready() -> void:
	EventBus.load_successful.connect(add)
	refresh()


## Adds a new filepath as recent file and saves it to the history file.
func add(filepath: String) -> void:
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	if file:
		recent_filepaths.erase(filepath)
		recent_filepaths.push_front(filepath)
		file.store_string(JSON.stringify(recent_filepaths.slice(0, 10)))
		file.close()
		refresh()


func create_button(filepath: String) -> Button:
	var btn = button_scene.instantiate()
	var btn_text = filepath.replace("\\", "/")
	btn_text = btn_text.replace("//", "/")
	btn_text = btn_text.split("/")
	if btn_text.size() >= 2:
		btn_text = btn_text.slice(-2, btn_text.size())
		btn_text = btn_text[0].path_join(btn_text[1])
	else:
		btn_text = btn_text.back()

	btn.text = Util.truncate_filename(btn_text)
	btn.pressed.connect(EventBus.load_project.emit.bind(filepath))
	button_container.add_child(btn)
	return btn


## Create the recent file history save in user directory if it doesn't exist.
func create_file() -> void:
	if not FileAccess.file_exists(save_path):
		FileAccess.open(save_path, FileAccess.WRITE)


## Load the recent file history save and create buttons for it.
func load_file() -> void:
	var file = FileAccess.open(save_path, FileAccess.READ)
	if file:
		var data = parse_history(file.get_as_text())
		file.close()

		for path in data.slice(0, 3):
			recent_filepaths.append(path)
			create_button(path)


## Return only the recent files that still exist as a JSON array.
func parse_history(text: String) -> Array:
	var data = JSON.parse_string(text)
	if data is Array:
		return data.filter(func(p): return FileAccess.file_exists(p))
	return []


## Remake the recent file list.
func refresh() -> void:
	for child in button_container.get_children():
		child.queue_free()
	recent_filepaths.clear()
	create_file()
	load_file()
	show_or_hide()


## Show container if recent file buttons are present, otherwise hide it.
func show_or_hide() -> void:
	if button_container.get_child_count() > 0:
		show()
	else:
		hide()
