extends Control
signal navigation_requested(destination: String)

func _ready() -> void:
	for button in $Buttons.get_children():
		button.pressed.connect(func(): navigation_requested.emit(button.name.to_lower()))
