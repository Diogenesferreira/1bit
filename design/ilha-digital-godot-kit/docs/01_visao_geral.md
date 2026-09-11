# 01 · Visão geral

Tela de batalha vertical **1024 × 1600**, fundo `#16130D`.

## Blocos (de cima para baixo)
| bloco | x | y | w | h |
|---|---|---|---|---|
| header | 0 | 0 | 1024 | 132 |
| strip | 0 | 132 | 1024 | 92 |
| visor | 24 | 232 | 976 | 736 |
| team | 24 | 984 | 976 | 38 |
| bank | 24 | 1040 | 976 | 419.6 |
| bank_grid | 24 | 1094 | 976 | 365.6 |
| nav | 24 | 1480 | 976 | 100 |

O aviso (`toast`) só existe quando aparece — ver estado `alertas`.

## Camadas do visor (de trás para frente)
1. **Cenário** — `background/bg_*_visor_976x736.png` (recorte x 24–1000 / y 232–968 da arte 1024×1600)
2. **Personagens** — para cada posição: anel de chão (under/progress/over) e por cima o sprite
3. **Película** — `visor_film_scanline_976x736.png` e depois `visor_film_vignette_976x736.png`
4. **HUD do visor** — cantoneiras, SETOR/ROUND, mira, chips, pop-up do alvo

O visor tem cantos de raio 32 — use `visor_mask_976x736.png` (ver 06_godot.md) e por cima `hud/visor/visor_frame.png`.

## Estados renderizados (`reference/screens/`)
| arquivo | o que mostra |
|---|---|
| `screen_padrao_1024x1600.png` | tela como abre: Tropical, indicador anel, pop-up fechado |
| `screen_alvo_chefe_1024x1600.png` | toque no chefe: mira + pop-up ao lado (não cabe acima) |
| `screen_alvo_inimigo_1024x1600.png` | toque em E2: mira + pop-up acima |
| `screen_chefe_sozinho_1024x1600.png` | formação do último nível |
| `screen_deserto_1024x1600.png` | cenário Deserto |
| `screen_cartas_selecionadas_1024x1600.png` | duas cartas escolhidas, combo 2/3, líder ativo |
| `screen_skill_pronta_1024x1600.png` | aliado com skill 100%: anel com brilho e chip PRONTA |
| `screen_alertas_1024x1600.png` | ataque iminente, HP da equipe em alerta, líder em recarga, aviso âmbar |
| `screen_aviso_vermelho_1024x1600.png` | aviso de ataque sofrido |
| `screen_aviso_menta_1024x1600.png` | aviso de cura |
| `screen_indicador_minimo_1024x1600.png` | variação antiga: fio fino sob os pés |
| `screen_indicador_placa_1024x1600.png` | variação antiga: placas |

`reference/overlays/layout_debug_1024x1600.png` mostra os retângulos das peças principais com o nome de cada uma.
