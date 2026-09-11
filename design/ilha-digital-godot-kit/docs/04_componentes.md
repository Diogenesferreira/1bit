# 04 · Componentes e texturas

`texture_rect` = onde a textura se encaixa na tela 1024×1600 (já inclui sombra/brilho). `node` = retângulo do elemento sem a sombra — use para posicionar o Control e o 9-slice.

Modos: **completo** (com ícones/texto, para conferência), **caixa** (só fundo/borda/sombra, sem conteúdo), **under / progress / over** (camadas de TextureProgressBar, todas no mesmo retângulo).

## `assets/background`

| arquivo | modo | estado | texture_rect | node | raio | nota |
|---|---|---|---|---|---|---|
| `visor_film_scanline_976x736.png` | completo | padrao | 24,232 976×736 | 24,232 976×736 |  | camada 3: por cima do cenario e dos personagens |
| `visor_film_vignette_976x736.png` | completo | padrao | 24,232 976×736 | 24,232 976×736 |  | camada 3: por cima do scanline |

## `assets/buttons`

| arquivo | modo | estado | texture_rect | node | raio | nota |
|---|---|---|---|---|---|---|
| `button_nav_normal.png` | caixa | padrao | 24,1479 232×101 | 24,1480 232×100 | 18.0 | EQUIPE / INVOCAR / LOJA |
| `button_nav_primary.png` | caixa | padrao | 734,1453 290×147 | 768,1480 232×100 | 18.0 | FASES (botao principal) |
| `button_nav_equipe_ref.png` | completo | padrao | 24,1479 232×101 | 24,1480 232×100 | 18.0 |  |
| `button_nav_invocar_ref.png` | completo | padrao | 272,1479 232×101 | 272,1480 232×100 | 18.0 |  |
| `button_nav_loja_ref.png` | completo | padrao | 520,1479 232×101 | 520,1480 232×100 | 18.0 |  |
| `button_nav_fases_ref.png` | completo | padrao | 734,1453 290×147 | 768,1480 232×100 | 18.0 |  |
| `button_leader_normal.png` | caixa | padrao | 888,984 112×38 | 898.5,984 101.5×38 | 10.0 |  |
| `button_leader_active.png` | caixa | cartas_selecionadas | 856,984 144×38 | 872.4,984 127.6×38 | 10.0 |  |
| `button_leader_cooldown.png` | caixa | alertas | 899,984 101×38 | 907.2,984 92.8×38 | 10.0 |  |
| `button_leader_normal_ref.png` | completo | padrao | 888,984 112×38 | 898.5,984 101.5×38 | 10.0 |  |
| `button_leader_active_ref.png` | completo | cartas_selecionadas | 856,984 144×38 | 872.4,984 127.6×38 | 10.0 |  |
| `button_leader_cooldown_ref.png` | completo | alertas | 899,984 101×38 | 907.2,984 92.8×38 | 10.0 |  |

## `assets/cards`

| arquivo | modo | estado | texture_rect | node | raio | nota |
|---|---|---|---|---|---|---|
| `card_frame_selected.png` | caixa | cartas_selecionadas | 0,1040 221×270 | 24,1084 152.7×176.8 | 18.0 | anel ambar da carta selecionada (a carta sobe 10px) |
| `card_slot_selected_ref.png` | completo | cartas_selecionadas | 0,1040 221×270 | 24,1084 152.7×176.8 | 18.0 |  |
| `card_slot_ref.png` | completo | padrao | 173,1084 184×209 | 188.7,1094 152.7×176.8 | 18.0 |  |
| `card_order_badge.png` | caixa | cartas_selecionadas | 143,1092 28×28 | 142.7,1092 28×28 | 8.0 | selo do indice do combo |
| `card_value_plate.png` | caixa | padrao | 34,1232 33×31 | 36,1234.8 26.5×26 | 8.0 | placa do numero de poder |

## `assets/hud/bank`

