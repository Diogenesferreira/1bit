class_name CharacterDefinition
extends Resource
## Região visual de referência; a criatura continua integrada à pintura fixa.
@export var display_name: String
@export var element: CardDefinition.Kind
@export var level: int = 38
@export var max_hp: int = 640
@export var is_boss: bool = false
@export var atlas_region: Rect2
