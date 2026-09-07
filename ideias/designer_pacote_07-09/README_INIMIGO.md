# Inimigo — life e turno (v1)

Mesma linguagem 1-bit dos Selos de Fragmento. Canvas **384 × 144 px** RGBA, grade lógica **64 × 24**
(1 px lógico = 6 px de arquivo). Todas as camadas usam o MESMO canvas 384×144 e origem (0,0):
empilhe na ordem e tudo alinha sem cálculo.

## 1. Arquivos (pasta enemy/)

| arquivo | tamanho | uso |
|---|---|---|
| enemy_turn_plate_{el}_v1.png | 384×144 | socket elemental + placa do turno (sem texto) |
| enemy_hp_well_v1.png | 384×144 | calha do HP (igual para todos os elementos) |
| enemy_hp_fill_v1.png | 384×144 | barra vermelha cheia — recortar pela largura |
| enemy_digits_sheet_v1.png | 420×48 | dígitos 0–9, 10 células de **42×48** |
| enemy_label_turn_v1.png | 144×48 | palavra TURN |
| enemy_bar_{el}_preview_v1.png | 384×144 | composto de referência (3 TURN, HP 72%) |
| enemy_bar_sheet_v1.png | 384×720 | os 5 previews empilhados |

## 2. Geometria (px de arquivo)

- Socket elemental: x 0–71, y 0–71 (72×72), preenchido na cor do elemento.
- Placa do turno: x 84–383, y 0–71 (300×72). Interior `#1a1a18`, contorno `#c9c0a8`, cantos cortados 1 px lógico.
- Número do turno: **x 138, y 12** (célula de 42×48 da folha de dígitos).
- Rótulo TURN: **x 186, y 12** (144×48).
- Calha do HP: x 0–383, y 84–143 (384×60). Interior `#121211`.
- Barra do HP: área útil **x 12 → 372** (360 px), y 96–131 (36 px de altura).
  - topo `#d9695c` (1 px lógico), corpo `#c04a3e`, base `#8f3229` (2 px lógicos).

## 3. Regra do HP

`largura_visivel = 12 + hp * 360`  (hp de 0.0 a 1.0)

Recorte o `enemy_hp_fill` por largura (nunca escale a textura). Em Godot:
`AtlasTexture.region = Rect2(0, 0, 12 + hp * 360, 144)`.

## 4. Regra dos turnos — 1 a 5

O contador aceita **1, 2, 3, 4 e 5 turnos** (a folha de dígitos vai de 0 a 9, então 0 existe para o
disparo). Só um dígito é desenhado: nunca dois algarismos.

| valor | célula na folha | offset X |
|---|---|---|
| 0 (dispara agora) | 1ª | 0 |
| 1 | 2ª | −42 |
| 2 | 3ª | −84 |
| 3 | 4ª | −126 |
| 4 | 5ª | −168 |
| 5 | 6ª | −210 |

`offset_x = -valor * 42`

Ciclo: o inimigo entra com `turnos_max` (1–5), decrementa 1 a cada turno do jogador; ao chegar em
**0** ele ataca e o contador volta para `turnos_max`. `turnos_max` acima de 5 não é suportado pela
arte — quebra o layout de um dígito.

## 5. Animação

| evento | duração | curva | efeito |
|---|---|---|---|
| dano no HP | 420 ms | ease-out | largura da barra interpola até o novo valor |
| HP ≤ 25% | 700 ms | ease-in-out, loop | pulso de glow `#c04a3e` na barra (lê o alpha, segue a silhueta) |
| HP = 0 | 200 ms | snap | barra vazia; placa e calha vão a 45% de brilho e greyscale |
| turno −1 | 200 ms | ease-out | troca de célula do dígito, sem fade |
| turno = 0 (ataque) | 120 ms | snap | placa pisca para `#c9c0a8` por 1 quadro e volta |
| aparecer em cena | 200 ms | ease-out | fade + 4 px de subida |

Sem sombra externa suave. Nada de fonte de sistema: número e palavra vêm das folhas.

## 6. Import no Godot 4

Igual aos selos: **Filter = Nearest**, Mipmaps off, Fix Alpha Border off, Compress Lossless.
Script pronto em `godot/EnemyBar.gd`.
