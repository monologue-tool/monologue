extends Node
# TODO save logs in files

enum Levels {DEBUG, INFO, WARN, ERROR, FATAL}

var level: Levels = Levels.INFO


func _log(levelname: String, colorname: String, args: Array, bold: bool = false) -> void:
	var _args: Array = []
	_args.append("[color=%s]" % colorname)
	_args.append("[b]%-5s [/b]" % levelname)
	if bold: _args.append("[b]")
	_args.append(" ".join(args))
	if bold: _args.append("[/b]")
	_args.append("[/color]" % colorname)
	
	print_rich.callv(_args)


func msg(...args: Array) -> void:
	print_rich.callv(args)


func debug(...args: Array) -> void:
	_log("DEBUG", "#5f819d", args)


func info(...args: Array) -> void:
	_log("INFO", "#8c9440", args)


func warn(...args: Array) -> void:
	_log("WARN", "#de935f", args)


func error(...args: Array) -> void:
	_log("ERROR", "#a54242", args)


func exception(...args: Array) -> void:
	var stack: Array = get_stack()
	stack.pop_front()
	
	var call_idx: int = 0
	for _call: Dictionary in stack:
		var source: String = "%s:%s" % [_call.get("source", "<unknown>"), _call.get("line", -1)]
		args.append("[indent]%s - %s[/indent]" % [call_idx, source])
		call_idx += 1
	
	error.callv(args)


func fatal(...args: Array) -> void:
	_log("FATAL", "#a54242", args, true)
