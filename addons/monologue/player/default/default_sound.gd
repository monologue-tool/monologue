## Music, effects and voice, on three players so that none of them cuts the others off.
##
## What loops is music and what does not is an effect: a story that starts a second piece of
## music means to replace the first, and one that fires two footsteps means both.
class_name MonologueDefaultSound extends MonologueSoundPart

@export var music: AudioStreamPlayer
@export var effects: AudioStreamPlayer
@export var voice: AudioStreamPlayer


func play(path: String, loop: bool, volume_db: float, pitch: float) -> void:
	var player: AudioStreamPlayer = music if loop else effects
	var stream: AudioStream = MonologueAssets.sound(path)
	if player == null or stream == null:
		return

	MonologueAssets.set_looping(stream, loop)
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = pitch
	player.play()


## A line as it was recorded, over whatever else is playing. Only one at a time: two people
## talking at once is never what a story meant.
func play_voice(path: String) -> void:
	var stream: AudioStream = MonologueAssets.sound(path)
	if voice == null or stream == null:
		return

	MonologueAssets.set_looping(stream, false)
	voice.stream = stream
	voice.play()


func stop_all() -> void:
	for player: AudioStreamPlayer in [music, effects, voice]:
		if player != null:
			player.stop()
