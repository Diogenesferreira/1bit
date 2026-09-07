# CHANGELOG — desde o export de 06/09/2026

Tudo que mudou entre o pacote de 06/09 e este (07/09/2026). O que nao esta
listado aqui nao mudou.

---

## 1. Telas novas / alteradas

| tela | mudanca |
| --- | --- |
| `UI Batalha 1bit.dc.html` | **deixou de ser mockup estatico e virou tela jogavel**: regra de mao completa, fusao, cascata, skills, progressao de stage |
| `Laboratorio de Animacoes.dc.html` | mantido como canvas de teste; a tela principal agora tem as mesmas animacoes |

## 2. Regras de comportamento NOVAS

| regra | detalhe |
| --- | --- |
| **Campo de 12 casas** | 2 fileiras de 5 (mao) + a COLUNA 6 de cada fileira (ENTRADA), que comeca **vazia**. Porta de `EstadoBatalha.gd`. |
| **Toque marca, nao ataca** | 1a e 2a carta marcadas levantam na propria casa e **uma carta do BAG desce** na ENTRADA da fileira. A 3a do mesmo elemento **fecha o trio sozinha** (nada desce). |
| **Desmarcar devolve** | tocar numa marcada desfaz e a carta que desceu volta pro fim da fila do BAG. |
| **Abandono de cadeia** | tocar em elemento diferente devolve tudo e comeca cadeia nova. |
| **Cascata** | fechado um trio, todo trio pronto no resto da mao dispara sozinho, **+30% de dano por elo**. |
| **Renovacao** | sobrou <= 1 carta na mao -> a mao inteira se renova e a corrente continua. |
| **Fim de corrente** | ENTRADA entra na mao -> BAG chove o resto -> mao redistribui (agrupada por elemento, valor crescente) -> **so entao** o dano acumulado aplica de uma vez. |
| **Mao sempre jogavel** | porta de `_garantir_saida`: mao sem trio possivel nunca chega ao jogador (uma carta orfa vira o tipo mais abundante). |
| **BAG anda esq -> dir** | a carta que desce e a **mais a direita** (`bag[7]`, junto do NEXT); a nova entra pelo slot 0. |
| **Botao ATACAR removido** | os toques resolvem tudo. |
| **Energia nunca dispara sozinha** | fica liberada esperando o clique. |
| **Leader tem MIRA** | o clique entra em modo de mira; o jogador escolhe o alvo. Cooldown 4 turnos. |
| **Skill de aliado** | com a barra cheia (8 pips), aparece um **botao no proprio card**; clicar consome a carga e da um golpe. |
| **Progressao de stage** | 1/3 (3 inimigos) -> 2/3 (2 inimigos) -> 3/3 (boss). Antes o palco respawnava a mesma formacao pra sempre. |

## 3. Animacoes — tempos antigos -> novos

| animacao | 06/09 | **07/09** |
| --- | --- | --- |
| passo da cascata de dano | 95 ms por carta | **90 ms por elo da cadeia** (o dano agora e por trio, nao por carta) |
| fusao — convergencia | 620 ms, cartas de 26x36 no palco | **70 -> 560 ms, cartas de 138x191 no centro da mao** |
| fusao — aquecimento | nao existia | **400 ms** (560 -> 980) de `brightness` 1 -> 3.6 |
| fusao — estouro | 1080 ms, circulo simples 150 px | **980 ms**, nucleo radial 230 px + **2 ondas de choque** + **12 estilhacos** |
| fusao — feixe/projetil | projetil no palco, 520 ms | **feixe 28x300 na mao (500 ms) + orbe que viaja 500 ms ease-in-out** |
| fusao — carga no aliado | 1980 ms | **1780 ms** |
| popup de dano | 950 ms, empilhado em coluna (lane * 26 px) | 950 ms, **espalhado em 8 posicoes (SCATTER)**, fonte 26/32 px, placa opaca |
| tremor do inimigo | 300 ms, amp 7 | 300 ms, **amp 6** |
| barra de HP/energia | 420 ms | 420 ms (sem mudanca) |
| flash de tela | 450 ms | 450 ms (sem mudanca) |
| troca de stage | 520 ms | **480 ms + crossfade de backdrop de 600 ms** |
| selecao de carta | levanta 14 px | levanta **14 px** + rim 2 px + **pulso de 340 ms** |
| fila do BAG | nao existia | **220 ms** de slide-in pela esquerda |
| carta caindo do BAG | nao existia | **380 ms** ease-out cubic |
| embaralhar a mao | nao existia | **260 ms + 20 ms de stagger por casa** |
| skill pronta | risco fino de 2 px | **faixa de 900 ms + barra pulsando 1400 ms + botao pulsando 1100 ms** |
| banner do leader | nao existia | **220 ms** de entrada |

