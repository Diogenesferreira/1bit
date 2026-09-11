class_name BattleAudio
extends Node

const EFFECT_ROOT := "res://audio/battle/effects/"
const MUSIC_ROOT := "res://audio/battle/music/"

const EFFECT_VOLUMES := {
	"se_touch": -7.0,
	"se_gousei": -2.0,
	"se_wildattack1": -1.0,
	"se_countup": -5.0,
	"se_card_shuffle": -6.0,
	"se_card_shuffle3": -5.0,
	"se_arrart2": -3.0,
}

var effects: Dictionary = {}
var music: AudioStreamPlayer

func _ready() -> void:
	for effect_name in EFFECT_VOLUMES:
		var player := AudioStreamPlayer.new()
		player.name = effect_name
		player.stream = load(EFFECT_ROOT + effect_name + ".wav")
		player.volume_db = EFFECT_VOLUMES[effect_name]
		player.max_polyphony = 12
		add_child(player)
		effects[effect_name] = player
	music = AudioStreamPlayer.new()
	music.name = "BattleResultMusic"
	music.volume_db = -7.0
	add_child(music)

func play_effect(effect_name: String, volume_offset_db := 0.0, pitch := 1.0) -> void:
	var player := effects.get(effect_name) as AudioStreamPlayer
	if player == null or player.stream == null:
		return
	player.volume_db = float(EFFECT_VOLUMES.get(effect_name, 0.0)) + volume_offset_db
	player.pitch_scale = pitch
	player.play()

func play_result(won: bool) -> void:
	if music == null:
		return
	music.stream = load(MUSIC_ROOT + ("bgm_06_battle_win.ogg" if won else "bgm_07_battle_lose.ogg"))
	music.play()

func stop_all() -> void:
	for player in effects.values():
		(player as AudioStreamPlayer).stop()
	if music:
		music.stop()
