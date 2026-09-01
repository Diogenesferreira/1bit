# FragmentSeal.gd — Selos de Fragmento (Godot 4)
#
# Árvore de nós esperada:
#
#   FragmentSeal            (Node2D, este script)
#     Portrait              (Sprite2D)  -> sprite do personagem, fundo transparente
#     Frame                 (Sprite2D)  -> fragment_seal_{el}_empty_v1.png
#     Charge                (Sprite2D)  -> fragment_seal_{el}_charge_sheet_v1.png (AtlasTexture)
#     Shine                 (Sprite2D)  -> mesma textura de Charge, material aditivo
#     Ring                  (Sprite2D)  -> opcional: contorno de 2 px, ou um Line2D/9-patch
#
# Todos os Sprite2D com centered = false e position = Vector2.ZERO.
# Portrait deve ser recortado pela abertura (ver PORTRAIT_RECT).

extends Node2D

const SEAL_SIZE := 330
const MAX_CHARGE := 8

# abertura do personagem, em px de arquivo
const PORTRAIT_RECT := Rect2(54, 45, 222, 237)
const PORTRAIT_FEET_Y := 276
const PORTRAIT_CENTER_X := 165

const COLORS := {
	"dragon": Color("#a8443a"),
	"knight": Color("#5a86a8"),
	"nature": Color("#7d9455"),
	"light": Color("#c9a842"),
	"dark": Color("#7a5f9a"),
}

@export_enum("dragon", "knight", "nature", "light", "dark") var element: String = "nature"
@export_range(0, 8) var charge: int = 0 : set = set_charge

var _ready_time := 0.0
var _is_ready := false

func _ready() -> void:
	_load_textures()
	_apply_charge()

func _load_textures() -> void:
	var base := "res://art/seals/"
	$Frame.texture = load(base + "fragment_seal_%s_empty_v1.png" % element)
	var sheet: Texture2D = load(base + "fragment_seal_%s_charge_sheet_v1.png" % element)
	for n in ["Charge", "Shine"]:
		var atlas := AtlasTexture.new()
		atlas.atlas = sheet
		atlas.region = Rect2(0, 0, SEAL_SIZE, SEAL_SIZE)
		get_node(n).texture = atlas
	$Shine.visible = false
	if has_node("Ring"):
		$Ring.visible = false

func set_charge(value: int) -> void:
	charge = clampi(value, 0, MAX_CHARGE)
	if is_inside_tree():
		_apply_charge()

func add_charge(amount: int = 1) -> void:
	# 420 ms por encaixe: chame isto pelo seu timer/turno de jogo
	set_charge(charge + amount)

func spend() -> void:
	# gasto da skill: volta a zero em snap, sem fade
	set_charge(0)

func _apply_charge() -> void:
	var region := Rect2(0, charge * SEAL_SIZE, SEAL_SIZE, SEAL_SIZE)
	($Charge.texture as AtlasTexture).region = region
	($Shine.texture as AtlasTexture).region = Rect2(0, MAX_CHARGE * SEAL_SIZE, SEAL_SIZE, SEAL_SIZE)
	var full := charge >= MAX_CHARGE
	if full != _is_ready:
		_is_ready = full
		_ready_time = 0.0
		$Shine.visible = full
		if has_node("Ring"):
			$Ring.visible = full
		if full:
			emit_signal("skill_ready")

signal skill_ready

func _process(delta: float) -> void:
	if not _is_ready:
		modulate = Color.WHITE
		return
	_ready_time += delta
	# loop de 1.3 s
	var t: float = fmod(_ready_time, 1.3) / 1.3
	var pulse: float = 0.5 - 0.5 * cos(t * TAU)          # 0 -> 1 -> 0, ease-in-out
	# halo: brilho 1.00 -> 1.12
	var c := COLORS[element]
	modulate = Color(1.0, 1.0, 1.0).lerp(Color(1.12, 1.12, 1.12), pulse)
	# varredura aditiva: 0 -> 0.85 -> 0
	$Shine.modulate = Color(c.r, c.g, c.b, 0.85 * pulse)
	# anel: escala 1.00 -> 1.16, alpha 0.55 -> 0
	if has_node("Ring"):
		var s: float = lerp(1.0, 1.16, t)
		$Ring.scale = Vector2(s, s)
		$Ring.position = Vector2(SEAL_SIZE, SEAL_SIZE) * 0.5 * (1.0 - s)
		$Ring.modulate = Color(c.r, c.g, c.b, 0.55 * (1.0 - t))

# Halo real (glow que segue a silhueta): adicione um WorldEnvironment com
# Glow ativado (bloom), ou um BackBufferCopy + ShaderMaterial de blur no
# nó Frame/Charge. O 'modulate' acima só faz o pulso de brilho.
