# 03 · Tema

## Cores
| token | valor | uso |
|---|---|---|
| shell | `#16130D` | fundo da tela |
| surface | `#201C13` | faixa de instrumentos, botões de navegação, botão de líder |
| amber | `#F2A33C` | acento: cantoneiras, XP, seleção, botão FASES, líder ativo |
| cream | `#F5EFE2` | texto principal e linhas |
| mint | `#6FE3B8` | HP da equipe acima de 40%, SYNC, energia |
| danger | `#FF6B4A` | alvo, mira, ataque iminente, HP baixo |
| ring_enemy_hp | `#FF4A3A` | anel de vida dos inimigos |

Cores de elemento dos **anéis de chão** (vivas, para ler sobre o cenário): Dragon `#FF5A3D` · Knight `#4DA8FF` · Nature `#5BD75B` · Light `#FFC93C` · Dark `#B06BFF`.
Cores das **cartas e selos** (sóbrias): ver `data/palette.json → element_card`.

Opacidades de texto sobre o `shell`: 65%, 55%, 45%, 40%, 35% do cream (`data/palette.json → text_alpha`).

## Fontes (`fonts/`)
- **Instrument Sans** — nome do jogador, nome do alvo, LV dos chips, títulos.
- **Martian Mono** — todos os números, rótulos em caixa-alta (BITS, ROUND, ATQ…), avisos.

Rótulo padrão "tick": Martian Mono 14px (7pt), peso 400, espaçamento 1px, CAIXA-ALTA.

## Tipografia medida (px em 1024)
| peça | exemplo | fonte | tamanho | peso | espaçamento | caixa | cor |
|---|---|---|---|---|---|---|---|
| bank_label | BANCO | Martian Mono | 14.0 | 400 | 1.0 | uppercase | rgba(245, 239, 226, 0.5) |
| bank_queue_label | FILA | Martian Mono | 14.0 | 400 | 1.0 | uppercase | rgba(245, 239, 226, 0.4) |
| button_nav_equipe_label | EQUIPE | Martian Mono | 14.0 | 400 | 1.0 | uppercase | rgba(245, 239, 226, 0.65) |
| button_nav_fases_label | FASES | Martian Mono | 14.0 | 600 | 1.0 | uppercase | rgb(26, 17, 5) |
| button_nav_invocar_label | INVOCAR | Martian Mono | 14.0 | 400 | 1.0 | uppercase | rgba(245, 239, 226, 0.65) |
| button_nav_loja_label | LOJA | Martian Mono | 14.0 | 400 | 1.0 | uppercase | rgba(245, 239, 226, 0.65) |
| card_order_1 | 1 | Martian Mono | 16.0 | 600 | normal | none | rgb(26, 17, 5) |
| card_order_8 | 2 | Martian Mono | 16.0 | 600 | normal | none | rgb(26, 17, 5) |
| card_value_1 | 4 | Martian Mono | 19.0 | 600 | normal | none | rgb(255, 255, 255) |
| card_value_10 | 6 | Martian Mono | 19.0 | 600 | normal | none | rgb(255, 255, 255) |
| card_value_11 | 10 | Martian Mono | 19.0 | 600 | normal | none | rgb(255, 255, 255) |
| card_value_12 | 9 | Martian Mono | 19.0 | 600 | normal | none | rgb(255, 255, 255) |
| card_value_2 | 7 | Martian Mono | 19.0 | 600 | normal | none | rgb(255, 255, 255) |
| card_value_3 | 6 | Martian Mono | 19.0 | 600 | normal | none | rgb(255, 255, 255) |
| card_value_4 | 9 | Martian Mono | 19.0 | 600 | normal | none | rgb(255, 255, 255) |
| card_value_5 | 8 | Martian Mono | 19.0 | 600 | normal | none | rgb(255, 255, 255) |
| card_value_6 | 10 | Martian Mono | 19.0 | 600 | normal | none | rgb(255, 255, 255) |
| card_value_7 | 5 | Martian Mono | 19.0 | 600 | normal | none | rgb(255, 255, 255) |
| card_value_8 | 4 | Martian Mono | 19.0 | 600 | normal | none | rgb(255, 255, 255) |
| card_value_9 | 7 | Martian Mono | 19.0 | 600 | normal | none | rgb(255, 255, 255) |
| header_player_name | Jinsa | Instrument Sans | 30.0 | 700 | -0.4 | none | rgb(245, 239, 226) |
| header_player_rank | TAMER · LV38 | Martian Mono | 14.0 | 400 | 1.0 | uppercase | rgb(242, 163, 60) |
| header_sync_text | SYNC | Martian Mono | 14.0 | 400 | 1.0 | uppercase | rgba(245, 239, 226, 0.4) |
| header_xp_text | 6120/12000 | Martian Mono | 16.0 | 400 | normal | none | rgba(245, 239, 226, 0.45) |
| strip_bits_label | BITS | Martian Mono | 14.0 | 400 | 1.0 | uppercase | rgba(245, 239, 226, 0.45) |
| strip_bits_value | 12.845.900 | Martian Mono | 25.0 | 600 | -1.2 | none | rgb(245, 239, 226) |
| strip_energy_label | ENERGIA | Martian Mono | 14.0 | 400 | 1.0 | uppercase | rgba(245, 239, 226, 0.45) |
| strip_energy_timer | +04:12 | Martian Mono | 14.0 | 400 | 1.0 | uppercase | rgba(111, 227, 184, 0.7) |
| strip_energy_value | 092/100 | Martian Mono | 25.0 | 600 | -1.2 | none | rgb(245, 239, 226) |
| strip_gems_label | GEMAS | Martian Mono | 14.0 | 400 | 1.0 | uppercase | rgba(245, 239, 226, 0.45) |
| strip_gems_value | 128.400 | Martian Mono | 25.0 | 600 | -1.2 | none | rgb(245, 239, 226) |
| team_hp_label | EQUIPE HP | Martian Mono | 14.0 | 400 | 1.0 | uppercase | rgb(111, 227, 184) |
| team_hp_text | 2840/3200 | Martian Mono | 19.0 | 500 | normal | none | rgb(245, 239, 226) |
| toast | LIDERANÇA ATIVA · +25% NESTE TURNO | Martian Mono | 19.0 | 600 | 0.6 | none | rgb(242, 163, 60) |
| visor_sector | SETOR 03 · ILHA DIGITAL | Martian Mono | 14.0 | 400 | 1.0 | uppercase | rgba(242, 163, 60, 0.95) |


## Espessuras e efeitos
- Contornos finos: 2px (1pt) · cantoneiras: 3px (1.5pt), braço 32px no visor, 18px no avatar
- Barras segmentadas: segmento 10px + vão 4px (XP, HP da equipe, pop-up)
- Anel de chão: trilho 10px `rgba(8,10,12,.75)` com miolo `rgba(10,14,10,.38)`; progresso 6.4px; marcas 7.2px tracejadas
- Película: linhas pretas 15% a cada 6px; vinheta radial até 62% do shell nas bordas
- Pop-up: fundo `rgba(16,13,9,.94)`, contorno `rgba(255,107,74,.5)`, raio 16, sombra 0 12 36 60% preto
- Brilho de skill pronta: sombra da cor do elemento, raio 10px