| arquivo | modo | estado | texture_rect | node | raio | nota |
|---|---|---|---|---|---|---|
| `bank_rule.png` | completo | padrao | 176,1058 603×2 | 165.5,1058 621.7×2 |  |  |
| `bank_combo_off.png` | completo | padrao | 94,1050 66×18 | 83.5,1050 66×18 |  |  |
| `bank_combo_2of3.png` | completo | cartas_selecionadas | 94,1050 66×18 | 83.5,1050 66×18 |  |  |
| `bank_header_ref.png` | completo | padrao | 25,1040 975×38 | 24,1040 976×38 |  |  |

## `assets/hud/header`

| arquivo | modo | estado | texture_rect | node | raio | nota |
|---|---|---|---|---|---|---|
| `avatar_frame.png` | completo | padrao | 26,18 96×96 | 32,24 84×84 |  | moldura + cantoneiras; a foto vai por baixo |
| `avatar_placeholder.png` | completo | padrao | 32,24 84×84 | 32,24 84×84 | 24.0 | foto provisoria do jogador |
| `xp_bar_under.png` | under | padrao | 140,86 296×8 | 140,87.0 296×8 | 2.0 | TextureProgressBar esquerda->direita; segmentos ja desenhados |
| `xp_bar_progress.png` | progress | padrao | 140,86 296×8 | 140,87.0 296×8 | 2.0 | TextureProgressBar esquerda->direita; segmentos ja desenhados |
| `sync_dot.png` | completo | padrao | 848,43 46×46 | 873.2,60 12×12 |  |  |
| `header_ref.png` | completo | padrao | 26,18 960×96 | 0,0 1024×132 |  | referencia com textos |

## `assets/hud/popup`

| arquivo | modo | estado | texture_rect | node | raio | nota |
|---|---|---|---|---|---|---|
| `popup_target_box.png` | caixa | alvo_inimigo | 414,466 432×232 | 458,498 344×146 | 16.0 | painel 9-slice |
| `popup_target_arrow_down.png` | completo | alvo_inimigo | 617,630 26×29 | 617.3,632.3 25.5×25.5 |  | seta quando o pop-up abre ACIMA do alvo |
| `popup_target_arrow_right.png` | completo | alvo_chefe | 610,344 29×26 | 610.3,344.3 25.5×25.5 |  | seta quando o pop-up abre AO LADO do alvo |
| `popup_hp_under.png` | under | alvo_inimigo | 478,572 304×10 | 478,574 304×10 | 2.0 | barra de vida do pop-up |
| `popup_hp_progress.png` | progress | alvo_inimigo | 478,572 304×10 | 478,574 304×10 | 2.0 | barra de vida do pop-up |
| `popup_turn_box_amber.png` | caixa | alvo_chefe | 471,384 131×30 | 480,386 122×30 | 8.0 |  |
| `popup_turn_box_red.png` | caixa | alvo_inimigo | 651,594 131×30 | 660,596 122×30 | 8.0 |  |
| `popup_target_ref_acima.png` | completo | alvo_inimigo | 414,466 432×232 | 458,498 344×146 | 16.0 |  |
| `popup_target_ref_lado.png` | completo | alvo_chefe | 234,256 432×232 | 278,288 344×146 | 16.0 |  |

## `assets/hud/stage`

