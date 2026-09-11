@tool
class_name CardView
extends Button

@export var slot_index: int = 0
@export var initial_kind: int = 0
@export var original_art: AtlasTexture
@export var is_preview: bool = false
var kind: int = 0
var artwork: AtlasTexture
var selected: bool = false
var power: int = 4
const ORIGINAL_POWERS: Array[int] = [4, 7, 6, 9, 8, 5, 10]

func _ready() -> void:
	kind = initial_kind
	artwork = original_art
	flat = true
	focus_mode = Control.FOCUS_NONE
	for style in ["normal", "hover", "pressed", "disabled", "focus"]:
		add_theme_stylebox_override(style, StyleBoxEmpty.new())
	_configure_face(ORIGINAL_POWERS[kind], ORIGINAL_POWERS[kind])

func show_card(new_kind: int, definition: CardDefinition, card_value: int = -1) -> void:
	if new_kind != kind:
		kind = new_kind
		artwork = definition.preview if is_preview else definition.artwork
	_configure_face(definition.printed_power, definition.power if card_value < 0 else card_value)

func set_selected(value: bool) -> void:
	selected = value
	$Selection.visible = value

func _configure_face(printed: int, current: int) -> void:
	if artwork == null:
		return
	power = current
	$Face.texture = artwork
	var source_size := artwork.region.size
	var inset := Vector2(28, 28) if source_size.y < 100 else Vector2(43, 42)
	var number_size := Vector2(25, 25) if source_size.y < 100 else Vector2(37, 34)
	var number_rect := Rect2(artwork.region.position + source_size - inset, number_size)
	var regions: Array[Rect2] = [number_rect]
	$Face.configure_regions(regions)
	var ratio := size / source_size
	$Number.position = (source_size - inset) * ratio
	$Number.size = number_size * ratio
	$Number.font_size = 21 if is_preview else 28
	$Number.alignment = HORIZONTAL_ALIGNMENT_RIGHT
	$Number.configure(number_rect, str(printed))
	$Number.set_value(str(current))
