# Especificação de Layout — Arena de Batalha 1-Bit

## 0. Estado implementado — revisão de 29/08/2026

As tabelas abaixo preservam o estudo original de slots e escalas. Quando houver
conflito, este bloco descreve o padrão atual da alpha jogável:

- Os cinco inimigos usam formação em profundidade, não uma única linha. O HUD
  fica acima do retângulo final de cada sprite e cresce proporcionalmente para
  encontros com menos unidades ou chefe único.
- O HUD inimigo é uma peça única com marcador elemental, `X TURN` e barra de
  life vermelha. As antigas regras de life somente em texto estão superadas.
- Os cinco aliados usam formação fixa em W. Não há barra horizontal abaixo do
  personagem: a skill é um medidor radial de oito blocos ancorado no canto
  superior-direito do retângulo real do sprite.
- O centro do medidor aliado tem `34 × 34 px` no canvas de `1152 × 2048`. O
  marcador inimigo usa aproximadamente `11,2%` da largura do respectivo HUD.
- O affinity não usa mais ícone branco. Ele é um quadrado pequeno preenchido
  por cor fosca: Dragão/vermelho, Cavaleiro/azul, Natureza/verde, Luz/amarelo e
  Trevas/roxo. Borda clara, sombra curta, sem aparência de LED.
- Cards, fusão e energia reutilizam a mesma paleta dessaturada. Wild reúne as
  cinco cores; Cura usa marrom.
- O HP do time é universal e permanece no rodapé. Aliados não exibem life
  individual na arena.
- As posições finais continuam inteiras, com filtro nearest e validação no
  cenário crítico de cinco contra cinco.

Implementação de referência: `Unidades.gd`, `EnemyUnit.gd`, `AllyUnit.gd`,
`SkillGauge.gd`, `CardIcon.gd` e `Arte.gd`.

## 1. Objetivo

Definir um layout determinístico para a área de batalha onde:

- o time do jogador possui **sempre 5 personagens** na faixa inferior;
- o inimigo pode possuir **1, 2, 3, 4 ou 5 unidades** na faixa superior;
- cada inimigo possui:
  - sprite;
  - ícone de affinity em moldura, posicionado no canto superior-direito da cabeça;
  - life em texto com coração: `♥ atual / máximo`;
  - **sem barra de life**;
- cada personagem do jogador possui:
  - sprite;
  - ícone de affinity na mesma lógica/posição relativa usada no inimigo;
  - **sem texto de life**;
  - somente a barra de skill abaixo.

A documentação trata cada unidade como um **slot invisível**. Nada do personagem deve ultrapassar o slot, exceto por até 2 px de antialias inexistente/contorno visual do próprio sprite.

---

## 2. Sistema de coordenadas recomendado

A imagem de referência enviada possui aproximadamente **549 × 529 px**.

Para implementação, usar uma malha lógica normalizada de:

- **540 × 520 px** — resolução lógica do módulo de batalha;
- escala 2× = **1080 × 1040 px** no Android;
- filtro de textura: **Nearest / Point**;
- sem interpolação linear;
- posições sempre inteiras.

Essa normalização evita subpixel e mantém a pixel-art limpa em 1080 px de largura.

### Conversão

- lógico → Android 1080: multiplicar tudo por `2`;
- referência 549×529 → lógico 540×520:
  - `x_logico = x_ref × 540 / 549`
  - `y_logico = y_ref × 520 / 529`

---

# 3. Macro layout do módulo 540 × 520

## 3.1 Área dos inimigos

**Moldura visível:**

```text
X = 90
Y = 79
W = 366
H = 253
```

Android 1080:

```text
X = 180
Y = 158
W = 732
H = 506
```

### Safe Area interna dos inimigos

Nenhum componente funcional deve sair desta área:

```text
X = 102
Y = 91
W = 342
H = 229
```

Android:

```text
X = 204
Y = 182
W = 684
H = 458
```

---

## 3.2 Área fixa do time do jogador

**Moldura visível:**

```text
X = 16
Y = 356
W = 503
H = 149
```

Android:

```text
X = 32
Y = 712
W = 1006
H = 298
```

### Safe Area interna do time

```text
X = 28
Y = 365
W = 479
H = 130
```

Android:

```text
X = 56
Y = 730
W = 958
H = 260
```

---

# 4. Regra do slot invisível

Cada unidade ocupa um retângulo invisível.

Dentro dele existem três regiões funcionais:

```text
┌────────────────────────────┐
│                            │
│       ┌──────────┐ [AFF]   │
│       │  SPRITE  │         │
│       │          │         │
│       └──────────┘         │
│                            │
│     ♥ 1234 / 1500          │   ← inimigo
│                            │
└────────────────────────────┘
```

No jogador:

```text
┌────────────────────────────┐
│                            │
│       ┌──────────┐ [AFF]   │
│       │  SPRITE  │         │
│       │          │         │
│       └──────────┘         │
│                            │
│       [ SKILL BAR ]        │
└────────────────────────────┘
```

O ícone de affinity **não fica centralizado acima do personagem**.
Ele deve ficar no **lado direito da cabeça**, levemente sobreposto ao bounding box superior do sprite.

---

# 5. Layout adaptativo dos inimigos

Todos os slots inimigos usam:

```text
slot_y = 108
slot_h = 184
```

Android:

```text
slot_y = 216
slot_h = 368
```

A base do sprite é alinhada sempre em:

```text
sprite_bottom_y = 268
```

Android:

```text
sprite_bottom_y = 536
```

O life começa em:

```text
life_y = 278
```

Android:

```text
life_y = 556
```

Isso faz todos os inimigos ficarem visualmente assentados na mesma linha, independentemente do tamanho.

---

# 6. Cenário com 1 inimigo

## Slot

```text
X = 193
Y = 108
W = 160
H = 184
Centro X = 273
```

Android:

```text
X = 386
Y = 216
W = 320
H = 368
Centro X = 546
```

## Componentes dentro do slot

### Sprite

```text
local_x = 18
local_y = 42
W máximo = 118
H máximo = 118
```

### Affinity

```text
local_x = 124
local_y = 50
W = 26
H = 26
```

### Life

```text
local_y = 170
altura = 10
fonte recomendada = 10 px
alinhamento = centro
formato = ♥ 1800 / 1800
```

### Android 2×

- Sprite: até **236 × 236 px**
- Affinity: **52 × 52 px**
- Fonte: **20 px**

### Uso visual

Com apenas um inimigo, ele deve ser claramente o foco da arena. Não ampliar além desse limite para não quebrar consistência ao transicionar para 2 inimigos.

---

# 7. Cenário com 2 inimigos

## Slots

| Unidade | X | Y | W | H | Centro X |
|---|---:|---:|---:|---:|---:|
| 1 | 111 | 108 | 150 | 184 | 186 |
| 2 | 285 | 108 | 150 | 184 | 360 |

Gap horizontal: **24 px**.

Android: gap **48 px**.

## Componentes locais

### Sprite

```text
local_x = 16
local_y = 62
W máximo = 98
H máximo = 98
```

### Affinity

```text
local_x = 108
local_y = 70
W = 24
H = 24
```

### Life

```text
local_y = 170
fonte = 10 px
```

Android:

- sprite: **196 × 196 px**;
- affinity: **48 × 48 px**;
- fonte: **20 px**.

---

# 8. Cenário com 3 inimigos

## Slots

| Unidade | X | Y | W | H | Centro X |
|---|---:|---:|---:|---:|---:|
| 1 | 102 | 108 | 104 | 184 | 154 |
| 2 | 221 | 108 | 104 | 184 | 273 |
| 3 | 340 | 108 | 104 | 184 | 392 |

Gap horizontal: **15 px**.

Android: **30 px**.

## Componentes locais

### Sprite

```text
local_x = 9
local_y = 80
W máximo = 80
H máximo = 80
```

### Affinity

```text
local_x = 80
local_y = 88
W = 20
H = 20
```

### Life

```text
local_y = 170
fonte = 9 px
```

Android:

- sprite: **160 × 160 px**;
- affinity: **40 × 40 px**;
- fonte: **18 px**.

---

# 9. Cenário com 4 inimigos

## Slots

| Unidade | X | Y | W | H | Centro X |
|---|---:|---:|---:|---:|---:|
| 1 | 103 | 108 | 76 | 184 | 141 |
| 2 | 191 | 108 | 76 | 184 | 229 |
| 3 | 279 | 108 | 76 | 184 | 317 |
| 4 | 367 | 108 | 76 | 184 | 405 |

Gap horizontal: **12 px**.

Android: **24 px**.

## Componentes locais

### Sprite

```text
local_x = 4
local_y = 96
W máximo = 64
H máximo = 64
```

### Affinity

```text
local_x = 57
local_y = 102
W = 18
H = 18
```

### Life

```text
local_y = 170
fonte = 8 px
```

Android:

- sprite: **128 × 128 px**;
- affinity: **36 × 36 px**;
- fonte: **16 px**.

---

# 10. Cenário com 5 inimigos — cenário crítico

Este é o cenário que deve governar a validação do layout.

## Slots

| Unidade | X | Y | W | H | Centro X |
|---|---:|---:|---:|---:|---:|
| 1 | 102 | 108 | 63 | 184 | 133.5 |
| 2 | 172 | 108 | 63 | 184 | 203.5 |
| 3 | 242 | 108 | 63 | 184 | 273.5 |
| 4 | 312 | 108 | 63 | 184 | 343.5 |
| 5 | 381 | 108 | 63 | 184 | 412.5 |

