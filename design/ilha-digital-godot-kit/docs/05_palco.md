# 05 · Palco

## Cenário
- Arte fonte: `background/bg_<nome>_1024x1600.png`. O visor mostra só **x 24–1000, y 232–968** → já recortado em `bg_<nome>_visor_976x736.png`.
- Horizonte por volta de 27–38% da altura do visor; chão andável dos 40% para baixo.
- O cenário **Trevas** veio corrompido no zip original e não entrou.

## Personagens
PNG com fundo transparente. **Pé** em (128, 248) nos quadros 256 e (256, 504) no quadro 512 do chefe.
Posicione cada sprite pelo pé; a largura do quadro na tela já cria a perspectiva (atrás menor, frente maior).

| slot | nome | papel | elemento | pé no visor | pé em px | quadro px | anel rx×ry | topo do chip |
|---|---|---|---|---|---|---|---|---|
| A1 | Crimson Clamp | aliado | dragon | 15% · 46% | 170.4, 570.6 | 200 | 68×20 | 592.6 |
| A2 | Bone Raider | aliado | dark | 37% · 42% | 385.1, 541.1 | 192 | 66×20 | 563.1 |
| A3 | Panda Gunner | aliado | knight | 26% · 65% | 277.8, 710.4 | 212 | 72×22 | 734.4 |
| A4 | Twin Apes | aliado | light | 12% · 90% | 141.1, 894.4 | 228 | 78×24 | 920.4 |
| A5 | Flora Fairy | aliado | nature | 40% · 91% | 414.4, 901.8 | 228 | 78×24 | 927.8 |
| E1 | Long Ear Guardian | chefe (trio) | light | 76% · 50% | 765.8, 600.0 | 336 | 114×34 | 636.0 |
| E2 | Dusk Dragon | inimigo | dark | 62% · 88% | 629.1, 879.7 | 252 | 86×26 | 907.7 |
| E3 | Twin Tail | inimigo | nature | 87% · 90% | 873.1, 894.4 | 252 | 86×26 | 922.4 |
| BOSS | Long Ear Guardian | chefe sozinho | light | 72% · 80% | 726.7, 820.8 | 448 | 152×46 | 868.8 |

- Trio: A1–A5 + E1 (chefe) + E2 + E3. Chefe sozinho: A1–A5 + BOSS (E2/E3 somem).
- Ordem de desenho (trás → frente): A2, A1, E1, A3, E2, A4, E3, A5 (sozinho: A2, A1, A3, BOSS, A4, A5).
- Elementos atribuídos por aparência, para teste.
- Personagem abatido: 35% de opacidade + escala de cinza.

## Anel de chão
- Centro no pé. `rx = quadro × 0.34`, `ry = rx × 0.3` (valores prontos na tabela).
- Texturas por slot: `hud/stage/ring_<slot>_under.png` (trilho + sombra), `_progress.png` (anel cheio em branco), `_over.png` (marcas).
- Aliado: progresso = **skill**, cor do elemento (vivas, ver 03_tema). Com 100%: brilho da cor do elemento + chip com moldura âmbar e "PRONTA".
- Inimigo: progresso = **vida**, `#FF4A3A`. Começa no ponto mais à direita e enche no sentido horário (a frente enche primeiro).

## Chip
- Pilula `hud/stage/chip_ally_box.png` / `chip_enemy_box.png`, altura 30px, centralizada no pé, topo = pé + ry + 2.
- Conteúdo: selo 26px (`icons/elements/badge_<elemento>.png`), "LV" Instrument Sans 12px 70%, número Martian Mono 15px peso 600 com **largura mínima de 30px** (3 dígitos).
- Inimigo: 3 segmentos 10×5 + número de turnos. Cores: 3 = âmbar 75%, 2 = âmbar, 1 = `#FF6B4A` piscando.
- Alvo: `chip_frame_target.png` (anel vermelho). Skill pronta: `chip_frame_ready.png`.

## Mira
4 cantoneiras vermelhas `#FF6B4A` (braço 34px, traço 3px), quadrado de lado `round(quadro×0.97)×0.96`, centrado no meio da altura do personagem. Pisca de 60% a 100% em 1.4s.
Referências: `hud/visor/aim_chefe.png`, `aim_inimigo.png`, `aim_chefe_sozinho.png`.

## Pop-up do alvo
- **Fechado por padrão.** Toque no inimigo → abre e marca o alvo. Toque no mesmo → fecha. Outro inimigo → troca.
- Largura 344px. Se couber acima da cabeça (topo da cabeça − 148 − 24 > 52): abre **acima**, centralizado no alvo (limitado às bordas), seta `popup_target_arrow_down.png`.
- Senão abre **ao lado esquerdo**, no topo do visor (y = visor + 56), seta `popup_target_arrow_right.png`.
- Conteúdo: "ALVO · LV40" (tick vermelho) · % (tick 42%) · nome (Instrument Sans 21px 700) · barra de vida segmentada · "1850 / 4000 HP" (Martian Mono 16px 55%) · caixa ATQ com 3 segmentos e número.

Todos os números estão em `data/stage_positions.json`.
