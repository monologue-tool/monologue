## A player that draws itself, so a story is watchable the moment it is added to a scene.
##
## Its parts live on a CanvasLayer, which is what lets the scene be dropped anywhere -- a 2D
## scene, a 3D one, or an editor window -- without a layout to fit into.
##
## To change how it looks, inherit default_player.tscn and edit the nodes. To replace a piece
## outright, delete that node and point the export at your own [MonologueTextBoxPart] or
## [MonologueChoicePart]; nothing here is forked, so the addon still updates.
class_name MonologueDefaultPlayer extends MonologuePlayer

const SCENE_PATH: String = "res://addons/monologue/player/default/default_player.tscn"


## The scene, ready to add. What a game calls when it would rather not carry the path.
static func create() -> MonologueDefaultPlayer:
	return (load(SCENE_PATH) as PackedScene).instantiate()
