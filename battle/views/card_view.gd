class_name CardView
extends Button

@export var slot_index: int = 0
@export var initial_kind: int = 0
@export var original_art: AtlasTexture
var kind: int = 0
var artwork: Texture2D
var selected: bool = false

func _ready() -> void:
	kind = initial_kind
	artwork = original_art
	flat = true
	focus_mode = Control.FOCUS_NONE
	for style in ["normal", "hover", "pressed", "disabled", "focus"]:
		add_theme_stylebox_override(style, StyleBoxEmpty.new())
	queue_redraw()

func show_card(new_kind: int, definition: CardDefinition) -> void:
	if new_kind != kind:
		kind = new_kind
		artwork = definition.artwork
	queue_redraw()

func set_selected(value: bool) -> void:
	selected = value
	queue_redraw()

func _draw() -> void:
	if artwork != null:
		draw_texture_rect(artwork, Rect2(Vector2.ZERO, size), false)
	if selected:
		draw_rect(Rect2(Vector2(3, 3), size - Vector2(6, 6)), Color("e9fcff"), false, 4.0)
