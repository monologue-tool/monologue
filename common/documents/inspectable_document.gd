@abstract
class_name InspectableDocument extends InspectableObject

# An alias, not a second definition: what a document is called on disk is MonologueSource's.
const FILE_FORMAT: String = MonologueSource.DOCUMENT_EXTENSION

signal content_changed
signal undo_redo_changed

var is_dirty: bool = false


func _init(command_manager: CommandManager) -> void:
	property_changed.connect(_on_property_changed)
	command_manager.command_executed.connect(_on_command_executed)
	command_manager.undone.connect(_on_undo)
	command_manager.redone.connect(_on_redo)

	super._init(command_manager)


## How this document is named in problem reports. Documents that carry a user-chosen
## name (storylines, collections) override it.
func get_document_name() -> String:
	return get_type()


func _on_property_changed(_pname: String) -> void:
	is_dirty = true
	content_changed.emit()


func _on_command_executed() -> void:
	is_dirty = true
	content_changed.emit()
	undo_redo_changed.emit()


func _on_undo() -> void:
	content_changed.emit()
	undo_redo_changed.emit()


func _on_redo() -> void:
	is_dirty = true
	content_changed.emit()
	undo_redo_changed.emit()
