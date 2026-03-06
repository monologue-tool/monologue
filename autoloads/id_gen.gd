class_name IDGen extends Node

const CHARS = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"


static func generate(length: int = 10) -> String:
	var id = ""
	for i in range(length):
		var index = randi() % CHARS.length()
		id += CHARS[index]

	return id