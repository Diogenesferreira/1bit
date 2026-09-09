class_name StageDefinition
extends Resource

@export var biome: BiomeDefinition
@export var allies: Array[CharacterDefinition] = []
@export var enemies: Array[CharacterDefinition] = []
@export var total_rounds: int = 3
@export var hp_cap: int = 9999
@export var leader_cooldown: int = 3
@export var skill_threshold: int = 100
@export var skill_gain: int = 25
@export var enemy_attack: int = 65
@export var damage_per_power: int = 20
@export var heal_per_power: int = 35
