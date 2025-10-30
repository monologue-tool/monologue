## Indexer for text field type.
##
## Provides the scene and metadata for text field editor properties.
extends MonologueIndexer


## Returns the scene for text field editors.
func get_scene() -> PackedScene:
	return preload("uid://be0xxn5gocqjo")


## Returns metadata for the text field type.
func get_metadata() -> Dictionary:
	return {"name": "text", "type": ObjectType.FIELD, "color": Color("af85fdff")}
