# Layout da tela de batalha — especificação exata (v2, 2026-08-31)

Fonte da verdade: `html/UI Batalha 1bit.dc.html` (abra no navegador; é a tela renderizada).
Dados legíveis por máquina: `spec/layout_batalha.json` — **use esse arquivo no Codex**, ele tem todos os números.

## 0. Resolução e escala (leia antes de tudo)

| item | valor |
|---|---|
| viewport base do projeto | **940 × 1685** (é o tamanho exato do design; 1 px design = 1 px do viewport) |
| proporção | 0,558 (≈ 9:16,1 — praticamente a tela de um celular) |
| Godot: Stretch Mode | `canvas_items` |
| Godot: Aspect | `expand` |
| Godot: Scale Mode | `fractional` (ou `integer` se quiser pixel perfeito com tarja) |
| Filtro de textura padrão do projeto | **Nearest** (Rendering > Textures > Canvas Textures > Default Texture Filter = Nearest) |
| Snap 2D | ligue `snap_2d_transforms_to_pixel` e `snap_2d_vertices_to_pixel` |

Em 1080×1920 o Godot escala por 1,139 e sobra ~9 px de largura, que o `expand` preenche com o
fundo `#080908`. Nada é cortado. **Nunca** desenhe nada dependendo de px físicos: trabalhe sempre
em px de design.

## 1. Pilha vertical (nada rola, nada reflui)

| # | seção | y | altura |
|---|---|---|---|
| 1 | barra de conta | 25 | 64 |
| 2 | palco (mapa) | 103 | 560 |
| 3 | régua PARTY | 679 | 18 |
| 4 | faixa dos 5 selos | 711 | 222 |
| 5 | BAG | 947 | 160 |
| 6 | régua HAND | 1121 | 18 |
| 7 | mão (5×2 cartas) | 1153 | 446 |
| 8 | rodapé (life) | 1615 | 41 |

Coluna de conteúdo: **x = 25, largura = 890**. Molduras: card 940 de largura, fundo `#0d0e0c`,
borda externa 2 px `#2b2b28`, padding 10; moldura interna 1 px `rgba(201,192,168,.30)`, padding 14, gap 14.

## 2. Barra de conta (h 64)

`[emblema 58×58] [nome + LV / barra de XP] ——— [moeda] [gema] | [energia] [menu]`

- **Emblema**: 58×58, borda 2 px `rgba(201,192,168,.6)`, fundo `#141512`, foto com `inset:3` sobre `#0b0d0a`;
  blocos de canto 8×8 `#c9c0a8` no topo-esquerdo e na base-direita (encaixe visual, não recortar).
- **Nome**: `ui/val_account.png` (altura 17) — gerado da fonte bitmap; troque em runtime pelo nome real.
- **LV**: caixa 1 px `rgba(201,192,168,.35)`, padding 2/5 → `lbl_lv` (11, alpha .6) + `val_lv` (12).
- **XP**: `lbl_xp` (11) + calha **214×13** (borda 1 px `rgba(201,192,168,.5)`, fundo `#121211`, padding 2)
  com preenchimento em listras de 3 px `#c9c0a8`/`#8f886f` + `val_xp` (11).
- **Moeda** hexágono 17×17 `#c9a842` + valor, **largura reservada 82**.
- **Gema** losango 15×18 `#7a5f9a` + valor, **largura reservada 68**.
- **Energia** (após divisor 1 px) raio 16×26 `#c9a842` + `val_energy`, **largura reservada 86**.
  As larguras reservadas existem para o número crescer sem empurrar o layout — respeite-as.
- **Menu**: 3 barras 34×5 `#c9c0a8`, gap 6.

## 3. Palco (890 × 560, área útil 888 × 558)

- Fundo `#101210` + arte do cenário em `cover`, recorte ligado (`clip_contents`).
- Cantos em L 16×16 (traço 2 px `#c9c0a8`) nos quatro vértices, a 6 px das bordas — decorativos.
- **Plaquinha de progresso** no canto inferior esquerdo (x 22, bottom 20):
  `STAGE` + `2/3` + divisor + 3 nós + `BOSS`.
  Nó feito: losango 12×12 `#c9c0a8`. Nó atual: 15×15 `#7d9455` com borda 2 px `#c9c0a8` e glow 8 px.
  Nó boss: 17×17 `#2a1512` com borda 2 px `#c04a3e`. Conectores 20×2.
  **Regra**: 3 nós por fase normal, o último é sempre o boss; ao avançar, o nó anterior vira "feito".

