"""Gera cenas e AtlasTextures sem modificar nenhum pixel do PNG aprovado.

Execute apenas para atualizar a estrutura/retângulos do atlas.
"""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ATLAS = "res://assets/reference/ilha_digital_approved.png"
CARD_NAMES = ["dragon", "knight", "nature", "light", "dark", "capsule", "wild"]
CARD_LABELS = ["Dragon", "Knight", "Nature", "Light", "Dark", "Capsule", "Wild Card"]
POWERS = [4, 7, 6, 9, 8, 5, 10]
XS = [28, 190, 356, 522, 686, 850]
WIDTHS = [150, 153, 154, 154, 154, 147]
KINDS = [0, 1, 2, 3, 4, 6, 5, 0, 1, 2, 6, 3]
CARDS = [(XS[i % 6], 982 if i < 6 else 1154, WIDTHS[i % 6], 160) for i in range(12)]
BAG = [(228, 817, 81, 85), (329, 817, 81, 85), (430, 817, 81, 85),
       (531, 817, 81, 85), (632, 817, 81, 85), (735, 817, 84, 85)]
SECTIONS = [
    ("AccountHUD", "ui/account_hud", 0, 112),
    ("Battlefield", "battle/views/battlefield", 112, 605),
    ("CombatHUD", "battle/views/combat_hud", 717, 87),
    ("BagPreview", "battle/views/bag_preview", 804, 116),
    ("AttackBoard", "battle/views/attack_board", 920, 430),
    ("BottomNavigation", "ui/bottom_navigation", 1350, 186),
]

def write(path, text):
    target = ROOT / path
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(text.rstrip() + "\n", encoding="utf-8")

def rect(r):
    return "Rect2(%s)" % ", ".join(str(v) for v in r)

def offsets(r):
    x, y, w, h = r
    return f"offset_left = {float(x)}\noffset_top = {float(y)}\noffset_right = {float(x+w)}\noffset_bottom = {float(y+h)}\n"

def atlas_resource(name, r):
    return f'[sub_resource type="AtlasTexture" id="{name}"]\natlas = ExtResource("atlas")\nregion = {rect(r)}\nfilter_clip = true\n\n'

def button(name, parent, r, tooltip=""):
    return f'''[node name="{name}" type="Button" parent="{parent}"]
{offsets(r)}focus_mode = 0
mouse_default_cursor_shape = 2
tooltip_text = "{tooltip}"
theme_override_styles/normal = SubResource("empty")
theme_override_styles/hover = SubResource("empty")
theme_override_styles/pressed = SubResource("empty")
theme_override_styles/disabled = SubResource("empty")
theme_override_styles/focus = SubResource("empty")
flat = true

'''

