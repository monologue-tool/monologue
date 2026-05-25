@abstract
class_name InspectableDocument extends InspectableObject

const FILE_FORMAT: String = "mnlf"

signal content_changed
signal undo_redo_changed

var is_dirty: bool = false


func _init(command_manager: CommandManager) -> void:
	property_changed.connect(_on_property_changed)
	command_manager.command_executed.connect(_on_command_executed)
	command_manager.undone.connect(_on_undo)
	command_manager.redone.connect(_on_redo)
	
	super._init(command_manager)


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
