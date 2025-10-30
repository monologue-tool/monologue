## Global signal bus singleton.
##
## A centralized event bus system that allows different parts of the application
## to communicate through named signals without direct coupling. Manages dynamic
## signal listeners that can be registered and triggered at runtime.
extends Node

## Dictionary tracking registered listeners for each signal name.
## Keys are signal names (String), values are arrays of Callable methods.
var _listeners = {}


## Adds a new global listener method for a specific signal name.
##
## Registers a callable method to be invoked when the specified signal is emitted.
## Multiple listeners can be registered for the same signal.
## [br][br]
## [param signal_name] The name of the signal to listen for.
## [br][br]
## [param method] The callable method to invoke when the signal is emitted.
func add_listener(signal_name: String, method: Callable) -> void:
	if not _listeners.has(signal_name):
		_listeners[signal_name] = []

	_listeners[signal_name].append(method)


## Removes a registered listener method from a signal.
##
## Unregisters a previously registered callable method from the specified signal.
## Does nothing if the signal or method was not registered.
## [br][br]
## [param signal_name] The name of the signal.
## [br][br]
## [param method] The callable method to remove.
func remove_listener(signal_name: String, method: Callable) -> void:
	if not _listeners.has(signal_name):
		return
	if not _listeners[signal_name].has(method):
		return

	_listeners[signal_name].erase(method)


## Emits a named signal, calling all registered listener methods.
##
## Invokes all registered methods for the specified signal name with the provided arguments.
## Automatically removes invalid methods during emission.
## [br][br]
## [param signal_name] The name of the signal to emit.
## [br][br]
## [param args] Optional array of arguments to pass to listener methods. Default is empty array.
func emit(signal_name: String, args: Array = []):
	if not _listeners.has(signal_name):
		return

	for method in _listeners[signal_name]:
		if not method.is_valid():
			_listeners[signal_name].erase(method)
			continue
		method.callv(args)
