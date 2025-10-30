## Indexer for context field type.
##
## Provides metadata for the context field type in the Monologue editor.
## Context fields are not directly inspectable.
extends MonologueIndexer


## Returns an empty scene as context fields are not inspectable.
func get_scene() -> PackedScene:
	# Not intended to be inspectable
	return PackedScene.new()


## Returns metadata for the context field type.
func get_metadata() -> Dictionary:
	return {"name": "context", "type": ObjectType.FIELD, "color": Color("ffffff")}
