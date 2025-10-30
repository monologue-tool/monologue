extends Node

var characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"


## Retries up to 100 times to avoid collisions with existing IDs
func generate(length: int = 10, avoid_ids: Array = []) -> String:
	for _i in range(100):
		var id = ""
		var random = RandomNumberGenerator.new()
		random.randomize()

		for i in range(length):
			var index = random.randi_range(0, characters.length() - 1)
			id += characters[index]

		if id not in avoid_ids:
			return id

	push_error("The program failed to generate a random number.")
	return ""
