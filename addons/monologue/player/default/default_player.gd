## A player that draws itself, so a story is watchable the moment it is added to a scene.
##
## Its parts live on a CanvasLayer, so the scene drops into a 2D scene, a 3D one or an editor
## window without needing a layout to fit into.
##
## All five parts are here. What is said, what is chosen, who is on stage, what is behind them
## and what is heard, each its own node, so a game can keep the four it likes.
##
## To change how it looks, inherit default_player.tscn and edit the nodes. To replace a piece,
## delete that node and point the export at your own part. Nothing here is forked, so the
## addon still updates underneath.
class_name MonologueDefaultPlayer extends MonologuePlayer

const SCENE_PATH: String = "res://addons/monologue/player/default/default_player.tscn"


## The scene, ready to add, for a game that would rather not carry the path.
static func create() -> MonologueDefaultPlayer:
	return (load(SCENE_PATH) as PackedScene).instantiate()