## 4. Inimigos — placa de life/turno e formações

A placa é montada por fórmula a partir de um fator inteiro **k**:

| medida | fórmula | k=6 | k=4 |
|---|---|---|---|
| placa | 32k × 12k | 192×72 | 128×48 |
| dígito do turno | 3,5k × 4k em x=11,5k, y=k | 21×24 | 14×16 |
| sheet de dígitos | 35k de largura | 210 | 140 |
| label TURN | 12k × 4k em x=15,5k | 72×24 | 48×16 |
| preenchimento de HP | largura = placa × hp | — | — |

Só use **k ∈ {12, 6, 4, 3}** — são os divisores inteiros dos assets de origem (384×144 / 144×48 / 420×48).

Camadas, de baixo para cima: `enemy_turn_plate_<el>` → dígito do turno → `enemy_label_turn` →
`enemy_hp_well` → `enemy_hp_fill` recortado pela largura do HP. O sprite do inimigo fica **7 px
abaixo da placa**, centralizado nela.

### Formações (x = centro da placa, y = topo, dentro do palco 888×558)

| fase | k | placa | sprite | posições (cx, y) |
|---|---|---|---|---|
| **Boss** (1) | 6 | 192×72 | 330 | (444, 34) |
| **2 inimigos** | 6 | 192×72 | 236 | (256, 44) · (632, 44) |
| **3 inimigos** | 4 | 128×48 | 190 | (154, 26) · (444, 214) · (734, 26) |
| **5 (especial)** | 4 | 128×48 | 150 | (124, 18) · (444, 18) · (764, 18) · (278, 272) · (610, 272) |

Regra de conteúdo: fases normais alternam **3 → 2 → boss**; fases especiais chegam a 5.
A placa nunca cresce além de k=6: o destaque é do mapa.

## 5. Faixa dos 5 selos (h 222)

Faixa `#121311` com filetes 1 px `rgba(201,192,168,.22)` em cima e embaixo, padding 16/8/12, gap 8.
Cada selo: **165×165** (metade exata do asset 1A de 330×330).

1. foto do personagem — janela **x 18, y 15, 129×99** (área segura 258×198 no asset), fundo `#0b0d0a`, `contain`;
2. `seal_1a_<el>_empty.png` a 165×165;
3. quadro do `seal_1a_<el>_charge_sheet.png` (330×2970 = 9 quadros) exibido a 165×1485, deslocado em `-n×165`.

O slot **ativo** sobe 16 px, ganha `drop-shadow 0 0 7px` na cor do elemento, dois cantos em L 16×9
acima e um triângulo 11×6 abaixo. O **líder** usa os 3 blocos; o **convidado**, o losango vazado.

## 6. BAG (h 160)

Painel 1 px `rgba(201,192,168,.35)` sobre `#101210`, padding 16/16/14. Aba `BAG` em x 12, y −9.
Fila de **8 cartas 78×108** distribuídas com `space-between`; depois divisor, seta 12×18 e o bloco
**NEXT** — rótulo `lbl_next` (14) e **uma carta 78×108 exatamente igual às da fila** (sem moldura,
sem numeral). A carta do NEXT é sempre o próximo item real do baralho.

## 7. Mão (h 446)

Grid 5 colunas × 2 linhas de **156×216** (2× o asset), gap 14, centralizado.
Numeral em x 14, y 14, célula 21×24 do sheet a 210 de largura.
Carta selecionada: contorno 2 px na cor do elemento com offset 2. Slot vazio: tracejado + losango 22×22.

## 8. Rodapé — life (h 41)

Coração 28×26 `#c04a3e` + `lbl_hp` (12, alpha .6) + calha `flex:1` de 22 px de altura
(borda 1 px `rgba(201,192,168,.55)`, fundo `#121211`, padding 3) preenchida com **vermelho sólido
`#c04a3e`** + valor `val_hp_curr` (15). Sem textura, sem listras, sem contorno interno.
