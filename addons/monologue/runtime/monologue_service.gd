## Something a story can reach that is not the story. What a node type can do is bounded by
## what the game offers here, not by what the session exposes.
##
## Two ways in. Drop a file in a watched folder, or hand the runtime something already in your
## scene with [method MonologueRuntime.provide]. A provided object need not extend this. It
## only has to answer the calls the behaviours make on it.
@abstract class_name MonologueService extends Node

## Explicit and not derived from the file name, so renaming a file cannot break the stories
## that reach for it.
@abstract func service_name() -> String


## Called when a story starts, and before a restored save puts its state back.
func clear() -> void:
	pass


func save_state() -> Dictionary:
	return {}


func load_state(_data: Dictionary) -> void:
	pass
