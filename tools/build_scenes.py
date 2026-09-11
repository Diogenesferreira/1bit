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
    target.write_text(text.rstrip() + "\n", encoding="utf-8", newline="\n")

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

WHITE = "1, 1, 1, 1"
GOLD = "1, 0.89, 0.38, 1"
BLUE = "0.3, 0.8, 1, 1"
GREEN = "0.13, 0.84, 0.2, 1"
RED = "0.93, 0.14, 0.22, 1"

def text_fields(section):
    if section == "AccountHUD":
        return [
            ("PlayerName", (136, 13, 110, 36), "JINSA", 28, WHITE),
            ("Level", (181, 51, 63, 36), "38", 27, GOLD),
            ("XPValue", (323, 73, 174, 24), "6120 / 12000", 19, BLUE),
            ("Money", (597, 28, 102, 41), "154200", 24, GOLD),
            ("Tickets", (778, 29, 42, 42), "50", 27, BLUE),
            ("Energy", (896, 29, 100, 28), "92/100", 24, BLUE),
        ]
    if section == "CombatHUD":
        return [
            ("PartyHP", (281, 761, 133, 24), "2840 / 3200", 20, WHITE),
            ("EnemyHP", (807, 761, 147, 24), "1850 / 4000", 20, WHITE),
            ("Target", (646, 732, 163, 25), "CHEFE HP", 19, RED),
            ("Round", (464, 754, 109, 39), "3 / 3", 30, WHITE),
        ]
    if section == "AttackBoard":
        return [("Message", (391, 942, 610, 30), "COMBINE CARTAS, LIBERE O PODER DOS SEUS MONSTROS!", 17, BLUE)]
    if section == "Battlefield":
        allies = [(79, 371, 63, 22), (303, 370, 63, 22), (218, 506, 63, 22), (66, 665, 63, 23), (304, 665, 63, 23)]
        enemies = [(754, 433, 66, 23), (650, 665, 63, 23), (867, 665, 63, 23)]
        return [(f"AllyLevel{i}", r, "LV 38", 18, WHITE) for i, r in enumerate(allies)] + [(f"EnemyLevel{i}", r, "LV 40" if i == 0 else "LV 36", 18, WHITE) for i, r in enumerate(enemies)]
    return []

def gauge_fields(section):
    if section == "AccountHUD":
        return [("XPBar", (251, 57, 227, 10), 6120, 12000, BLUE), ("EnergyBar", (855, 65, 140, 10), 92, 100, GREEN)]
    if section == "CombatHUD":
        return [("PartyBar", (88, 764, 186, 14), 2840, 3200, GREEN), ("EnemyBar", (646, 764, 155, 14), 1850, 4000, RED)]
    if section == "Battlefield":
        allies = [(123, 398, 84, 10), (341, 398, 84, 10), (250, 531, 84, 10), (112, 694, 84, 10), (346, 694, 84, 10)]
        enemies = [(749, 474, 154, 10), (637, 694, 134, 10), (852, 694, 132, 10)]
        return [(f"Skill{i}", r, 75, 100, BLUE) for i, r in enumerate(allies)] + [(f"EnemyHP{i}", r, [1850, 900, 1200][i], [4000, 900, 1200][i], RED) for i, r in enumerate(enemies)]
    return []

