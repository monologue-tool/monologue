extends Node

signal theme_changed

var current_configuration: ConfigurationDocument
var command_manager: CommandManager = CommandManager.new()


func _ready() -> void:
	load_configuration()

	sync_theme()
	sync_fonts()


func load_configuration() -> ConfigurationDocument:
	_ensure_configuration()

	var file: FileAccess = FileAccess.open(Constants.PREFERENCES_PATH, FileAccess.READ)
	var content: String = file.get_as_text()
	file.close()

	current_configuration = ConfigurationDocument.new(command_manager)

	# A corrupt preferences file used to crash the editor on startup: the parse result
	# was assigned straight into a Dictionary. Now it falls back to the defaults and
	# says so, which is recoverable. The next save rewrites the file.
	var result: ValidationResult = ValidationResult.ok()
	var data: Dictionary = ProjectReader.parse_object(
		content, Constants.PREFERENCES_PATH.get_file(), result
	)
	if not result.is_valid():
		Log.warn("Preferences could not be read; falling back to the defaults.")
	else:
		current_configuration._from_dict(data)

	return current_configuration


func save_configuration() -> void:
	var file: FileAccess = FileAccess.open(Constants.PREFERENCES_PATH, FileAccess.WRITE)
	var data: Dictionary = current_configuration._to_dict()
	var content: String = JSON.stringify(data, "\t")
	file.store_string(content)
	file.close()


func _ensure_configuration() -> void:
	if not FileAccess.file_exists(Constants.PREFERENCES_PATH):
		current_configuration = ConfigurationDocument.new(command_manager)
		save_configuration()


func get_config(property_name: String, default: Variant = null) -> Variant:
	if not current_configuration:
		Log.error("Attempting to retrieve a configuration value without a configuration document.")
		return

	var property: Property = current_configuration.get_property(property_name)
	return property.get_value() if property != null else default


func set_config(property_name: String, value: Variant) -> void:
	if not current_configuration:
		Log.error("Attempting to update a configuration property without a configuration document.")
		return

	current_configuration.set_property_value(property_name, value)


func sync_theme() -> void:
	ThemeLayout.generate_and_apply_theme()
	theme_changed.emit()


func sync_fonts() -> void:
	#ThemeLayout.rebuild_fonts()
	pass
