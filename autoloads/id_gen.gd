class_name IDGen extends Node

const CHARS = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"


static func generate(length: int = 10, avoid_ids: Array = []) -> String:
	for _i in range(100):
		var id = ""
		var random = RandomNumberGenerator.new()
		random.randomize()

		for i in range(length):
			var index = random.randi_range(0, CHARS.length() - 1)
			id += CHARS[index]

		if id not in avoid_ids:
			return id

	push_error("The program failed to generate a random number.")
	return ""
