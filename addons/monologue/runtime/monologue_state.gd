## Everything about a story that changes while it plays. The graph is read-only, so this is
## the whole of a save file. What moves and is not in here, a saved game forgets.
class_name MonologueState extends RefCounted

var variables: Dictionary = {}
## character id -> item id -> how many are held. Per character, not one pile for the whole
## story.
var inventory: Dictionary = {}
## "<choice id>|<option key>" -> true, for options that only offer themselves once
var consumed_options: Dictionary = {}
var fired_events: Dictionary = {}
## node id -> how many times the story has been through it
var visited: Dictionary = {}
## Node ids to come back to when a chain runs out, innermost last. What a call pushes.
var call_stack: Array[String] = []
## Where the chain ran out, for whatever pushed the return address it is unwinding to. A call
## has one exit per place its function stops, and this says which. Read and cleared by the
## node it comes back to.
var ran_out_at: String = ""
var cursor: Dictionary = {}
## What is on screen, so a restored save rebuilds the picture without replaying. One slice
## per behaviour that puts something up, under a key of its own choosing.
var stage: Dictionary = {}
var checkpoint: String = ""
## Why the story stopped, once it has.
var ending: Dictionary = {}
var step_index: int = 0
## Kept here and not on the session, so a save replays its coin flips the same way.
var rng_seed: int = 0
## How far into that sequence the run has got. Setting a seed rewinds to the start, so a
## save carrying only the seed would draw the same numbers all over again.
var rng_state: int = 0


func visit(node_id: String) -> void:
	visited[node_id] = int(visited.get(node_id, 0)) + 1


func times_visited(node_id: String) -> int:
	return int(visited.get(node_id, 0))


func is_consumed(choice_id: String, option_key: String) -> bool:
	return consumed_options.has(_option_key(choice_id, option_key))


func consume(choice_id: String, option_key: String) -> void:
	consumed_options[_option_key(choice_id, option_key)] = true


## Zero for anyone who has never met the item.
func held(character_id: String, item_id: String) -> int:
	return int((inventory.get(character_id, {}) as Dictionary).get(item_id, 0))


func hold(character_id: String, item_id: String, quantity: int) -> void:
	var carried: Dictionary = inventory.get_or_add(character_id, {})
	carried[item_id] = maxi(quantity, 0)


func current_node() -> String:
	return str(cursor.get("node", ""))


func current_storyline() -> String:
	return str(cursor.get("storyline", ""))


func move_to(storyline_id: String, node_id: String) -> void:
	cursor = {"storyline": storyline_id, "node": node_id}


func to_dict() -> Dictionary:
	return {
		"variables": variables.duplicate(true),
		"inventory": inventory.duplicate(true),
		"consumed_options": consumed_options.duplicate(),
		"fired_events": fired_events.duplicate(),
		"visited": visited.duplicate(),
		"call_stack": call_stack.duplicate(true),
		"ran_out_at": ran_out_at,
		"checkpoint": checkpoint,
		"cursor": cursor.duplicate(),
		"stage": stage.duplicate(true),
		"ending": ending.duplicate(true),
		"step_index": step_index,
		"rng_seed": rng_seed,
		"rng_state": rng_state,
	}


static func from_dict(data: Dictionary) -> MonologueState:
	var state: MonologueState = MonologueState.new()
	state.variables = (data.get("variables", {}) as Dictionary).duplicate(true)
	state.inventory = (data.get("inventory", {}) as Dictionary).duplicate(true)
	state.consumed_options = (data.get("consumed_options", {}) as Dictionary).duplicate()
	state.fired_events = (data.get("fired_events", {}) as Dictionary).duplicate()
	state.visited = (data.get("visited", {}) as Dictionary).duplicate()
	for node_id: Variant in data.get("call_stack", []) as Array:
		state.call_stack.append(str(node_id))
	state.ran_out_at = str(data.get("ran_out_at", ""))
	state.checkpoint = str(data.get("checkpoint", ""))
	state.cursor = (data.get("cursor", {}) as Dictionary).duplicate()
	state.stage = (data.get("stage", {}) as Dictionary).duplicate(true)
	state.ending = (data.get("ending", {}) as Dictionary).duplicate(true)
	state.step_index = int(data.get("step_index", 0))
	state.rng_seed = int(data.get("rng_seed", 0))
	state.rng_state = int(data.get("rng_state", 0))
	return state


static func _option_key(choice_id: String, option_key: String) -> String:
	return "%s|%s" % [choice_id, option_key]
