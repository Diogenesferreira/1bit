# Posicionamento e encaixe — contrato de layout

Este contrato substitui medidas implícitas das versões anteriores. A arte já está
correta; a integração deve preservar hierarquia, espaço de coordenadas, recorte
e ancoragem.

## Regras

1. Toda medida pertence ao espaço do nó-pai declarado.
2. A árvore de nós é normativa.
3. `FRAME` é o único nó com `clip_contents = true`.
4. O personagem é ancorado pelos pés: `y = 136 - altura`.
5. O tamanho de desenho é tabelado por elemento, nunca calculado por escala.

## Árvore normativa

```text
PartyCard            Control  152x188   posição manual, PRESET_TOP_LEFT
├── bg               ColorRect (0,0,152,188)
├── border_out       borda 2px
├── FRAME            Control  (2,2) 148x184   clip_contents = true
│   ├── field        TextureRect (0,0,148,184)  STRETCH_TILE
│   ├── scene        TextureRect (-1,0,150,138) STRETCH_SCALE
│   ├── hero         TextureRect (x,136-h,w,h)
│   └── border_in    borda 2px na cor do elemento
├── seal_bg          ColorRect (-3,-3,30,30)
├── seal_border      borda 2px na cor do elemento
├── seal_sym         TextureRect (-1,-1,26,26)
├── skill_bar        (9,147,134,10), 8 pips de 14x6, passo 16
├── name_plate       (2,162,148,24)
│   ├── level_chip   offset (6,3)
│   └── name_label   offset (43,4), glyph 16
└── leader_plaque    (38,-14,117,22), apenas no líder
```

Elementos internos são filhos de `FRAME`. Elementos que sangram para fora ou
precisam sobrepor a moldura são filhos de `PartyCard`.

## Desenho do personagem

Espaço: `FRAME`. Baseline: `136`. Centro horizontal:
`x = round((148 - w) / 2)`.

| elemento | desenho | x | y |
| --- | ---: | ---: | ---: |
| dragon | 114×108 | 17 | 28 |
| knight | 88×116 | 30 | 20 |
| nature | 112×108 | 18 | 28 |
| light | 108×112 | 20 | 24 |
| dark | 104×108 | 22 | 28 |
| heal | 96×108 | 26 | 28 |

Os PNGs são maiores que o desenho final. Use `STRETCH_SCALE`, filtro `Nearest`
e `EXPAND_IGNORE_SIZE`. No Godot 4.7, configure `expand_mode` antes de atribuir a
textura para não herdar o tamanho mínimo do PNG.

## Integração

- `FRAME.clip_contents` deve permanecer habilitado.
- Nenhum filho de `FRAME` pode usar coordenadas de `PartyCard`, ou vice-versa.
- O card do líder mede os mesmos 152×188 dos demais.
- O anel interno sempre usa a cor do elemento; dourado pertence à placa.
- O card não deve ser filho direto de `HBoxContainer` ou `GridContainer`. Use um
  wrapper `Control` 152×188 quando a faixa for gerenciada por container.
- Fontes e texturas de UI usam filtro `Nearest`, sem mipmaps.