## 4. Numeros de layout que mudaram

| medida | 06/09 | **07/09** |
| --- | --- | --- |
| teto da energia | 20 | **999** (caixa de 90 px ja reservava) |
| caixa da moeda | rack unico com filete | **caixa propria**, gap 8 entre moeda e gema |
| caixa da gema | idem | **caixa propria** (64 px reservados) |
| emblema da conta | 58 x 58 | **68 x 68** (pips 8 -> 9 px, linha 64 -> 72) |
| mao | 8 cartas em fileira unica | **12 casas: 6 colunas x 2 linhas, celula 138x191, gap 12** |
| grade da mao | — | **888 x 394** |
| palco | 560 (sem backdrop) | 560 **com backdrop 888x560** |
| barra de life | altura 24, tiles de PNG | altura **24, dither procedural**, borda 3 px |
| botao do leader | botao de texto, altura 32 | **card**: altura 34, borda bone 2 px, faixa de estado 3 px, icone burst 14 px |
| marca de lider no card | placa "LEADER" 117 x 22 | **losango 14 x 14** em (-4,-4) |

## 5. Assets — novos, renomeados, aposentados

### Novos
| arquivo | nativo | motivo |
| --- | --- | --- |
| `backdrops/stage_plains_v1.png` | 222 x 140 | backdrop do stage 1/3 |
| `backdrops/stage_forest_v1.png` | 222 x 140 | backdrop do stage 2/3 |
| `backdrops/stage_sea_v1.png` | 222 x 140 | backdrop do boss |
| `cards/card_face_*.png` (5) | 78 x 108 | pasta nova, so as faces **em uso** |

### Removidos do projeto
| arquivo | motivo |
| --- | --- |
| `stage-grass-mountains.png`, `stage-forest-night.png`, `stage-night-sea.png` | eram **screenshots do jogo de referencia com o HUD e os personagens deles embutidos na foto** — era de la que vinha o "hexagono roxo 1 TURN" fantasma no palco |

### Aposentados (ficam no pacote, nao sao mais usados)
| arquivo | substituido por |
| --- | --- |
| `ui/hp_tile_field.png`, `ui/hp_tile_fill.png` | dither procedural de 3 px |
| `ui/ui_font_sheet_v1.png` | `ui/font_1x_v1.png` (folha 1:1) |
| `ui/lbl_lv.png`, `val_lv.png`, `lbl_xp.png`, `val_xp.png`, `lbl_stage.png`, `val_stage.png`, `lbl_boss.png`, `val_coin.png`, `val_gem.png`, `val_energy.png`, `lbl_hp.png`, `val_hp*.png` | `BitmapFontLabel` na folha 1:1 |
| `card_party/crown_leader.png` | losango de 14 px |

### Contrato de nomes
Nenhum `<id>` mudou. Nenhum `_vN` foi sobrescrito: os backdrops novos entraram
como `_v1` em nomes novos (`stage_plains_v1`, nao `stage-grass-mountains`).

## 6. Correcoes de bug (uteis pro Godot saber)

| bug | causa | licao pro Godot |
| --- | --- | --- |
| inimigo/carta fantasma na tela | listas sem `id` estavel no `sc-for` | toda lista repetida precisa de chave estavel; em Godot, reusar nos por id em vez de recriar |
| numerais das cartas com pixel vizinho sangrando | celula fracionaria (sheet 186 px em caixa de 19 px) | `sheet_w = celula * n`, sempre inteiro |
| fontes borradas | folhas de 48 px reduzidas para 16 px (escala fracionaria) | folhas 1:1 + `Filter = Nearest` |
| dano ilegivel sobre o inimigo | so glow, sem placa de contraste | placa opaca + contorno em 4 direcoes |
| STAGE ilegivel | plate com alpha .72 sobre foto | plate **opaco** `#0b0d0a` |
| heroi vazando do card | faltava `clip_contents` no FRAME | quem clipa, clipa explicitamente |

## 7. Pendencias conhecidas

1. **Escalas nao inteiras** de `card_face_*` (1.769x), `char_nature` (2.14x),
   `sym_*` (2.3x) — ver `spec/CONTRADICOES.md` secao 2. Reexportar resolve.
2. **Balanceamento e placeholder**: leader 60, skill de aliado 340, HP de
   inimigo 100. O 340 mata tres inimigos — numeros de leitura visual.
3. **Cura e Coringa** tem arte (`card_face_heal_v1`, `card_face_wild_v3`) mas
   **nao tem regra** na tela; `EstadoBatalha.gd` ja preve os dois.
4. **Estados nao capturados** em `reference/`: skill pronta, leader em mira,
   troca de stage (dependem de 4+ turnos).
5. Depois do boss o ciclo **reinicia em 1/3** — comportamento de laboratorio;
   no jogo, trocar por tela de resultado.
