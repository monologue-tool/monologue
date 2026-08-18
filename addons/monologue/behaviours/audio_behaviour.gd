## Remembers the looping ones, so a restored save does not come back to silence.
extends MonologueBehaviour

const SLOT: String = "audio"


func handles() -> PackedStringArray:
	return ["audio"]


func setup(ctx: MonologueContext) -> void:
	var kept: Dictionary = ctx.state.stage.get(SLOT, {})
	if not kept.is_empty():
		_play(ctx, kept)


func run(ctx: MonologueContext) -> BehaviourResult:
	var stream: String = str(ctx.value("stream", ""))
	if stream.is_empty():
		ctx.note(&"audio_without_stream", "This node names no sound.")
		return BehaviourResult.progress(ctx.next())

	var playback: Dictionary = {
		"stream": stream,
		"loop": bool(ctx.value("loop", false)),
		"volume": float(ctx.value("volume", 0.0)),
		"pitch": float(ctx.value("pitch", 1.0)),
	}

	# A one-shot has long finished by the time anyone loads the save.
	if playback["loop"]:
		ctx.state.stage[SLOT] = playback
	else:
		ctx.state.stage.erase(SLOT)

	_play(ctx, playback)
	return BehaviourResult.progress(ctx.next())


func _play(ctx: MonologueContext, playback: Dictionary) -> void:
	if ctx.player.sound == null:
		return
	ctx.player.sound.play(
		ctx.player.resolve(str(playback.get("stream", ""))),
		bool(playback.get("loop", false)),
		float(playback.get("volume", 0.0)),
		float(playback.get("pitch", 1.0))
	)
