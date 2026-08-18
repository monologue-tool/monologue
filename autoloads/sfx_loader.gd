extends Node

var last_created_track: AudioStreamPlayer2D


func clear() -> void:
	for child: Node in get_children():
		child.queue_free()


func get_track() -> AudioStreamPlayer2D:
	return last_created_track


func load_track(path: String, loop: bool = false, volume: float = 0.0, pitch: float = 1.0) -> Error:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if not file:
		return ERR_FILE_NOT_FOUND

	var player: AudioStreamPlayer2D = AudioStreamPlayer2D.new()
	player.pitch_scale = pitch
	player.volume_db = volume
	var stream: AudioStream = null
	var buffer: PackedByteArray = file.get_buffer(file.get_length())
	match path.get_extension():
		"mp3":
			var mp3_stream: AudioStreamMP3 = AudioStreamMP3.new()
			mp3_stream.data = buffer
			mp3_stream.loop = loop
			stream = mp3_stream
		"ogg":
			var ogg_stream: AudioStreamOggVorbis = AudioStreamOggVorbis.load_from_buffer(buffer)
			ogg_stream.loop = loop
			stream = ogg_stream
		"wav":
			var wav_stream: AudioStreamWAV = parse_wav_data(buffer)
			if not wav_stream:
				return ERR_PARSE_ERROR
			wav_stream.loop_mode = int(loop) as AudioStreamWAV.LoopMode
			stream = wav_stream
		_:
			return ERR_INVALID_PARAMETER
	file.close()

	player.stream = stream
	player.connect("finished", player.queue_free)
	add_child(player)
	last_created_track = player
	player.name = path.get_file()
	player.play()
	return OK


## Create an AudioStreamWAV based on given file bytes. This code is adapted
## from [url]https://github.com/Gianclgar/GDScriptAudioImport[/url] which is
## MIT-licensed. 24-bit WAV is not converted, but rejected.
func parse_wav_data(bytes: PackedByteArray) -> AudioStreamWAV:
	var stream: AudioStreamWAV = AudioStreamWAV.new()
	var bits_per_sample: int = 0
	# read the .wav header in bytes, then assign values to the AudioStreamWAV
	for i: int in range(0, 43):
		var byte_chunk: String = str(
			char(bytes[i]) + char(bytes[i + 1]) + char(bytes[i + 2]) + char(bytes[i + 3])
		)
		if byte_chunk == "fmt ":
			var start: int = i + 8  # audio format starts 8 bytes after "fmt "

			# set format code (bytes 0-1)
			var format_code: int = bytes[start] + (bytes[start + 1] << 8)
			stream.format = format_code as AudioStreamWAV.Format

			# set channel number (bytes 2-3)
			var channel_number: int = bytes[start + 2] + (bytes[start + 3] << 8)
			stream.stereo = channel_number == 2

			# set sample rate (bytes 4-7)
			var sample_rate: int = (
				bytes[start + 4]
				+ (bytes[start + 5] << 8)
				+ (bytes[start + 6] << 16)
				+ (bytes[start + 7] << 24)
			)
			stream.mix_rate = sample_rate

			# set bits per sample/bitrate (bytes 14-15)
			bits_per_sample = bytes[start + 14] + (bytes[start + 15] << 8)
			if bits_per_sample not in [8, 16]:
				return null  # we only support 8-bit and 16-bit WAV

		elif byte_chunk == "data":
			var start: int = i + 8  # starts 8 bytes after "data"
			var size: int = (
				bytes[i + 4] + (bytes[i + 5] << 8) + (bytes[i + 6] << 16) + (bytes[i + 7] << 24)
			)
			stream.data = bytes.slice(start, start + size)
			break

	# calculate the size of each sample based on bits_per_sample
	var sample_size: float = bits_per_sample / 8.0
	# get samples and set loop end
	var sample_number: float = stream.data.size() / sample_size
	stream.loop_end = int(sample_number)
	return stream if stream.data else null
