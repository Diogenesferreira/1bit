class_name CardDefinition
extends Resource

enum Kind { DRAGON, KNIGHT, NATURE, LIGHT, DARK, CAPSULE, WILD }

@export var kind: Kind = Kind.DRAGON
@export var display_name: String = "Dragon"
@export var power: int = 4
@export var printed_power: int = 4
@export var artwork: AtlasTexture
@export var preview: AtlasTexture
