## What a behaviour answers when the session asks it anything.
class_name BehaviourResult extends RefCounted

enum Kind {
	WAIT,  ## Nothing from me. From run() and process() it means "I am not done".
	PROGRESS,  ## The story moves to node. An empty node is a chain that ran out.
	STOP,  ## The story is over.
}

var kind: Kind = Kind.WAIT
var node: String = ""


static func wait() -> BehaviourResult:
	return BehaviourResult.new()


static func progress(node_id: String) -> BehaviourResult:
	var result: BehaviourResult = BehaviourResult.new()
	result.kind = Kind.PROGRESS
	result.node = node_id
	return result


static func stop() -> BehaviourResult:
	var result: BehaviourResult = BehaviourResult.new()
	result.kind = Kind.STOP
	return result


func is_waiting() -> bool:
	return kind == Kind.WAIT


func is_stop() -> bool:
	return kind == Kind.STOP
