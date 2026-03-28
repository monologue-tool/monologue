extends Node
# TODO save logs in files

enum Levels {DEBUG, INFO, WARN, ERROR, FATAL}

var log_level: Levels = Levels.INFO
var _label := RichTextLabel.new()


func _ready() -> void:
	_label.bbcode_enabled = true


func _log(level: Levels, levelname: String, colorname: String, args: Array, bold: bool = false) -> void:
	if level < log_level:
		return
	
	var message: String = " ".join(args)
	var bbcode_args: Array = []
	bbcode_args.append("[color=%s]" % colorname)
	bbcode_args.append("[b]%-5s [/b]" % levelname)
	if bold: bbcode_args.append("[b]")
	bbcode_args.append(message)
	if bold: bbcode_args.append("[/b]")
	bbcode_args.append("[/color]")
	
	print_rich.callv(bbcode_args)
	var _raw_log: String = _bbcode_to_plain("".join(bbcode_args))
	


func msg(...args: Array) -> void:
	print_rich.callv(args)


func debug(...args: Array) -> void:
	_log(Levels.DEBUG, "DEBUG", "#5f819d", args)


func info(...args: Array) -> void:
	_log(Levels.INFO, "INFO", "#8c9440", args)


func warn(...args: Array) -> void:
	_log(Levels.WARN, "WARN", "#de935f", args)


func error(...args: Array) -> void:
	_log(Levels.ERROR, "ERROR", "#a54242", args)


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
	_log(Levels.FATAL, "FATAL", "#a54242", args, true)


func _bbcode_to_plain(bbcode: String) -> String:
	_label.text = bbcode
	return _label.get_parsed_text()
