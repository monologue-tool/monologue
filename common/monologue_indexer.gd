@abstract class_name MonologueIndexer

enum ObjectType { NODE, FIELD }

@abstract func get_scene() -> PackedScene

# {"name": "<name>", "type": "<ObjectType>"}
@abstract func get_metadata() -> Dictionary
