extends Node3D
## Root scene wiring the greybox level, mouse player, and prototype HUD.

@onready var mouse_player: MouseController = $MousePlayer
@onready var prototype_hud: PrototypeHUD = $PrototypeHUD


func _ready() -> void:
	if mouse_player and prototype_hud:
		mouse_player.state_text_changed.connect(prototype_hud.set_state_text)
