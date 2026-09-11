@tool
class_name AtlasValue
extends Control
## Texto independente. A grafia original é preservada quando o valor é igual
## ao da referência; qualquer novo valor usa o Label, sem texto antigo por baixo.
const SOURCE: Texture2D = preload("res://assets/reference/ilha_digital_approved.png")
@export var source_region: Rect2
@export var reference_text: String = ""
@export var font_size: int = 24
@export var font_color: Color = Color.WHITE
@export var alignment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT
var text: String = ""

func _ready() -> void:
	configure(source_region, reference_text)

func configure(region: Rect2, original_value: String) -> void:
	source_region = region
	reference_text = original_value
	var artwork := AtlasTexture.new()
	artwork.atlas = SOURCE
	artwork.region = source_region
	artwork.filter_clip = true
	$ReferenceInk.texture = artwork
	$Value.add_theme_color_override("font_color", font_color)
	$Value.horizontal_alignment = alignment
	set_value(reference_text)

func set_value(value: String) -> void:
	text = value
	$Value.text = value
	var point_size := font_size
	var font: Font = $Value.get_theme_font("font")
	while point_size > 12 and font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, point_size).x > size.x:
		point_size -= 1
	$Value.add_theme_font_size_override("font_size", point_size)
	$ReferenceInk.visible = value == reference_text
	$Value.visible = value != reference_text
