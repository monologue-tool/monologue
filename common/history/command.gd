@abstract
class_name Command extends RefCounted

@abstract func execute() -> void
@abstract func undo() -> void
@abstract func get_description() -> String
