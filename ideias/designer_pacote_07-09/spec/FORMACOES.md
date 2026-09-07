# Formacoes de inimigo e sequencia de stage

Espaco: **STAGE** (888 x 560). `cx` = centro horizontal, `y` = topo da placa.

## 1. Formacoes (tabela literal)

### 1 inimigo (boss) — escala 6, sprite 330
| # | cx | y | elemento | turn |
| --- | --- | --- | --- | --- |
| 0 | 444 | 34 | dragon | 1 |

### 2 inimigos — escala 6, sprite 236
| # | cx | y | elemento | turn |
| --- | --- | --- | --- | --- |
| 0 | 256 | 44 | nature | 2 |
| 1 | 632 | 44 | dark | 1 |

### 3 inimigos — escala 4, sprite 190
| # | cx | y | elemento | turn |
| --- | --- | --- | --- | --- |
| 0 | 154 | 26 | nature | 2 |
| 1 | 444 | 214 | dark | 3 |
| 2 | 734 | 26 | knight | 1 |

### 5 inimigos — escala 4, sprite 150
| # | cx | y | elemento | turn |
| --- | --- | --- | --- | --- |
| 0 | 124 | 18 | nature | 2 |
| 1 | 444 | 18 | dark | 1 |
| 2 | 764 | 18 | light | 3 |
| 3 | 278 | 272 | knight | 2 |
| 4 | 610 | 272 | dragon | 1 |

## 2. Sequencia de stage

| stage | formacao | backdrop | boss |
| --- | --- | --- | --- |
| 1/3 | 3 inimigos | `backdrops/stage_plains_v1.png` | nao |
| 2/3 | 2 inimigos | `backdrops/stage_forest_v1.png` | nao |
| 3/3 | 1 inimigo | `backdrops/stage_sea_v1.png` | **sim** |

Ao cair o ultimo inimigo: flash 450 ms -> swap em 480 ms -> crossfade do
backdrop em 600 ms. Depois do boss o ciclo reinicia em 1/3 (comportamento de
laboratorio; no jogo, trocar por tela de resultado).

## 3. Trilha de nos do plate de STAGE

| estado | lado | preenchimento | borda |
| --- | --- | --- | --- |
| concluido | 12 | `#c9c0a8` | — |
| atual | 15 | `#7d9455` | 2 px `#c9c0a8` |
| futuro | 12 | `#1a1a16` | 2 px `rgba(201,192,168,.45)` |
| boss | 17 | `#2a1512` | 2 px `#c04a3e` |

**Precedencia: o boss vence na FORMA.** Quando o boss e o stage atual ele
continua 17 px com borda vermelha e apenas ganha o glow. E o caso que quebra
primeiro.

## 4. Backdrops

| asset | nativo | escala legal | desenho |
| --- | --- | --- | --- |
| `backdrops/stage_plains_v1.png` | 222 x 140 | x4 | 888 x 560 |
| `backdrops/stage_forest_v1.png` | 222 x 140 | x4 | 888 x 560 |
| `backdrops/stage_sea_v1.png` | 222 x 140 | x4 | 888 x 560 |

Desenhe em 888 x 560 exatos (`no-repeat`, sem `cover`), `Filter = Nearest`.
Os antigos `stage-grass-mountains / -forest-night / -night-sea` **foram
descartados**: eram screenshots do jogo de referencia com o HUD e os
personagens deles embutidos na foto.