| arquivo | modo | estado | texture_rect | node | raio | nota |
|---|---|---|---|---|---|---|
| `ring_A1_under.png` | under | padrao | 97,545 146×50 | 90.4,538 160×64 |  | TextureProgressBar radial horario, angulo inicial 90; progress branco + tint_progress |
| `ring_A1_progress.png` | progress | padrao | 97,545 146×50 | 90.4,538 160×64 |  | TextureProgressBar radial horario, angulo inicial 90; progress branco + tint_progress |
| `ring_A1_over.png` | over | padrao | 97,545 146×50 | 90.4,538 160×64 |  | TextureProgressBar radial horario, angulo inicial 90; progress branco + tint_progress |
| `ring_A2_under.png` | under | padrao | 314,517 142×50 | 307.1,510 156×64 |  | TextureProgressBar radial horario, angulo inicial 90; progress branco + tint_progress |
| `ring_A2_progress.png` | progress | padrao | 314,517 142×50 | 307.1,510 156×64 |  | TextureProgressBar radial horario, angulo inicial 90; progress branco + tint_progress |
| `ring_A2_over.png` | over | padrao | 314,517 142×50 | 307.1,510 156×64 |  | TextureProgressBar radial horario, angulo inicial 90; progress branco + tint_progress |
| `ring_A3_under.png` | under | padrao | 201,683 154×54 | 193.8,676 168×68 |  | TextureProgressBar radial horario, angulo inicial 90; progress branco + tint_progress |
| `ring_A3_progress.png` | progress | padrao | 201,683 154×54 | 193.8,676 168×68 |  | TextureProgressBar radial horario, angulo inicial 90; progress branco + tint_progress |
| `ring_A3_over.png` | over | padrao | 201,683 154×54 | 193.8,676 168×68 |  | TextureProgressBar radial horario, angulo inicial 90; progress branco + tint_progress |
| `ring_A4_under.png` | under | padrao | 58,865 166×58 | 51.1,858 180×72 |  | TextureProgressBar radial horario, angulo inicial 90; progress branco + tint_progress |
| `ring_A4_progress.png` | progress | padrao | 58,865 166×58 | 51.1,858 180×72 |  | TextureProgressBar radial horario, angulo inicial 90; progress branco + tint_progress |
| `ring_A4_over.png` | over | padrao | 58,865 166×58 | 51.1,858 180×72 |  | TextureProgressBar radial horario, angulo inicial 90; progress branco + tint_progress |
| `ring_A5_under.png` | under | padrao | 331,873 166×58 | 324.4,866 180×72 |  | TextureProgressBar radial horario, angulo inicial 90; progress branco + tint_progress |
| `ring_A5_progress.png` | progress | padrao | 331,873 166×58 | 324.4,866 180×72 |  | TextureProgressBar radial horario, angulo inicial 90; progress branco + tint_progress |
| `ring_A5_over.png` | over | padrao | 331,873 166×58 | 324.4,866 180×72 |  | TextureProgressBar radial horario, angulo inicial 90; progress branco + tint_progress |
| `ring_E1_under.png` | under | padrao | 647,561 238×78 | 639.8,554 252×92 |  | TextureProgressBar radial horario, angulo inicial 90; progress branco + tint_progress |
| `ring_E1_progress.png` | progress | padrao | 647,561 238×78 | 639.8,554 252×92 |  | TextureProgressBar radial horario, angulo inicial 90; progress branco + tint_progress |
| `ring_E1_over.png` | over | padrao | 647,561 238×78 | 639.8,554 252×92 |  | TextureProgressBar radial horario, angulo inicial 90; progress branco + tint_progress |
| `ring_E2_under.png` | under | padrao | 538,849 182×62 | 531.1,842 196×76 |  | TextureProgressBar radial horario, angulo inicial 90; progress branco + tint_progress |
| `ring_E2_progress.png` | progress | padrao | 538,849 182×62 | 531.1,842 196×76 |  | TextureProgressBar radial horario, angulo inicial 90; progress branco + tint_progress |
| `ring_E2_over.png` | over | padrao | 538,849 182×62 | 531.1,842 196×76 |  | TextureProgressBar radial horario, angulo inicial 90; progress branco + tint_progress |
| `ring_E3_under.png` | under | padrao | 782,863 182×62 | 775.1,856 196×76 |  | TextureProgressBar radial horario, angulo inicial 90; progress branco + tint_progress |
| `ring_E3_progress.png` | progress | padrao | 782,863 182×62 | 775.1,856 196×76 |  | TextureProgressBar radial horario, angulo inicial 90; progress branco + tint_progress |
| `ring_E3_over.png` | over | padrao | 782,863 182×62 | 775.1,856 196×76 |  | TextureProgressBar radial horario, angulo inicial 90; progress branco + tint_progress |
| `ring_BOSS_under.png` | under | chefe_sozinho | 570,769 314×102 | 562.7,762 328×116 |  | anel do chefe sozinho |
| `ring_BOSS_progress.png` | progress | chefe_sozinho | 570,769 314×102 | 562.7,762 328×116 |  | anel do chefe sozinho |
| `ring_BOSS_over.png` | over | chefe_sozinho | 570,769 314×102 | 562.7,762 328×116 |  | anel do chefe sozinho |
| `chip_ally_box.png` | caixa | padrao | 114,586 112×50 | 125.5,592 89.8×30 | 16.0 | pilula 9-slice do chip de aliado |
| `chip_enemy_box.png` | caixa | padrao | 542,902 174×50 | 553.8,908 150.5×30 | 16.0 | pilula 9-slice do chip de inimigo |
| `chip_frame_target.png` | caixa | alvo_chefe | 667,612 198×78 | 690.5,636 150.5×30 | 16.0 | chip do inimigo selecionado (anel vermelho) |
| `chip_frame_ready.png` | caixa | skill_pronta | 177,710 202×78 | 205.7,734 144.2×30 | 16.0 | chip do aliado com skill pronta (anel ambar) |
| `chip_ally_ref.png` | completo | padrao | 114,586 112×50 | 125.5,592 89.8×30 | 16.0 |  |
| `chip_ally_ready_ref.png` | completo | skill_pronta | 177,710 202×78 | 205.7,734 144.2×30 | 16.0 |  |
| `chip_enemy_ref.png` | completo | padrao | 786,916 174×50 | 797.8,922 150.5×30 | 16.0 |  |
| `chip_enemy_imminent_ref.png` | completo | padrao | 542,902 174×50 | 553.8,908 150.5×30 | 16.0 |  |
| `chip_turn_amber_ref.png` | completo | padrao | 779,645 53×12 | 780.3,643.0 50.7×16 |  |  |
| `chip_turn_red_ref.png` | completo | padrao | 643,917 53×12 | 643.6,915.0 50.7×16 |  |  |

