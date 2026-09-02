extends Node
class_name BattleSfx

# Banco polifonico dos sons de carta. Os WAV preservam o AAC original sem
# uma segunda compressao com perdas e sao leves o bastante para SFX curtos.

const POOL_SIZE := 10
const SONS := {
	"touch": preload("res://assets/audio/sfx/battle/se_touch.wav"),
	"fusion": preload("res://assets/audio/sfx/battle/se_gousei_hit.wav"),
	"wild": preload("res://assets/audio/sfx/battle/se_wildattack1.wav"),
	"countup": preload("res://assets/audio/sfx/battle/se_countup.wav"),
	"shuffle_1": preload("res://assets/audio/sfx/battle/se_card_shuffle.wav"),
	"shuffle_2": preload("res://assets/audio/sfx/battle/se_card_shuffle2.wav"),
	"shuffle_3": preload("res://assets/audio/sfx/battle/se_card_shuffle3.wav"),
}
const SHUFFLES := ["shuffle_1", "shuffle_2", "shuffle_3"]

var habilitado := true
var _players: Array[AudioStreamPlayer] = []
var _cursor := 0
var _shuffle_indice := 0
var _variacao_toque := 0


func _ready() -> void:
	habilitado = DisplayServer.get_name() != "headless"
	for i in POOL_SIZE:
		var player := AudioStreamPlayer.new()
		player.name = "Voice%02d" % i
		player.bus = "Master"
		add_child(player)
		_players.append(player)


func _exit_tree() -> void:
	for player: AudioStreamPlayer in _players:
		player.stop()
		player.stream = null
	_players.clear()


func tocar(chave: String, volume_db := 0.0, pitch := 1.0,
		cortar_mesmo := false) -> void:
	if not habilitado or not SONS.has(chave):
		return
	if cortar_mesmo:
		for player: AudioStreamPlayer in _players:
			if player.playing and String(player.get_meta("sfx_chave", "")) == chave:
				player.stop()
	var escolhido: AudioStreamPlayer
	for player: AudioStreamPlayer in _players:
		if not player.playing:
			escolhido = player
			break
	if escolhido == null:
		escolhido = _players[_cursor]
		_cursor = (_cursor + 1) % _players.size()
		escolhido.stop()
	escolhido.set_meta("sfx_chave", chave)
	escolhido.stream = SONS[chave]
	escolhido.volume_db = volume_db
	escolhido.pitch_scale = clampf(pitch, 0.65, 1.45)
	escolhido.play()


func toque(pitch := 1.0) -> void:
	# Alternancia quase imperceptivel evita que cliques consecutivos soem
	# mecanicamente identicos sem descaracterizar o efeito original.
	var variacoes := [0.97, 1.0, 1.035]
	var pitch_final: float = pitch * float(variacoes[_variacao_toque])
	_variacao_toque = (_variacao_toque + 1) % variacoes.size()
	tocar("touch", -5.0, pitch_final)


func descida(pitch := 1.0) -> void:
	tocar("shuffle_1", -11.0, pitch * 1.06, true)


func fusao(pitch := 1.0) -> void:
	tocar("fusion", -6.0, pitch, true)


func ataque_wild(pitch := 1.0) -> void:
	tocar("wild", -4.0, pitch, true)


func contagem(pitch := 1.0) -> void:
	tocar("countup", -8.0, pitch, true)


func embaralhar(pitch := 1.0) -> void:
	var chave: String = SHUFFLES[_shuffle_indice]
	_shuffle_indice = (_shuffle_indice + 1) % SHUFFLES.size()
	tocar(chave, -7.0, pitch, true)
