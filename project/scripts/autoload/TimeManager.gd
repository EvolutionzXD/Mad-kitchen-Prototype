extends Node
## Internal kitchen cycle clock used to drive Chef AI's fixed timetable.

signal cycle_tick(cycle_time: float, normalized_progress: float)
signal cycle_looped

@export var cycle_duration_seconds: float = 180.0

var elapsed_cycle_time: float = 0.0
var is_running: bool = true


func _process(delta: float) -> void:
	if not is_running:
		return

	elapsed_cycle_time += delta
	if elapsed_cycle_time >= cycle_duration_seconds:
		elapsed_cycle_time = fmod(elapsed_cycle_time, cycle_duration_seconds)
		cycle_looped.emit()

	var progress: float = elapsed_cycle_time / maxf(cycle_duration_seconds, 0.001)
	cycle_tick.emit(elapsed_cycle_time, progress)


func reset_clock() -> void:
	elapsed_cycle_time = 0.0
