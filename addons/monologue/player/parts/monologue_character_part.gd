## Who is on screen, and how.
@abstract class_name MonologueCharacterPart extends Node


## [param character] is the whole character record; [param look] is everything about the
## picture, already resolved: [code]image[/code] is a path to open, [code]portrait[/code] the
## record it came from, [code]curve[/code] the four coordinates of an ease, [code]offset[/code]
## a [Vector2], plus [code]position[/code], [code]z_index[/code], [code]flip_h[/code],
## [code]flip_v[/code] and [code]duration[/code].
@abstract func apply(character: Dictionary, look: Dictionary) -> void
@abstract func leave(character_id: String, duration: float) -> void
## Puts the stage back as [param stage] describes it -- character id to [param look] -- without
## animating. What a loaded save and a rewind both need, and the reason [MonologueState] keeps
## a stage at all.
@abstract func restage(stage: Dictionary) -> void
