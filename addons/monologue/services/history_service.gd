## Everything the story has said, in order, for a backlog screen.
##
## Also the shortest example of a service: a behaviour records into it, the game reads it,
## and it rides along in a save without the runtime knowing what it holds.
extends MonologueService

## A very long playthrough would otherwise grow a save file without bound.
const MAX_ENTRIES: int = 500

var entries: Array[Dictionary] = []


func service_name() -> String:
	return "history"


func record(line: String, speaker: String = "", node_id: String = "") -> void:
	entries.append({"speaker": speaker, "line": line, "node": node_id})
	if entries.size() > MAX_ENTRIES:
		entries = entries.slice(entries.size() - MAX_ENTRIES)


func last(count: int = 1) -> Array[Dictionary]:
	return entries.slice(maxi(0, entries.size() - count))


func clear() -> void:
	entries.clear()


func save_state() -> Dictionary:
	return {"entries": entries.duplicate(true)}


func load_state(data: Dictionary) -> void:
	entries.clear()
	for entry: Variant in data.get("entries", []) as Array:
		if entry is Dictionary:
			entries.append(entry)
