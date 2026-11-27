extends Node
## Central event bus for sound propagation between the player/props and Chef AI.

signal sound_emitted(origin: Vector3, radius: float, loudness: float, source_tag: String)


func emit_sound(origin: Vector3, radius: float, loudness: float = 1.0, source_tag: String = "generic") -> void:
	sound_emitted.emit(origin, radius, loudness, source_tag)
