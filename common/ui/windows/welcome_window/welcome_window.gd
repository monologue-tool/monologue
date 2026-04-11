class_name WelcomeWindow extends MonologueWindow

## Callback for loading projects after file selection.
var file_callback: Callable = func(path: String) -> void: EventBus.load_project.emit(path)

@onready var close_button: BaseButton = %CloseButton
@onready var recent_files: RecentFilesContainer = %RecentProjectsContainer
@onready var version_label: Label = %VersionLabel

var is_startup: bool = false


func _ready() -> void:
	super._ready()
	is_startup = true
	version_label.text = "v" + ProjectSettings.get("application/config/version")
	EventBus.show_welcome.connect(show)
	EventBus.hide_welcome.connect(_on_hide)
	EventBus.window_out.connect(_on_hide)


func _input(_event: InputEvent) -> void:
	if Input.is_key_pressed(KEY_ESCAPE) and not is_startup:
		hide()


func _on_hide() -> void:
	is_startup = false
	hide()


func _on_new_file_btn_pressed() -> void:
	EventBus.save_file_request.emit(load_callback, ["*.json"])


func _on_open_file_btn_pressed() -> void:
	EventBus.open_file_request.emit(load_callback, ["*.json"])


func load_callback(path: String) -> void:
	EventBus.load_project.emit(path)


func _on_github_btn_pressed() -> void:
	OS.shell_open("https://github.com/monologue-tool/monologue")


func _on_bug_report_btn_pressed() -> void:
	OS.shell_open("https://github.com/monologue-tool/monologue/issues/new?template=BUG-REPORT.yml")