## `assets/hud/strip`

| arquivo | modo | estado | texture_rect | node | raio | nota |
|---|---|---|---|---|---|---|
| `strip_bg.png` | caixa | padrao | 0,132 1024×92 | 0,132 1024×92 |  | faixa de instrumentos: fundo + linhas topo/base |
| `strip_rule.png` | completo | padrao | 340,148 2×54 | 340,148 2×60 |  | divisor vertical tracejado |
| `strip_ref.png` | completo | padrao | 0,132 1024×92 | 0,132 1024×92 |  | referencia com textos |

## `assets/hud/team`

| arquivo | modo | estado | texture_rect | node | raio | nota |
|---|---|---|---|---|---|---|
| `team_hp_under.png` | under | padrao | 141,997 587×12 | 122.3,997.0 642.2×12 | 2.0 | acima de 40% menta, 40-20% ambar, abaixo de 20% vermelho |
| `team_hp_progress.png` | progress | padrao | 141,997 587×12 | 122.3,997.0 642.2×12 | 2.0 | acima de 40% menta, 40-20% ambar, abaixo de 20% vermelho |
| `team_hp_progress_mint.png` | progress | padrao | 141,997 587×12 | 122.3,997.0 642.2×12 | 2.0 | acima de 40% menta, 40-20% ambar, abaixo de 20% vermelho |
| `team_hp_progress_amber.png` | progress | padrao | 141,997 587×12 | 122.3,997.0 642.2×12 | 2.0 | acima de 40% menta, 40-20% ambar, abaixo de 20% vermelho |
| `team_hp_progress_red.png` | progress | padrao | 141,997 587×12 | 122.3,997.0 642.2×12 | 2.0 | acima de 40% menta, 40-20% ambar, abaixo de 20% vermelho |
| `team_ref.png` | completo | padrao | 25,984 975×38 | 24,984 976×38 |  |  |

## `assets/hud/toast`

