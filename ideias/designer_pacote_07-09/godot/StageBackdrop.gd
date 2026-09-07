## Fundo do palco com crossfade na troca de stage.
## Contrato: spec/FORMACOES.md secao 4.
##
## Os PNG sao autorados em 222x140 e desenhados em 888x560 (x4 EXATO).
## Nunca use "cover"/"keep_aspect_covered": corta fora do grid e quebra o x4.
class_name StageBackdrop
extends Control

const ART := "res://art/"
const SIZE := Vector2i(888, 560)
const FADE := 0.6

const BACKDROPS := [
	"backdrops/stage_plains_v1.png",   # 1/3
	"backdrops/stage_forest_v1.png",   # 2/3
	"backdrops/stage_sea_v1.png",      # 3/3 boss
]

var _atual: TextureRect
var _anterior: TextureRect
var _scrim: ColorRect

func _ready() -> void:
	custom_minimum_size = SIZE
	size = SIZE
	clip_contents = true
	_anterior = _camada(0)
	_atual = _camada(1)
	_atual.texture = load(ART + BACKDROPS[0])
	_scrim = ColorRect.new()
	_scrim.color = Color(0.031, 0.035, 0.031, 0.35)
	_scrim.size = Vector2(SIZE)
	_scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_scrim)

func trocar_para(stage_idx: int) -> void:
	_anterior.texture = _atual.texture
	_anterior.modulate.a = 1.0
	_atual.texture = load(ART + BACKDROPS[stage_idx % BACKDROPS.size()])
	_atual.modulate.a = 0.0
	var t := create_tween()
	t.tween_property(_atual, "modulate:a", 1.0, FADE)
	t.parallel().tween_property(_anterior, "modulate:a", 0.0, FADE)

func _camada(z: int) -> TextureRect:
	var r := TextureRect.new()
	r.size = Vector2(SIZE)
	r.stretch_mode = TextureRect.STRETCH_SCALE   # 222x140 -> 888x560 = x4
	r.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.z_index = z
	add_child(r)
	return r
