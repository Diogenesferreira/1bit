# Barra de LIFE do jogador — contrato de layout

Mesmo formato de `POSICIONAMENTO.md`: árvore de nós, espaço declarado, tabelas
literais, regra de ancoragem. Implementado em `godot/PlayerLifeBar.gd`.

## 1. Anatomia

Uma linha horizontal de quatro blocos, alinhados verticalmente ao centro,
separados por `GAP = 14`. Altura da linha = altura da calha = **24**.

```
[coração 27x24]  14  [HP]  14  [ ============ calha, o resto ============ ]  14  [1840/2400]
```

O terceiro bloco é elástico (é o `flex: 1` do HTML). Os outros três têm largura
fixa. Portanto:

```
well_x = 27 + 14 + 19 + 14            = 74
well_w = row_width - well_x - 14 - value_w
```

`row_width` é a largura útil do container (no alvo de 500px de device com padding
16, `row_width = 468`). Exemplo com o valor `1840/2400` (9 glifos → 116):

```
value_w = 9 * 13 - 1 = 116
well_w  = 468 - 74 - 14 - 116 = 264
```

**A calha é o único bloco que muda de largura.** Se o container mudar, recalcule
`well_w` — nunca escale a barra.

## 2. Árvore de nós (normativa)

```
PlayerLifeBar        Control  row_width x 24   PRESET_TOP_LEFT
├── heart            TextureRect (0,0,27,24)              hp_heart_card.png
├── label "HP"       BitmapFontLabel (41,6)  glyph 12, tracking 1, alpha .65
├── WELL             Control (74,0) well_w x 24   clip_contents = TRUE
│   ├── field        TextureRect (0,0,well_w,24)   STRETCH_TILE   hp_tile_field.png
│   ├── fill         TextureRect (3,3,fill_w,18)   STRETCH_TILE   hp_tile_fill.png
│   ├── tip          ColorRect   (3+fill_w,3,3,18)                #2a2620
│   └── border       4x ColorRect  w=3                             #c9c0a8
└── value            BitmapFontLabel (row_width-value_w, 4)  glyph 16, tracking 1
```

Espaços: `heart`, `label`, `WELL` e `value` em espaço de **PlayerLifeBar**;
`field`, `fill`, `tip`, `border` em espaço de **WELL**.

## 3. A calha e o fill

| medida | valor |
| --- | --- |
| borda da calha | 3px `#c9c0a8`, desenhada **por dentro** (`box-sizing: border-box`) |
| fundo da calha | `#14140f` + `hp_tile_field.png` em tile de 24 × 24 |
| área útil | `well_inner = well_w - 6`, altura 18, origem (3, 3) |
| fill | `hp_tile_fill.png` em tile de 24 × 18 |
| ponta do fill | filete `#2a2620` de 3 × 18 imediatamente à direita do fill |

Regra de ancoragem: **o fill cresce da esquerda mudando `size.x`**, nunca por
`scale` e nunca centralizado. `fill_w = round(well_inner * hp_current / hp_max)`.

Casos-limite: `fill_w == 0` → esconda o fill e a ponta; `fill_w == well_inner`
→ esconda só a ponta (senão ela cobre a borda direita).

Os dois tiles são **tiles**, não `STRETCH_SCALE` — esticar deforma o padrão de
dither. Célula do fundo 24 × 24, célula do fill 24 × 18: são diferentes de
propósito, o fill é mais baixo porque vive dentro da borda.

## 4. Texto

Nada de PNG estático aqui. `lbl_hp.png` (78 × 48) e `val_hp_curr.png` (324 × 48)
saíram: eram reescalados em fração e borravam, e o valor muda em runtime.

| bloco | fonte | glyph_height | tracking | conteúdo |
| --- | --- | --- | --- | --- |
| rótulo | `ui/font_1x_v1.png` | 12 | 1 | `HP`, alpha .65 |
| valor | `ui/font_1x_v1.png` | 16 | 1 | `%d/%d` |

Ordem dos glifos: `0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ/-:` — a barra existe no
índice 36. Avanço por glifo = `glyph_height * 12 / 16 + tracking`.

O valor é **ancorado à direita**: `x = row_width - value_w`. Cresce para a
esquerda quando o número fica maior, para não empurrar a calha.

## 5. Animação

| evento | duração | curva | o que muda |
| --- | --- | --- | --- |
| dreno de dano | 420 ms | ease-out cubic | `fill_w` e o texto do valor juntos |
| cura | 420 ms | ease-out cubic | idem, crescendo |
| set imediato | 0 | — | `set_hp()`, para carregar estado |

`drain_to(v)` faz as duas coisas de uma vez via `tween_method(_apply, ...)`, então
número e barra nunca ficam fora de sincronia. Não anime dois tweens separados.

## 6. Checklist de integração

- [ ] `WELL.clip_contents == true`
- [ ] `fill` e `tip` são filhos de `WELL`, em coordenadas de WELL
- [ ] Bordas desenhadas por dentro (a calha não fica 6px mais larga)
- [ ] Tiles com `STRETCH_TILE`, não `STRETCH_SCALE`
- [ ] `Filter = Nearest` nas três texturas e na folha de fonte
- [ ] Valor ancorado à direita, não à esquerda
- [ ] `fill_w` recalculado a partir de `well_inner`, nunca de `well_w`
- [ ] A linha **não** é filha direta de um `HBoxContainer` que sobrescreva
      `position` — se for, embrulhe em `Control` com `custom_minimum_size`
- [ ] `hp_tile_field` e `hp_tile_fill` importados sem mipmaps

## 7. Arquivos

```
export_godot/
  godot/PlayerLifeBar.gd       implementação deste contrato
  godot/BitmapFontLabel.gd     agora com `tracking`
  ui/hp_heart_card.png         27x24
  ui/hp_tile_field.png         24x24  (tile do fundo)
  ui/hp_tile_fill.png          24x18  (tile do preenchimento)
  ui/font_1x_v1.png            480x16, célula 12x16
```

`ui/lbl_hp.png`, `ui/val_hp.png`, `ui/val_hp_curr.png` e `ui/val_hp_9999.png`
continuam no pacote por histórico, mas **não são mais usados**.
