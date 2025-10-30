@abstract
class_name Command extends RefCounted

@abstract func execute()
@abstract func undo()
@abstract func get_description() -> String
