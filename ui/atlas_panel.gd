@tool
class_name AtlasPanel
extends TextureRect
## A moldura não exibe os valores/cartas removidos. Eles pertencem aos filhos.
const CLEAR_SHADER: Shader = preload("res://ui/atlas_panel.gdshader")
@export var clear_regions: Array[Rect2] = []

func _ready() -> void:
	configure_regions(clear_regions)

func configure_regions(regions: Array[Rect2]) -> void:
	clear_regions = regions
	var uniforms := PackedVector4Array()
	for rectangle in clear_regions:
		uniforms.append(Vector4(rectangle.position.x, rectangle.position.y, rectangle.size.x, rectangle.size.y))
	uniforms.resize(32)
	var mask := ShaderMaterial.new()
	mask.shader = CLEAR_SHADER
	mask.set_shader_parameter("clear_count", mini(clear_regions.size(), 32))
	mask.set_shader_parameter("clear_regions", uniforms)
	material = mask