Gaps:

```text
7 / 7 / 7 / 6 px
```

Android:

```text
14 / 14 / 14 / 12 px
```

## Componentes locais

### Sprite

```text
local_x = 2
local_y = 108
W máximo = 52
H máximo = 52
```

### Affinity

```text
local_x = 45
local_y = 114
W = 16
H = 16
```

O ícone pode sobrepor alguns pixels da região superior-direita do bounding box do sprite. Isso é intencional.

### Life

```text
local_y = 170
fonte = 8 px
altura = 10 px
```

Para 5 inimigos, preferir o formato compacto:

```text
♥ 1800/1800
```

em vez de:

```text
♥ 1800 / 1800
```

caso o texto exceda 63 px.

Android:

- sprite: **104 × 104 px**;
- affinity: **32 × 32 px**;
- fonte: **16 px**.

### Regra de aprovação

Se qualquer sprite ultrapassar 52 × 52 no layout lógico quando houver 5 inimigos, o layout deve ser considerado fora da especificação.

---

# 11. Resumo de escalas dos inimigos

| Inimigos | Slot W | Sprite máx. | Affinity | Fonte life | Gap |
|---:|---:|---:|---:|---:|---:|
| 1 | 160 | 118×118 | 26×26 | 10 | — |
| 2 | 150 | 98×98 | 24×24 | 10 | 24 |
| 3 | 104 | 80×80 | 20×20 | 9 | 15 |
| 4 | 76 | 64×64 | 18×18 | 8 | 12 |
| 5 | 63 | 52×52 | 16×16 | 8 | 6–7 |

### Em 1080 px de largura

| Inimigos | Slot W | Sprite máx. | Affinity | Fonte life |
|---:|---:|---:|---:|---:|
| 1 | 320 | 236×236 | 52×52 | 20 |
| 2 | 300 | 196×196 | 48×48 | 20 |
| 3 | 208 | 160×160 | 40×40 | 18 |
| 4 | 152 | 128×128 | 36×36 | 16 |
| 5 | 126 | 104×104 | 32×32 | 16 |

---

# 12. Time do jogador — sempre 5 personagens

A área inferior **não muda de escala**.

Ela deve ser desenhada considerando sempre os 5 personagens presentes.

## Slots fixos

Cada slot possui:

```text
W = 93
H = 130
Y = 365
```

GAP fixo:

```text
3 px
```

### Coordenadas

| Player | X | Y | W | H | Centro X |
|---|---:|---:|---:|---:|---:|
| P1 | 29 | 365 | 93 | 130 | 75.5 |
| P2 | 125 | 365 | 93 | 130 | 171.5 |
| P3 | 221 | 365 | 93 | 130 | 267.5 |
| P4 | 317 | 365 | 93 | 130 | 363.5 |
| P5 | 413 | 365 | 93 | 130 | 459.5 |

Android 1080:

- slot: **186 × 260 px**;
- gap: **6 px**.

---

# 13. Componentes internos do player

Todas as coordenadas abaixo são **locais ao slot**.

## Sprite

```text
X = 8
Y = 12
W máximo = 70
H máximo = 82
```

Android:

```text
140 × 164 px
```

## Affinity

Mesma regra visual do inimigo.

```text
X = 69
Y = 18
W = 18
H = 18
```

Android:

```text
36 × 36 px
```

O ícone deve ficar ao lado direito da cabeça, com pequena sobreposição visual sobre o quadrante superior-direito do sprite.

## Skill Bar

```text
X = 10
Y = 111
W = 73
H = 8
```

Android:

```text
X local = 20
Y local = 222
W = 146
H = 16
```

### Barra

- borda: 1 px lógico;
- interior útil: 71 × 6 px;
- preenchimento: `skill_atual / skill_max`;
- sem número de life;
- sem coração;
- sem barra adicional.

---

# 14. Regra do affinity — padrão único para os dois times

O affinity precisa parecer o mesmo componente para inimigo e player.

## Padrão

```text
[ cabeça ] [AFF]
```

Nunca:

```text
     [AFF]
[ personagem ]
```

### Comportamento

- canto superior-direito do personagem;
- pequena moldura quadrada;
- interior escuro;
- ícone branco;
- 1-bit;
- sem texto;
- sem sombra suave;
- pode sobrepor até aproximadamente 15% do sprite;
- nunca deve cobrir olhos/face.

### Ordem de renderização

```text
1. Background / cenário
2. Sprite do personagem
3. Moldura affinity
4. Ícone affinity
5. Life ou Skill Bar
```

O affinity fica visualmente acima do sprite.

---

# 15. Life dos inimigos

## Estrutura

