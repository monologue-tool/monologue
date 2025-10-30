## Extends Godot's [UndoRedo] class with ability to record more complicated
## Monologue interactions via custom [MonologueHistory].
##
## To start using, call [method UndoRedo.create_action] first, then call
## [method add_prepared_history] for prepared Monologue interactions.
## Finally, call [method UndoRedo.commit_action] to execute into history.
##
## It can be tedious to always call the various built-in methods like
## [method UndoRedo.add_do_method] because of many moving parts in the
## Monologue architecture. That's why there are custom [MonologueHistory]
## classes to separate bigger operations/data into its own section.
class_name HistoryHandler extends UndoRedo


## Extracts the undo/redo callback methods from the given [param history]
## and registers them to the currently created action.
## Updates to related properties and references are the concern of
## [param history], we don't need to care about that here.
func add_prepared_history(history: MonologueHistory):
	add_do_method(history.redo)
	add_undo_method(history.undo)
