extends Node
## Global game state, food quota tracking, and run lifecycle management.

enum GameState {
	PLAYING,
	PAUSED,
	CAUGHT,
	ESCAPED,
}

signal state_changed(new_state: GameState)
signal food_collected(current_count: int, total_weight: float)
signal run_reset

@export var required_food_for_good_ending: int = 5

var current_state: GameState = GameState.PLAYING
var food_count: int = 0
var carried_weight: float = 0.0
var death_count: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func set_state(new_state: GameState) -> void:
	if current_state == new_state:
		return
	current_state = new_state
	get_tree().paused = (new_state == GameState.PAUSED)
	var time_manager := get_node_or_null("/root/TimeManager")
	if time_manager:
		time_manager.set("is_running", new_state == GameState.PLAYING)
	state_changed.emit(current_state)


func add_food(weight: float = 1.0) -> void:
	food_count += 1
	carried_weight += weight
	food_collected.emit(food_count, carried_weight)


func trigger_caught() -> void:
	if current_state != GameState.PLAYING:
		return
	death_count += 1
	set_state(GameState.CAUGHT)


func trigger_escape(is_secret_exit: bool = false) -> String:
	set_state(GameState.ESCAPED)
	if is_secret_exit and food_count >= required_food_for_good_ending:
		return "GOOD_ENDING"
	return "BAD_ENDING"


func reset_run() -> void:
	food_count = 0
	carried_weight = 0.0
	set_state(GameState.PLAYING)
	run_reset.emit()
	get_tree().reload_current_scene()
