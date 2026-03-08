class_name IDGen

const _CHARS: String = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
static var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


static func generate(length: int = 10) -> String:
	var id: String = ""
	for i: int in range(length):
		id += _CHARS[_rng.randi_range(0, _CHARS.length() - 1)]
	return id
