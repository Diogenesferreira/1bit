# Como especificar posicionamento e encaixe (contrato de layout)

Escrito depois da primeira integração no Godot, em que os heróis vazaram para
fora do card e cobriram a placa de nome. **A arte estava certa; o contrato de
layout é que estava implícito.** Este arquivo é o formato a usar de agora em
diante para qualquer parte da UI.

## 0. Diagnóstico do que deu errado

Três causas, todas de descrição e não de arte:

1. **Nenhum nó clipava.** No HTML a moldura interna tem `overflow: hidden`. Isso
   nunca foi dito na spec, então no Godot o sprite do herói foi adicionado como
   irmão dos outros elementos, sem `clip_contents` — e o que passava do limite
   simplesmente apareceu em cima da placa de nome e fora do card.
2. **Dois espaços de coordenadas misturados.** Alguns valores da spec eram
   relativos ao card (152×188) e outros à moldura interna (148×184, deslocada 2px).
   Um erro de 2px por nível, acumulado em três níveis, é o desalinhamento visível.
3. **Tamanho do herói por multiplicador.** A spec dizia "lógico × 2". Mas o
   lógico de cada sprite é diferente e nem todos fecham em ×2 — nature fecha em
   112×108, não em 120×116. Um sprite maior que a janela de arte, ancorado pelo
   topo, empurra os pés para fora.

## 1. As cinco regras

**R1 — Um espaço por nó, declarado.** Toda medida vem acompanhada do nó-pai.
`(9, 147, 134, 10) em CARD` e `(0, 0, 148, 184) em FRAME` são coisas diferentes.
Nunca escreva um rect sem dizer o espaço.

**R2 — A hierarquia é parte da spec.** A árvore de nós é normativa, não sugestão:
quem é filho de quem determina o offset e o clip. Se a spec não desenha a árvore,
ela não especificou o layout.

**R3 — Quem clipa, clipa explicitamente.** Todo container com conteúdo que pode
transbordar leva `clip_contents = true` marcado na spec. No nosso card existe
exatamente **um** nó que clipa: `FRAME`.

**R4 — Arte de personagem é ancorada pelos PÉS.** Nunca pelo topo, nunca pelo
centro. A spec dá uma `baseline` (y dos pés) e o desenho é
`y = baseline - altura_de_desenho`. É o que o `align-items: flex-end` do HTML faz.
Assim um sprite mais alto cresce para cima, dentro da janela, em vez de afundar.

**R5 — Tamanhos de desenho são tabelados, não calculados.** Uma tabela literal
por elemento. Multiplicadores parecem elegantes e mentem em pelo menos um caso.

## 2. Árvore de nós do card (normativa)

```
PartyCard            Control  152x188   pos manual, PRESET_TOP_LEFT
├── bg               ColorRect (0,0,152,188)          #0d0e0c
├── border_out       4x ColorRect  w=2                #14140f
├── FRAME            Control  (2,2) 148x184   clip_contents = TRUE
│   ├── field        TextureRect (0,0,148,184)  STRETCH_TILE   field_<el>.png
│   ├── scene        TextureRect (-1,0,150,138) STRETCH_SCALE  scene_<el>.png
│   ├── hero         TextureRect (cx, 136-h, w, h)             char_<el>.png
│   └── border_in    4x ColorRect  w=2   = cor do elemento
├── seal_bg          ColorRect (-3,-3,30,30)          #0d0e0c      ← sangra, fica no CARD
├── seal_border      4x ColorRect w=2   = cor do elemento
├── seal_sym         TextureRect (-1,-1,26,26)        sym_<el>.png
├── skill_bar        ColorRect (9,147,134,10) + borda 1px + 8 pips (14x6, passo 16)
├── name_plate       ColorRect (2,162,148,24) + filete 1px no topo
│   ├── level_chip   (8,165) min-w 30, h 18
│   └── name_label   (45,166) glyph_height 16
└── leader_plaque    (38,-14) 117x22    só no líder    ← sangra, fica no CARD
```

Regra de bolso: **se o elemento sangra para fora do card ou precisa ficar por
cima da moldura, ele é filho do CARD; todo o resto é filho do FRAME.**

## 3. Tabela de desenho do herói

Espaço: FRAME. `baseline = 136`. `x = round((148 - w) / 2)`. `y = 136 - h`.

| elemento | png (px) | desenho w×h | x | y |
| --- | --- | --- | --- | --- |
| dragon | 228×216 | 114 × 108 | 17 | 28 |
| knight | 176×232 | 88 × 116 | 30 | 20 |
| nature | 240×232 | 112 × 108 | 18 | 28 |
| light | 216×224 | 108 × 112 | 20 | 24 |
| dark | 208×216 | 104 × 108 | 22 | 28 |
| heal | — | 96 × 108 | 26 | 28 |

Os PNGs estão em 4× do lógico; o desenho não é um múltiplo inteiro do PNG e isso
é intencional (a arte foi autorada maior para dar margem). Use `STRETCH_SCALE` +
`TEXTURE_FILTER_NEAREST` e os valores da tabela — não recalcule.

## 4. Zoom da tela

Toda a UI é autorada em px lógicos e ampliada de uma vez só, em **múltiplo
inteiro**. Nada de escalar nós individualmente.

```
Project Settings → Display → Window
  Viewport Width/Height  = resolução lógica do jogo
  Stretch Mode           = viewport
  Stretch Aspect         = keep
Import (todas as texturas de UI)
  Filter = Nearest, Mipmaps = off
```

Se aparecer meio pixel em qualquer borda, o zoom não é inteiro — é a primeira
coisa a checar antes de mexer em coordenada.

## 5. Checklist de integração

- [ ] `FRAME.clip_contents == true`
- [ ] Nenhum filho de `FRAME` usa coordenada de CARD (e vice-versa)
- [ ] Herói posicionado por `y = 136 - h`, com `h` vindo de `CHAR_DRAW`
- [ ] `CHAR_DRAW` conferido contra a tabela da seção 3
- [ ] Card do líder tem **o mesmo** 152×188 dos outros
- [ ] Placa LEADER em `x = 38`, sem cobrir o selo em `(-3,-3)`
- [ ] Anel interno na cor do elemento nos cinco cards, dourado só na placa
- [ ] O card **não** é filho direto de um `HBoxContainer`/`GridContainer` que
      sobrescreva `position` — se a faixa usa container, o card entra dentro de
      um `Control` wrapper com `custom_minimum_size = (152, 188)`
- [ ] Todas as folhas de fonte são as 1:1 (`font_1x_v1`, `digits_1x_v1`,
      `digits_card_1x_v1`), `Filter = Nearest`

## 6. Como pedir layout ao Codex

O prompt que funciona tem estas quatro partes, nesta ordem:

1. a **árvore de nós** com tamanho, posição, pai e flag de clip de cada nó;
2. o **espaço de coordenadas** de cada bloco de medidas, dito em voz alta;
3. as **tabelas literais** (por elemento, por estado) — zero aritmética implícita;
4. a **regra de ancoragem** de cada arte (pés, centro, canto) e o que acontece
   quando ela é maior que a janela.

O que não funciona: prosa do tipo "o personagem fica na parte de cima do card,
centralizado". Isso tem quatro interpretações e três delas quebram.
