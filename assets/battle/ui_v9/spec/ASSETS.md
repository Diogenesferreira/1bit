# Manifesto de assets — o que existe, tamanho de origem e escalas legais

**Regra de ouro**: todo asset só aparece na tela em múltiplo ou divisor **inteiro** do tamanho de origem.
Fora disso o pixel quebra. Importe tudo com `Filter = Nearest`, `Mipmaps = off`, `Fix Alpha Border = on`.

## Cartas — `ui/`
| arquivo | origem | usado a | observação |
|---|---|---|---|
| `card_face_dragon_v1.png` | 78×108 | 78×108 (BAG) · 156×216 (mão) | |
| `card_face_knight_v1.png` | 78×108 | idem | |
| `card_face_nature_v1.png` | 78×108 | idem | |
| `card_face_heal_v1.png` | 78×108 | idem | |
| `card_face_light_v3.png` | 78×108 | idem | **novo** — sol radiante |
| `card_face_dark_v3.png` | 78×108 | idem | **novo** — eclipse (sem caveira) |
| `card_face_wild_v3.png` | 78×108 | idem | **novo** — 5 elementos, inclui knight |
| `card_face_*_v2.png` | 156×216 | — | variante não usada |

## Selos de personagem (moldura 1A) — `seals_1a/`
| arquivo | origem | usado a |
|---|---|---|
| `seal_1a_<el>_empty.png` | 330×330 | 165×165 |
| `seal_1a_<el>_full.png` | 330×330 | 165×165 (referência do arco cheio) |
| `seal_1a_<el>_charge_sheet.png` | 330×2970 (9 quadros de 330) | quadro a 165×165 |

`<el>` = dragon · knight · nature · light · dark. Janela da foto: 258×198 em (36, 30) no asset;
em tela (165) vira 129×99 em (18, 15).

## Inimigo — `enemy/`
| arquivo | origem | escalas legais |
|---|---|---|
| `enemy_turn_plate_<el>_v1.png` | 384×144 | 384 · 192 · 128 · 96 |
| `enemy_hp_well_v1.png` | 384×144 | idem |
| `enemy_hp_fill_v1.png` | 384×144 | idem |
| `enemy_label_turn_v1.png` | 144×48 | 144 · 72 · 48 · 36 |
| `enemy_digits_sheet_v1.png` | 420×48 (10 células 42×48) | célula 42×48 · 21×24 · 14×16 |

## HUD e rótulos — `ui/`
| arquivo | origem | usado a |
|---|---|---|
| `ui_font_sheet_v1.png` | 1440×48 (40 células 36×48) | **fonte bitmap**: gere qualquer rótulo em runtime |
| `val_account.png` | 288×48 | h 17 · placeholder do nome da conta |
| `lbl_lv.png` / `val_lv.png` | 72×48 / 72×48 | h 11 / h 12 |
| `val_coin.png` | 144×48 | h 14 |
| `val_gem.png` | 72×48 | h 14 |
| `val_energy.png` | — | h 16 |
| `val_xp.png` / `lbl_xp.png` | — | h 11 |
| `lbl_stage.png` / `val_stage.png` | 180×48 / 108×48 | h 11 / h 12 |
| `lbl_boss.png` | 144×48 | h 10 |
| `lbl_hp.png` / `val_hp_curr.png` | 78×48 / 324×48 | h 12 / h 15 |
| `lbl_party.png` / `lbl_hand.png` / `lbl_bag.png` / `lbl_next.png` | — | h 18 / 18 / 16 / 14 |

**Prefira gerar os números em runtime pela fonte bitmap** (`godot/BitmapFontLabel.gd`); os `val_*.png`
são só o estado do mock. Ordem das células da fonte:
`0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ/-:` + espaço (índice 39). Avanço 36 px na origem.

## Personagens — `char/`
`char_<id>_<el>_battle_v1.png` 222×237 · `_idle_v1.png` 444×237 (2 quadros) · `_icon_v1.png` 72×72.

## Cenário
Ainda **não existe** arte de palco no pacote — o mock usa um slot de imagem. Entregue
`backdrops/stage_<nome>.png` em 888×558 (ou múltiplo inteiro: 1776×1116) e coloque em `cover`.
