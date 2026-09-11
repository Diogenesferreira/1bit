@tool
class_name AtlasGauge
extends ProgressBar

const SOURCE: Texture2D = preload("res://assets/reference/ilha_digital_approved.png")
@export var source_region: Rect2
@export var reference_value: float = 0.0
@export var reference_max: float = 100.0
@export var fill_color: Color = Color("21d534")

func _ready() -> void:
	show_percentage = false
	var background := StyleBoxFlat.new()
	background.bg_color = Color("071526")
	var fill := StyleBoxFlat.new()
	fill.bg_color = fill_color
	fill.border_width_top = 2
	fill.border_color = fill_color.lightened(0.35)
	add_theme_stylebox_override("background", background)
	add_theme_stylebox_override("fill", fill)
	var artwork := AtlasTexture.new()
	artwork.atlas = SOURCE
	artwork.region = source_region
	artwork.filter_clip = true
	$ReferenceFill.texture = artwork
	max_value = reference_max
	value = reference_value
	value_changed.connect(func(_value): _sync_appearance())
	changed.connect(_sync_appearance)
	_sync_appearance()

func set_state(current: float, maximum: float) -> void:
	max_value = maxf(1.0, maximum)
	value = clampf(current, min_value, max_value)
	_sync_appearance()

func _sync_appearance() -> void:
	$ReferenceFill.visible = is_equal_approx(value, reference_value) and is_equal_approx(max_value, reference_max)