| arquivo | modo | estado | texture_rect | node | raio | nota |
|---|---|---|---|---|---|---|
| `toast_amber_ref.png` | completo | alertas | 317,867 389×149 | 390.1,904 243.8×50 | 14.0 |  |
| `toast_red_ref.png` | completo | aviso_vermelho | 220,867 584×149 | 312.8,904 398.4×50 | 14.0 |  |
| `toast_mint_ref.png` | completo | aviso_menta | 373,867 278×149 | 434.3,904 155.4×50 | 14.0 |  |
| `toast_box_amber.png` | caixa | alertas | 317,867 389×149 | 390.1,904 243.8×50 | 14.0 | caixa 9-slice do aviso |
| `toast_box_red.png` | caixa | aviso_vermelho | 220,867 584×149 | 312.8,904 398.4×50 | 14.0 | caixa 9-slice do aviso |
| `toast_box_mint.png` | caixa | aviso_menta | 373,867 278×149 | 434.3,904 155.4×50 | 14.0 | caixa 9-slice do aviso |

## `assets/hud/visor`

| arquivo | modo | estado | texture_rect | node | raio | nota |
|---|---|---|---|---|---|---|
| `visor_frame.png` | caixa | padrao | 0,185 1024×870 | 24,232 976×736 | 32.0 | contorno ambar interno + sombra externa; conteudo recortado em raio 32 |
| `visor_corner_tl.png` | completo | padrao | 40,248 32×32 | 40,248 32×32 |  |  |
| `visor_corner_tr.png` | completo | padrao | 952,248 32×32 | 952,248 32×32 |  |  |
| `visor_corner_bl.png` | completo | padrao | 40,920 32×32 | 40,920 32×32 |  |  |
| `visor_corner_br.png` | completo | padrao | 952,920 32×32 | 952,920 32×32 |  |  |
| `visor_sector_ref.png` | completo | padrao | 76,249 263×31 | 84,254 200.1×16 |  |  |
| `visor_round_ref.png` | completo | padrao | 834,250 114×56 | 861.7,252 78.3×47.6 |  |  |
| `aim_chefe.png` | completo | padrao | 610,281 312×312 | 610,281.0 312×312 |  | mira no chefe (E1) |
| `aim_inimigo.png` | completo | alvo_inimigo | 513,641 234×234 | 513.0,641.0 234×234 |  | mira em E2/E3 |
| `aim_chefe_sozinho.png` | completo | chefe_sozinho | 518,395 416×416 | 518,395.0 416×416 |  |  |

## `assets/icons/elements`

| arquivo | modo | estado | texture_rect | node | raio | nota |
|---|---|---|---|---|---|---|
| `badge_dragon.png` | completo | padrao | 124,592 31×30 | 127.5,594 26×26 |  | selo redondo do chip (13pt) |
| `badge_dark.png` | completo | padrao | 339,564 31×30 | 342.2,566 26×26 |  | selo redondo do chip (13pt) |
| `badge_knight.png` | completo | padrao | 232,734 31×30 | 234.9,736 26×26 |  | selo redondo do chip (13pt) |
| `badge_light.png` | completo | padrao | 95,920 31×30 | 98.2,922 26×26 |  | selo redondo do chip (13pt) |
| `badge_nature.png` | completo | padrao | 368,928 31×30 | 371.5,930 26×26 |  | selo redondo do chip (13pt) |

## Ícones (`assets/icons/`)
Cada ícone existe como `.svg` (fonte, cor final embutida) e PNG 48 e 96.
- `elements/emblem_<elemento>` — emblemas creme das cartas (dragon, knight, nature, light, dark, wild, capsule)
- `elements/badge_<elemento>.png` — selo redondo do chip (fundo na cor da carta + emblema)
- `currency/` — bits, gemas, energia
- `nav/` — equipe, invocar, loja; fases em versão normal e principal
- `ui/` — menu e coroa (normal, ativa, recarga)

## Cartas (`assets/cards/`)
- `card_<elemento>@1x|2x|4x.png` — arte completa **sem número** (76×88 no 1x; na tela 1024 usa 152×176 = @2x)
- `card_value_plate.png` — placa do número (texto Martian Mono 19px branco, peso 600)
- `card_frame_selected.png` — anel âmbar da carta selecionada; a carta sobe 10px
- `card_order_badge.png` — selo 28×28 âmbar com o índice do combo (texto `#1A1105`, 16px, 600)
- Na fila, a mesma arte reduzida para 32×38.
