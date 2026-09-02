# Faixa de party — modelo final (02/09/2026)

Substitui a seção "card do líder" de `PARTY_HERO.md`. O que mudou: **todos os cinco
cards têm o mesmo tamanho**, a coroa saiu e o líder é marcado por uma placa
`LEADER` no topo, ancorada à direita.

## 1. Card (idêntico para os cinco slots)

| medida | valor (px lógicos, 1:1 com a tela) |
| --- | --- |
| card | 152 × 188 |
| contorno externo | 2px `#14140f` |
| corpo | `#0d0e0c` |
| moldura interna | inset 2px, borda 2px na cor do anel |
| anel (border interna) | líder `#c9a842` · demais = cor do elemento |
| cena de fundo | 150 × 138, topo, centralizada |
| padrão (field) | tile 24 × 24, repeat |
| sprite do herói | lógico × 2, base em `y = 136` |
| barra de skill | `left 9, right 9, bottom 31`, altura 10, 8 pastilhas de 14 × 6, gap 2 |
| placa de nome | `left 2, right 2, bottom 2`, altura 24, filete 1px no topo |
| footer interno | `gap 7`, `padding 0 6` |

Distinção do líder **sem mudar tamanho**: anel dourado + `drop_shadow` cyan/dourado
(`filter: drop-shadow(0 0 8px rgba(201,168,66,.4))` no HTML → em Godot, um
`CanvasItem` com material de glow ou um `NinePatch` de halo atrás do card) + a placa.

## 2. Selo do elemento (canto superior esquerdo) — inalterado

```
rect(-3, -3, 30, 30)   corpo #0d0e0c, borda 2px na cor do anel
sym_<elem>.png em (-1, -1, 26, 26)
```

## 3. Placa LEADER (novo)

Ancorada à **direita**, espelhando o selo do elemento. Isso é o ponto crítico:
centralizada ela cobria o selo.

```
w    = 117           # 6 glifos ×12 + 5 gaps ×3 + 2 pips ×4 + padding 2×8
x    = card.w + 3 - w = 38
y    = -14
h    = 22
corpo  #0d0e0c    borda 1px #c9a842
pip esquerdo  (x+8,  -5, 4, 4)  #c9a842
pip direito   (x+w-12, -5, 4, 4)  #c9a842
texto "LEADER"  glyph_height 16, começa em (x+16, -11)
z-index acima do card
```

`PartyCard.gd :: _build_leader_plaque()` implementa exatamente isso.

## 4. Chip de nível

Voltou ao formato preenchido (mais legível que a variante de plate escuro):

```
min-width 30, height 18, padding 0 4, alinhado à direita
fundo = cor do elemento (líder: #c9a842)
dígitos 12 × 14 de ui/digits_1x_v1.png (folha 1:1, 120 × 14, célula 12 × 14)
```

## 5. Folhas de fonte — trocar pelas versões 1:1

O borrado que você via vinha de reamostragem fracionária: as folhas antigas
tinham célula de 36 × 48 e 42 × 48 e eram reduzidas para 12 × 16 / 12 × 14 pelo
renderizador. As novas têm **1 px de textura = 1 px de tela**, alpha em limiar e
cores travadas na paleta.

| usar | em vez de | célula | folha |
| --- | --- | --- | --- |
| `ui/font_1x_v1.png` | `ui/ui_font_sheet_v1.png` | 12 × 16 | 480 × 16 |
| `ui/digits_1x_v1.png` | `enemy/enemy_digits_sheet_v1.png` | 12 × 14 | 120 × 14 |
| `ui/digits_card_1x_v1.png` | — (numerais das cartas) | 19 × 21 | 190 × 21 |

Ordem dos glifos da fonte: `0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ/-:`
Dígitos: `0123456789`.

Em **todo** `TextureRect`: `texture_filter = TEXTURE_FILTER_NEAREST`. Se precisar
de 2×/3× para telas densas, gere múltiplos inteiros a partir destas 1:1 —
nunca reduza as folhas antigas.

## 6. Arquivos deste pacote

```
export_godot/
  godot/PartyCard.gd          ← reescrito: tamanho único + _build_leader_plaque()
  godot/BitmapFontLabel.gd    ← aponta para font_1x_v1.png, CELL 12x16
  ui/font_1x_v1.png  digits_1x_v1.png  digits_card_1x_v1.png
  card_party/{field,scene,sym}_<elem>.png
  char80/char_<elem>.png       heróis do card (lógico ×2)
  char32/hero_<elem>.png       chassi 32×40 — ver MIGRACAO_HEROIS.md
  html/UI Batalha 1bit.dc.html referência viva (abre no navegador)
```

`card_party/crown_leader.png` fica no pacote mas **não é mais usado**.
