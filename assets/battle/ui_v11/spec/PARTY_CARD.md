# Carta de personagem (faixa do party) — modelo final (02/09/2026)

**Este é o modelo atual do party.** Substitui os selos quadrados 1A e também a tentativa hexagonal
(`PARTY_HEX.md` fica como histórico; onde divergir, vale este arquivo).

## Faixa
| item | valor |
|---|---|
| largura | 890 (coluna de conteúdo) · altura **252** |
| fundo | `#121311` + filetes 1 px `rgba(201,192,168,.22)` em cima/embaixo |
| gravura de fundo | `niche/party_arc.png` (296×76 lógico a 3× = 888×228) em **alpha .70** |
| padding | 22 topo / 16 base · 16 lateral · slots com `space-between` · alinhamento `flex-end` |
| ordem | 2 – 1 – 2 (líder no centro) |

## Carta de aliado — 152 × 188
Camadas, de baixo para cima:

1. **corpo**: `#0d0e0c`, contorno externo **2 px `#14140f`**;
2. **moldura interna**: 2 px na **cor do elemento**, `inset: 2px`;
3. **cena de classe**: `card_party/scene_<el>.png` (50×46 lógico a 3× = **150×138**), `no-repeat top center`;
4. **campo pontilhado**: `card_party/field_<el>.png` (8×8 lógico a 3× = 24×24), `repeat`, atrás da cena;
5. **personagem**: `char80/char_<el>.png` a **2×** do lógico, ancorado na base da área de arte (altura da área = 136);
6. **selo do elemento**: 30×30 em `left:-3, top:-3`, fundo `#0d0e0c`, borda 2 px da cor do elemento,
   com `card_party/sym_<el>.png` a 26×26 — **é o mesmo símbolo das cartas do jogo** (extraído de `ui/card_face_<el>`);
7. **barra de skill**: `left:9, right:9, bottom:31`, altura 10, calha `#121211` + borda 1 px `rgba(201,192,168,.45)`,
   **8 pastilhas** de (largura útil − 8)/8 na cor clara do elemento; vazia = `#1a1a16`;
8. **placa de nome**: `inset 2px` na base, altura 24, `#0d0e0c`, filete superior na cor do elemento,
   contendo o **chip de nível** e o **nome**.

### Chip de nível (0–99)
Caixa na cor do elemento, **largura mínima 30 px**, altura 18, `padding: 0 4px`,
conteúdo alinhado à direita: 1 ou 2 dígitos de 12×14 do atlas `enemy_digits_sheet_v1.png`
(célula de origem 42×48). Nível ≥ 10 usa dois dígitos sem empurrar o nome — a largura já está reservada.

### Nome
Montado letra a letra da fonte bitmap `ui/ui_font_sheet_v1.png` a **altura 16** (célula 12×16,
folha escalada para 480 px). Ordem das células: `0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ/-:`.
No Godot use `BitmapFontLabel.gd` com `glyph_height = 16`.

## Carta do líder — 176 × 214
Igual à do aliado, com:
- moldura interna e filetes em **ouro `#c9a842`** (em vez da cor do elemento);
- personagem **15 % maior** (`round(w*1.15)`), cena de fundo a **4×** (200×184);
- barra de skill com **12 px** de altura e borda dourada;
- `crown_leader.png` (52×24) encaixada no topo, `top:-15`, centralizada;
- glow `drop-shadow(0 0 9px rgba(201,168,66,.45))` — no Godot, `CanvasGroup` + glow, nunca pintado no PNG.

## Personagens (arte final)
| arquivo | lógico | 2× (aliado) | 2,3× (líder) |
|---|---|---|---|
| `char80/char_dragon.png` | 57×54 | 114×108 | 131×124 |
| `char80/char_knight.png` | 44×58 | 88×116 | 101×133 |
| `char80/char_nature.png` | 60×58 | 120×116 | 138×133 |
| `char80/char_light.png` | 54×56 | 108×112 | 124×129 |
| `char80/char_dark.png` | 52×54 | 104×108 | 120×124 |
| `char80/char_heal.png` | 46×54 | 92×108 | — (reserva do elemento cura) |

Os PNGs estão gravados a **4× do lógico** (grade original 80×80, fundo removido). Para exibir a 2×,
use `TextureRect` com `STRETCH_KEEP_ASPECT` e tamanho = lógico × 2 — sempre **múltiplo inteiro**.

## Migração: selo quadrado → carta
| antes (selo 1A) | agora (carta) |
|---|---|
| `seal_sq_a_<el>_empty.png` 165×165 | corpo da carta + moldura na cor do elemento (sem asset de moldura) |
| `seal_sq_a_<el>_charge_sheet.png` (9 quadros) | **barra de 8 pastilhas** — troque `set_charge(n)` por `set_charge(n)` que pinta n pastilhas |
| janela de foto 129×99 | área de arte 148×136, personagem ancorado na base |
| marcador de líder (3 blocos) | coroa `crown_leader.png` + moldura dourada |
| marcador de convidado (losango) | losango 10×10 `#c9c0a8` vazado no canto superior direito da carta |
| sem nome / nível | placa de nome com chip de nível 0–99 |

Passo a passo no Godot:
1. crie `PartyCard.tscn` a partir de `godot/PartyCard.gd` (uma cena, cinco instâncias);
2. na faixa do party, apague as instâncias de `PartySeal` e coloque 5 `PartyCard` num `HBoxContainer`
   com `alignment = center`, `separation` calculada por `space-between` (ou um `Control` com âncoras);
3. o slot central recebe `leader = true`;
4. ligue `set_charge(0..8)`, `set_level(0..99)`, `set_hero_name(String)` e `set_element(String)`;
5. os selos 1A continuam válidos nas telas de coleção/montagem de time.

## Variáveis por personagem (o que o jogo precisa alimentar)
```
element : "dragon" | "knight" | "nature" | "light" | "dark" | "heal"
hero_name : String (até 7 letras cabem sem apertar; A–Z e 0–9)
level : int 0..99
charge : int 0..8          # pastilhas acesas da barra de skill
leader : bool              # moldura dourada + coroa + carta maior
guest : bool               # losango vazado no canto
```
