## What one type of node does when the story reaches it, and what every other type may do
## meanwhile.
##
## The indexer keeps one live node per behaviour for the whole run, so anything to remember
## between two calls is just a field.
@abstract class_name MonologueBehaviour extends Node

## Whether or not the process function should be called.
@export var active_process: bool : get = need_active_process


func _ready() -> void:
	# Let the MonologueSession handle the process.
	process_mode = Node.PROCESS_MODE_DISABLED


## The node types this behaviour runs. Empty for an observer, which runs none.
@abstract func handles() -> PackedStringArray


func need_active_process() -> bool:
	return false


## Called on every behaviour when a run starts or a save is restored, before any node plays.
## The context points at no node yet.
func setup(_ctx: MonologueContext) -> void:
	pass


## The story has arrived at a node of this type. Answer where it goes next, or
## [method BehaviourResult.wait] to hold it here and be ticked through [method process].
##
## Never [code]await[/code] in here. A function that awaits returns a coroutine instead of an
## answer. Start the awaiting in a method of your own, call it without awaiting, and read
## whatever field it sets on a later tick.
@abstract func run(ctx: MonologueContext) -> BehaviourResult


## The game answered what this node asked for. Read the answer off the player, from
## [member MonologuePlayer.picked] or [member MonologuePlayer.answer], and say where the story
## goes. A node that talks to somebody shows in run() and leaves in here.
func input(_ctx: MonologueContext) -> BehaviourResult:
	return BehaviourResult.wait()


## Once a frame, on whichever behaviour holds the story, and on every behaviour whose
## [method need_active_process] says so. For what passes on its own, like a countdown.
func process(_ctx: MonologueContext, _delta: float) -> BehaviourResult:
	return BehaviourResult.wait()


## Every behaviour hears about every node just before it plays, this one included. Answering
## anything but wait sends the story elsewhere instead.
func step(_ctx: MonologueContext) -> BehaviourResult:
	return BehaviourResult.wait()
