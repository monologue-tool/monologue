## Abstract base class for indexing Monologue objects.
##
## Provides a common interface for registering and retrieving metadata
## about different types of objects (nodes, fields, etc.) in Monologue.
@abstract class_name MonologueIndexer

## Enumeration of object types that can be indexed.
enum ObjectType { NODE, FIELD }

## Returns the scene resource associated with this indexer.
##
## Must be implemented by subclasses.
@abstract func get_scene() -> PackedScene

## Returns metadata about this indexed object.
##
## Must return a dictionary with "name" and "type" keys where type is an ObjectType enum value.
## [br][br]
## Example: {"name": "MyNode", "type": ObjectType.NODE}
@abstract func get_metadata() -> Dictionary