def decorative_fields(section):
    if section == "AccountHUD":
        return [("Avatar", (8, 2, 111, 102)), ("CoinIcon", (555, 31, 36, 41)), ("TicketIcon", (731, 28, 47, 47)), ("EnergyIcon", (852, 29, 34, 34))]
    if section == "Battlefield":
        allies = [(39, 365, 40, 43), (260, 365, 40, 40), (170, 501, 42, 38), (23, 665, 41, 38), (258, 665, 41, 38)]
        enemies = [(705, 435, 43, 38), (603, 665, 43, 38), (820, 665, 41, 38)]
        return [(f"AllyElement{i}", r) for i, r in enumerate(allies)] + [(f"EnemyElement{i}", r) for i, r in enumerate(enemies)] + [("LeaderCrown", (164, 193, 39, 38))]
    return []

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
printed_power = {POWERS[kind]}
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

    write("battle/views/card_view.tscn", '''[gd_scene format=3]
[ext_resource type="Script" path="res://battle/views/card_view.gd" id="script"]
[ext_resource type="Script" path="res://ui/atlas_panel.gd" id="panel"]
[ext_resource type="PackedScene" path="res://ui/atlas_value.tscn" id="value"]
[sub_resource type="StyleBoxFlat" id="selection"]
bg_color = Color(0, 0, 0, 0)
border_width_left = 4
border_width_right = 4
border_width_top = 4
border_width_bottom = 4
border_color = Color(0.91, 0.99, 1, 1)
draw_center = false
[node name="CardView" type="Button"]
offset_right = 150.0
offset_bottom = 160.0
focus_mode = 0
flat = true
script = ExtResource("script")

[node name="Face" type="TextureRect" parent="."]
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
mouse_filter = 2
expand_mode = 1
script = ExtResource("panel")

[node name="Number" parent="." instance=ExtResource("value")]

[node name="Selection" type="Panel" parent="."]
visible = false
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
offset_left = 3.0
offset_top = 3.0
offset_right = -3.0
offset_bottom = -3.0
mouse_filter = 2
theme_override_styles/panel = SubResource("selection")
''')

    for name, path, y, height in SECTIONS:
        header = f'''[gd_scene format=3]
[ext_resource type="Script" path="res://{path}.gd" id="script"]
[ext_resource type="Texture2D" path="{ATLAS}" id="atlas"]
'''
        if name in ("AttackBoard", "BagPreview"):
            header += '[ext_resource type="PackedScene" path="res://battle/views/card_view.tscn" id="card"]\n'
        header += '[ext_resource type="Script" path="res://ui/atlas_panel.gd" id="panel_script"]\n'
        header += '[ext_resource type="PackedScene" path="res://ui/atlas_value.tscn" id="value"]\n'
        header += '[ext_resource type="PackedScene" path="res://ui/atlas_gauge.tscn" id="gauge"]\n'
        fields = text_fields(name)
        gauges = gauge_fields(name)
        decorations = decorative_fields(name)
        clear_regions = [field[1] for field in fields + gauges + decorations]
        if name == "AttackBoard":
            clear_regions += CARDS
        if name == "BagPreview":
            clear_regions += BAG
        if name == "BottomNavigation":
            clear_regions += [(6 + i*256, 1359, 246, 166) for i in range(4)]
        clear_property = "[" + ", ".join(rect(r) for r in clear_regions) + "]"
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
script = ExtResource("panel_script")
clear_regions = Array[Rect2]({clear_property})

'''
        nodes += '[node name="Fields" type="Control" parent="."]\nmouse_filter = 2\n\n'
        for field_name, r, reference, font_size, tint in fields:
            x, cy, w, h = r
            nodes += f'''[node name="{field_name}" parent="Fields" instance=ExtResource("value")]
{offsets((x, cy-y, w, h))}source_region = {rect(r)}
reference_text = "{reference}"
font_size = {font_size}
font_color = Color({tint})

'''
        for field_name, r, current, maximum, tint in gauges:
            x, cy, w, h = r
            nodes += f'''[node name="{field_name}" parent="Fields" instance=ExtResource("gauge")]
{offsets((x, cy-y, w, h))}source_region = {rect(r)}
reference_value = {float(current)}
reference_max = {float(maximum)}
fill_color = Color({tint})

'''
        for part_name, r in decorations:
            resources += atlas_resource(f"part_{part_name}", r)
            x, cy, w, h = r
            nodes += f'''[node name="{part_name}" type="TextureRect" parent="Fields"]
{offsets((x, cy-y, w, h))}mouse_filter = 2
texture = SubResource("part_{part_name}")

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
                nodes += f'''[node name="Next{i+1:02}" parent="Cards" instance=ExtResource("card")]
{offsets((x, cy-y, w, h))}mouse_filter = 2
original_art = SubResource("preview_{i}")
initial_kind = {[0, 1, 2, 3, 4, 6][i]}
is_preview = true
disabled = true

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
                resources += atlas_resource(f"navigation_{i}", (6 + i*256, 1359, 246, 166))
                nodes += f'''[node name="Artwork" type="TextureRect" parent="Buttons/{destination}"]
offset_right = 246.0
offset_bottom = 166.0
mouse_filter = 2
texture = SubResource("navigation_{i}")

'''
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
