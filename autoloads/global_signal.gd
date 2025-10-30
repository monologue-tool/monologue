## Global event bus for decoupled communication without direct signal connections
extends Node

var _listeners = {}


func add_listener(signal_name: String, method: Callable) -> void:
	if not _listeners.has(signal_name):
		_listeners[signal_name] = []

	_listeners[signal_name].append(method)


func remove_listener(signal_name: String, method: Callable) -> void:
	if not _listeners.has(signal_name):
		return
	if not _listeners[signal_name].has(method):
		return

	_listeners[signal_name].erase(method)


func emit(signal_name: String, args: Array = []):
	if not _listeners.has(signal_name):
		return

	for method in _listeners[signal_name]:
		if not method.is_valid():
			_listeners[signal_name].erase(method)
			continue
		method.callv(args)