def build():
    characters = [
        ("dragon", "Dragon", 0, 38, 720, False, (44, 223, 198, 187)),
        ("knight", "Knight", 1, 38, 650, False, (257, 244, 192, 166)),
        ("nature", "Nature", 2, 38, 600, False, (150, 411, 202, 137)),
        ("light", "Light", 3, 38, 580, False, (12, 499, 222, 211)),
        ("dark", "Dark", 4, 38, 650, False, (240, 542, 225, 168)),
        ("boss", "Chefe da Ilha", 0, 40, 4000, True, (654, 226, 342, 268)),
        ("amphibian", "Anfíbio", 2, 36, 900, False, (602, 501, 193, 212)),
        ("golem", "Golem", 2, 36, 1200, False, (797, 499, 220, 214)),
    ]
    for key, label, element, level, hp, boss, region in characters:
        write(f"data/characters/{key}.tres", f'''[gd_resource type="Resource" script_class="CharacterDefinition" load_steps=2 format=3]
[ext_resource type="Script" path="res://data/definitions/character_definition.gd" id="script"]
[resource]
script = ExtResource("script")
display_name = "{label}"
element = {element}
level = {level}
max_hp = {hp}
is_boss = {str(boss).lower()}
atlas_region = {rect(region)}
''')
    for kind, name in enumerate(CARD_NAMES):
        full_rect = CARDS[KINDS.index(kind)]
        preview_rect = full_rect if kind == 5 else BAG[[0, 1, 2, 3, 4, 6].index(kind)]
        text = f'''[gd_resource type="Resource" script_class="CardDefinition" load_steps=5 format=3]

[ext_resource type="Script" path="res://data/definitions/card_definition.gd" id="script"]
[ext_resource type="Texture2D" path="{ATLAS}" id="atlas"]

'''
        text += atlas_resource("face", full_rect) + atlas_resource("preview", preview_rect)
        text += f'''[resource]
script = ExtResource("script")
kind = {kind}
display_name = "{CARD_LABELS[kind]}"
power = {POWERS[kind]}
artwork = SubResource("face")
preview = SubResource("preview")
'''
        write(f"data/cards/{name}.tres", text)

    write("data/biomes/ilha_digital.tres", f'''[gd_resource type="Resource" script_class="BiomeDefinition" load_steps=4 format=3]
[ext_resource type="Script" path="res://data/definitions/biome_definition.gd" id="script"]
[ext_resource type="Texture2D" path="{ATLAS}" id="atlas"]
{atlas_resource("biome", (0, 112, 1024, 605))}
[resource]
script = ExtResource("script")
display_name = "Ilha Digital"
artwork = SubResource("biome")
''')
    stage = '''[gd_resource type="Resource" script_class="StageDefinition" load_steps=12 format=3]
[ext_resource type="Script" path="res://data/definitions/stage_definition.gd" id="script"]
[ext_resource type="Resource" path="res://data/biomes/ilha_digital.tres" id="biome"]
[ext_resource type="Script" path="res://data/definitions/character_definition.gd" id="character"]
'''
    for key, *_ in characters:
        stage += f'[ext_resource type="Resource" path="res://data/characters/{key}.tres" id="{key}"]\n'
    stage += '''
[resource]
script = ExtResource("script")
biome = ExtResource("biome")
allies = Array[ExtResource("character")]([ExtResource("dragon"), ExtResource("knight"), ExtResource("nature"), ExtResource("light"), ExtResource("dark")])
enemies = Array[ExtResource("character")]([ExtResource("boss"), ExtResource("amphibian"), ExtResource("golem")])
'''
    write("data/stages/ilha_digital.tres", stage)

    write("battle/views/card_view.tscn", '''[gd_scene load_steps=2 format=3]
[ext_resource type="Script" path="res://battle/views/card_view.gd" id="script"]
[node name="CardView" type="Button"]
offset_right = 150.0
offset_bottom = 160.0
focus_mode = 0
flat = true
script = ExtResource("script")
''')

    for name, path, y, height in SECTIONS:
        header = f'''[gd_scene format=3]
[ext_resource type="Script" path="res://{path}.gd" id="script"]
[ext_resource type="Texture2D" path="{ATLAS}" id="atlas"]
'''
        if name == "AttackBoard":
            header += '[ext_resource type="PackedScene" path="res://battle/views/card_view.tscn" id="card"]\n'
        resources = '\n[sub_resource type="StyleBoxEmpty" id="empty"]\n\n' + atlas_resource("panel", (0, y, 1024, height))
        nodes = f'''[node name="{name}" type="Control"]
offset_right = 1024.0
offset_bottom = {float(height)}
mouse_filter = 2
script = ExtResource("script")

[node name="Artwork" type="TextureRect" parent="."]
offset_right = 1024.0
offset_bottom = {float(height)}
mouse_filter = 2
texture = SubResource("panel")
expand_mode = 1
show_behind_parent = true

'''
        if name == "AttackBoard":
            nodes += '[node name="Slots" type="Control" parent="."]\nmouse_filter = 2\n\n'
            for i, r in enumerate(CARDS):
                resources += atlas_resource(f"card_{i}", r)
                x, cy, w, h = r
                nodes += f'''[node name="CardSlot{i+1:02}" parent="Slots" instance=ExtResource("card")]
{offsets((x, cy-y, w, h))}slot_index = {i}
initial_kind = {KINDS[i]}
original_art = SubResource("card_{i}")

'''
        elif name == "BagPreview":
            nodes += '[node name="Cards" type="Control" parent="."]\nmouse_filter = 2\n\n'
            for i, r in enumerate(BAG):
                resources += atlas_resource(f"preview_{i}", r)
                x, cy, w, h = r
                nodes += f'''[node name="Next{i+1:02}" type="TextureRect" parent="Cards"]
{offsets((x, cy-y, w, h))}mouse_filter = 2
texture = SubResource("preview_{i}")
expand_mode = 1

'''
        elif name == "Battlefield":
            nodes += '[node name="Allies" type="Control" parent="."]\nmouse_filter = 2\n\n'
            allies = [(44, 223, 198, 187), (257, 244, 192, 166), (150, 411, 202, 137), (12, 499, 222, 211), (240, 542, 225, 168)]
            for i, (x, cy, w, h) in enumerate(allies):
                nodes += button(f"AllySlot{i+1:02}", "Allies", (x, cy-y, w, h))
            nodes += '[node name="Enemies" type="Control" parent="."]\nmouse_filter = 2\n\n'
            enemies = [(654, 226, 342, 268), (602, 501, 193, 212), (797, 499, 220, 214)]
            for i, (x, cy, w, h) in enumerate(enemies):
                nodes += button(f"EnemySlot{i+1:02}", "Enemies", (x, cy-y, w, h))
            nodes += '[node name="EnemySlot04" type="Control" parent="Enemies"]\nvisible = false\nmouse_filter = 2\n\n'
            nodes += button("Leader", ".", (151, 193-y, 61, 51))
        elif name == "BottomNavigation":
            nodes += '[node name="Buttons" type="Control" parent="."]\nmouse_filter = 2\n\n'
            for i, destination in enumerate(["Equipe", "Invocacao", "Loja", "Fases"]):
                nodes += button(destination, "Buttons", (6 + i*256, 9, 246, 166))
        write(path + ".tscn", header + resources + nodes)

    text = '[gd_scene format=3]\n[ext_resource type="Script" path="res://battle/battle_screen.gd" id="screen"]\n[ext_resource type="Script" path="res://battle/battle_controller.gd" id="controller"]\n'
    for name, path, _, _ in SECTIONS:
        text += f'[ext_resource type="PackedScene" path="res://{path}.tscn" id="{name}"]\n'
    text += '''
[node name="BattleScreen" type="Control"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
script = ExtResource("screen")

[node name="BattleController" type="Node" parent="."]
script = ExtResource("controller")
'''
    for name, _, y, height in SECTIONS:
        text += f'\n[node name="{name}" parent="." instance=ExtResource("{name}")]\n' + offsets((0, y, 1024, height))
    write("battle/battle_screen.tscn", text)

if __name__ == "__main__":
    build()
    print("Cenas e 7 cartas geradas. PNG original inalterado.")
