extends CanvasLayer
class_name PrototypeHUD
## Minimal debug HUD showing controls and current mouse movement state.

@onready var state_label: Label = $Panel/VBox/StateLabel


func set_state_text(state_text: String) -> void:
	if state_label:
		state_label.text = "Trạng thái: " + state_text
