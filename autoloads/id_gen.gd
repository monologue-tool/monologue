## ID generator singleton for creating unique random identifiers.
##
## Provides methods to generate random alphanumeric IDs used throughout
## the Monologue application for unique identification of nodes, characters,
## and other objects.
extends Node

## Character set used for generating random IDs.
var characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"


## Generates a random alphanumeric ID string.
##
## Creates a random ID of the specified length from the character set.
## Will make up to 100 attempts to generate an ID that is not in the [param avoid_ids] list.
## [br][br]
## [param length] The length of the ID to generate. Default is 10 characters.
## [br][br]
## [param avoid_ids] Array of IDs that should not be generated.
## [br][br]
## Returns a unique ID string, or an empty string if generation fails after 100 attempts.
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