```text
♥ atual / máximo
```

Exemplo:

```text
♥ 715 / 1200
```

Não existe barra abaixo.

### Regras

- coração = glyph/sprite 1-bit;
- texto centralizado no slot;
- 1 linha apenas;
- máximo recomendado: 4 dígitos por valor;
- cenário de 5 inimigos: compactar espaços antes de reduzir fonte abaixo de 8 px lógico.

Prioridade:

```text
1. Remover espaços extras
2. Reduzir tracking
3. Somente então reduzir fonte
```

---

# 16. Skill Bar do jogador

O jogador não exibe life nesta área.

Cada personagem possui apenas:

```text
[ PERSONAGEM + AFFINITY ]

[=====---------]  SKILL
```

A posição da barra é fixa para os cinco slots.

Isso garante alinhamento horizontal e impede que personagens mais altos ou mais baixos façam a UI "pular".

---

# 17. Regras para sprites com formatos diferentes

Não escalar todo personagem para exatamente `W × H`.

O valor definido é um **bounding box máximo**.

Exemplo no cenário de 5:

```text
bounding máximo = 52 × 52
```

Um slime pode usar:

```text
48 × 38
```

Um dragão pode usar:

```text
52 × 49
```

Um personagem estreito pode usar:

```text
37 × 52
```

Todos devem:

- preservar aspect ratio;
- alinhar pela base;
- ficar centralizados horizontalmente dentro da região de sprite;
- nunca ser esticados para preencher o box.

---

# 18. Grid e pixel snapping

Obrigatório:

```text
position.x = inteiro
position.y = inteiro
size.x = inteiro
size.y = inteiro
```

No render 2×:

```text
1 px lógico = 2 px físicos
```

Nunca posicionar elementos em:

```text
x = 241.5
```

No motor, arredondar antes do draw.

---

# 19. Estrutura recomendada no Godot

```text
BattleArena
├── Background
├── EnemyPanel
│   ├── EnemySlot01
│   │   ├── CharacterSprite
│   │   ├── AffinityFrame
│   │   │   └── AffinityIcon
│   │   └── LifeLabel
│   ├── EnemySlot02
│   ├── EnemySlot03
│   ├── EnemySlot04
│   └── EnemySlot05
└── PlayerPanel
    ├── PlayerSlot01
    │   ├── CharacterSprite
    │   ├── AffinityFrame
    │   │   └── AffinityIcon
    │   └── SkillBar
    ├── PlayerSlot02
    ├── PlayerSlot03
    ├── PlayerSlot04
    └── PlayerSlot05
```

Os slots inimigos que não estiverem em uso devem ser ocultados; ao alterar a quantidade de inimigos, aplicar a tabela de layout correspondente.

---

# 20. Regra para mudança de quantidade de inimigos

Não interpolar o tamanho de forma contínua.

Usar **5 presets fechados**:

```text
ENEMY_LAYOUT_1
ENEMY_LAYOUT_2
ENEMY_LAYOUT_3
ENEMY_LAYOUT_4
ENEMY_LAYOUT_5
```

Cada preset define:

```text
slot_rects
sprite_max_size
icon_size
font_size
```

Isso evita variações de 1 ou 2 pixels entre batalhas e mantém a UI consistente.

---

# 21. Critério visual final

## 1 inimigo

- protagonista visual da área;
- sprite grande;
- muito espaço negativo.

## 2 inimigos

- duas massas visuais equilibradas;
- sem aproximar demais do centro.

## 3 inimigos

- distribuição simétrica;
- unidade central exatamente no eixo X do painel.

## 4 inimigos

- quatro slots uniformes;
- ícones começam a ficar mais compactos.

## 5 inimigos

- cenário crítico;
- sprites pequenos, porém ainda legíveis;
- affinity mínimo de 16×16 lógico / 32×32 físico;
- life em uma linha;
- nenhum elemento cruza o slot vizinho.

## Player

- sempre 5;
- mesma escala sempre;
- affinity ao lado direito da cabeça;
- somente skill bar abaixo;
- zero mudança de posição entre batalhas.

---

# 22. Resumo executivo

```text
BATTLE MODULE: 540 × 520
ANDROID @2X:   1080 × 1040

ENEMY PANEL:
90,79 / 366×253

PLAYER PANEL:
16,356 / 503×149

PLAYER:
5 slots fixos de 93×130
sprite máximo 70×82
affinity 18×18
skill 73×8

ENEMY 1:
sprite 118
affinity 26

ENEMY 2:
sprite 98
affinity 24

ENEMY 3:
sprite 80
affinity 20

ENEMY 4:
sprite 64
affinity 18

ENEMY 5:
sprite 52
affinity 16

ENEMY:
♥ LIFE somente

PLAYER:
SKILL BAR somente
```
