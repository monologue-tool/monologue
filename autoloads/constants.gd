extends Node


## Dictionary of Monologue node types and their corresponding scenes.
const NODE_SCENES = {
	"Root": preload("res://nodes/root_node/root_node.tscn"),
	"Audio": preload("res://nodes/audio_node/audio_node.tscn"),
	"Action": preload("res://nodes/action_node/action_node.tscn"),
	"Background": preload("res://nodes/background_node/background_node.tscn"),
	"Bridge": preload("res://nodes/bridge_in_node/bridge_in_node.tscn"),
	"BridgeIn": preload("res://nodes/bridge_in_node/bridge_in_node.tscn"),
	"BridgeOut": preload("res://nodes/bridge_out_node/bridge_out_node.tscn"),
	"Choice": preload("res://nodes/choice_node/choice_node.tscn"),
	"Comment": preload("res://nodes/comment_node/comment_node.tscn"),
	"Condition": preload("res://nodes/condition_node/condition_node.tscn"),
	"Random": preload("res://nodes/random_node/random_node.tscn"),
	"EndPath": preload("res://nodes/end_path_node/end_path_node.tscn"),
	"Event": preload("res://nodes/event_node/event_node.tscn"),
	"Sentence": preload("res://nodes/sentence_node/sentence_node.tscn"),
	"Setter": preload("res://nodes/setter_node/setter_node.tscn"),
	"Wait": preload("res://nodes/wait_node/wait_node.tscn"),
	"Reroute": preload("res://nodes/reroute_node/reroute_node.tscn")
}
const PROPERTY_CLASSES = ["Property", "Localizable"]


static func empty_callback() -> void:
	return
