# HUD do inimigo — contrato

Espaco: **STAGE** (888 x 560) para posicao; **ENEMY_PLATE** (32k x 12k) para o
conteudo da placa. `k` = escala da formacao (4 ou 6).

## 1. Placa por escala (tabela literal)

| medida | k = 4 (trios/quintetos) | k = 6 (duo/boss) |
| --- | --- | --- |
| placa (pw x ph) | 128 x 48 | 192 x 72 |
| digito do TURN | 14 x 16 | 21 x 24 |
| digito em | (46, 4) | (69, 6) |
| label TURN em | (62, 4) | (93, 6) |
| label TURN w | 48 | 72 |

Formula: `pw = 32k, ph = 12k, dw = round(3.5k), dh = 4k,
digito_x = round(11.5k), label_x = round(15.5k), label_w = 12k, y = k`.

## 2. Arvore de nos

```
EnemyUnit            Control  (left, top) do STAGE
├── PLATE            Control  pw x ph        (nao clipa)
│   ├── plate        TextureRect inset 0     enemy_turn_plate_<el>_v1.png
│   ├── digit        TextureRect             enemy_digits_sheet_v1.png (celula dw x dh)
│   ├── label        TextureRect             enemy_label_turn_v1.png
│   ├── well         TextureRect inset 0     enemy_hp_well_v1.png
│   └── FILL_CLIP    Control (0,0,pw*hp%,ph) clip_contents = TRUE
│       └── fill     TextureRect (0,0,pw,ph) enemy_hp_fill_v1.png
├── total_chip       (margin-top 5) so quando ha dano acumulado
├── SPRITE_BOX       Control sprite x sprite     <- image-slot / arte do inimigo
│   └── aim_ring     borda 2 px #c9a842 + glow, so em modo de mira
└── popups           empilhados fora do SPRITE_BOX, z acima (ver ANIMACOES_V2 §3)
```

## 3. Ancoragem

`left = clamp(cx - pw/2, 8, 888 - pw - 8)`, `top = y` (ambos da tabela de
formacao). O `cx` da formacao e o **centro** do inimigo, nao a borda.

## 4. Assets

| asset | nativo | escalas legais | uso |
| --- | --- | --- | --- |
| `enemy/enemy_turn_plate_<el>_v1.png` | 384 x 144 | 1/3 (128x48), 1/2 (192x72) | moldura da placa |
| `enemy/enemy_hp_well_v1.png` | 384 x 144 | 1/3, 1/2 | trilho de HP |
| `enemy/enemy_hp_fill_v1.png` | 384 x 144 | 1/3, 1/2 | preenchimento (clipado) |
| `enemy/enemy_label_turn_v1.png` | 144 x 48 | 1/3 (48x16), 1/2 (72x24) | palavra TURN |
| `enemy/enemy_digits_sheet_v1.png` | 420 x 48 | 1/3 (140x16), 1/2 (210x24) | 10 digitos, celula 42x48 |

Todas as reducoes acima **sao inteiras** (1/3 e 1/2) — mantenha `k` em 4 ou 6.

## 5. Checklist

- [ ] `FILL_CLIP.clip_contents == true`; o fill cresce por largura, nunca `scale`
- [ ] Cinza de morte na placa e no corpo, nao no wrapper
- [ ] Modo de mira liga `mouse_filter` no corpo; fora dele, IGNORE
- [ ] `k` apenas 4 ou 6 (escalas inteiras das folhas)
