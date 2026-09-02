# Barra de LIFE do jogador — contrato de layout

## Anatomia

Linha horizontal com altura de 24 px e quatro blocos separados por `GAP = 14`:

```text
[coração 27x24]  14  [HP]  14  [calha elástica]  14  [valor atual/máximo]
```

Somente a calha muda de largura. O coração, o rótulo e o valor permanecem em
tamanho nativo. Para `row_width`, a geometria é:

```text
well_x = 27 + 14 + 19 + 14 = 74
well_w = row_width - well_x - 14 - value_w
```

## Árvore normativa

```text
PlayerLifeBar        Control row_width x 24, PRESET_TOP_LEFT
├── heart            TextureRect (0,0,27,24)
├── label HP         BitmapFontLabel, glyph 24, tracking 2, alpha .85
├── WELL             Control (74,0,well_w,24), clip_contents = true
│   ├── field        TextureRect (0,0,well_w,24), STRETCH_TILE
│   ├── fill         TextureRect (3,3,fill_w,18), STRETCH_TILE
│   ├── tip          ColorRect (3+fill_w,3,3,18), #2a2620
│   └── border       borda interna 3px, #c9c0a8
└── value            BitmapFontLabel, glyph 24, tracking 2, ancorado à direita
```

`fill` e `tip` usam coordenadas de `WELL`. Todos os demais blocos usam
coordenadas de `PlayerLifeBar`.

## Comportamento

- Área útil: `well_w - 6`, com origem `(3,3)` e altura `18`.
- O fill cresce da esquerda pela largura, nunca por escala.
- `fill_w = round(well_inner * hp_current / hp_max)`.
- Fill vazio oculta fill e ponta; fill completo oculta somente a ponta.
- Fundo e preenchimento usam tiles 24×24 e 24×18 com filtro `Nearest`.
- Rótulo e valor usam o atlas em 24 px para preservar leitura no celular.
- O valor é texto bitmap em runtime, fica preso à margem direita e sua reserva
  é calculada a partir de `hp_max`; `9999/9999` cabe sem invadir a calha.
- Dano e cura animam largura e valor juntos em 420 ms, cubic ease-out.

Na tela de batalha 940×1685, o componente fica em `(31,1605)` com largura
`878`, centralizado entre o divisor da mão e a borda inferior da interface.
