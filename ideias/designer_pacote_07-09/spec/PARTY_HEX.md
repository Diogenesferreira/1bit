# Faixa do party — modelo hexagonal (01/09/2026)

Substitui a faixa de 5 selos quadrados 1A. **Só esta seção mudou**; todo o resto da tela segue
`LAYOUT_BATALHA.md`. Os selos quadrados 1A continuam válidos, mas agora nas telas de coleção /
montagem de time, não na batalha.

## Medidas (px de design, viewport base 940×1685)

| item | valor |
|---|---|
| altura da faixa | **246** (14 padding topo + 218 do líder + 12 padding base + 2 filetes) · largura 890 |
| fundo | `#121311`, filete 1 px `rgba(201,192,168,.22)` em cima e embaixo |
| padding | 14 / 0 / 12 · slots distribuídos com `space-between` e 18 px de recuo lateral · alinhamento `flex-end` |
| ordem | **2 – 1 – 2**: aliado · aliado · **LÍDER** · aliado · aliado |
| trilho | linha 2 px `rgba(201,192,168,.16)` atravessando a faixa na altura y=96, atrás dos hexágonos |
| cantos | 4 cantos em L 14×14 (traço 2 px `rgba(201,192,168,.45)`) a 12 px das bordas — mesma linguagem do palco |

### Slot de aliado — 132 × 168
(marcador 10 + gap 5 + hex 138 + gap 5 + medidor 10)
- marcador 10 px (vazio, ou losango 9×9 vazado para convidado)
- hexágono **132 × 138** = asset 44×46 lógico a **3×**
- medidor 132 × 10: calha `#121211`, borda 1 px `rgba(201,192,168,.4)`, 8 segmentos (14 px cheio + 2 px vão) na cor do elemento
- retrato: sprite `hero_<id>.png` a **3× (96×120)**, 20 px abaixo do topo do hexágono

### Slot do líder — 132 × 152
- hexágono **132 × 138** = asset 44×46 lógico a **3×**, sobe 6 px em relação aos aliados
- moldura `hex_frame_leader_<el>_3x.png`: contorno tinta 1 px + **anel dourado `#c9a842` 2 px** + anel do elemento 5 px
- coroa `crown_leader.png` (13×6 lógico a 4× = 52×24) encaixada no topo, y = −11
- dois losangos 9×9 `#c9a842` nas laterais, y = 62
- glow `drop-shadow(0 0 8px rgba(201,168,66,.5))`
- medidor 132 × 10 com **borda dourada**, 8 segmentos (14 px + 2 px)
- retrato: sprite a **3× (96×120)**, 20 px abaixo do topo

## Anatomia do hexágono

Asset lógico **44 × 46**, aba curta de 8 linhas (17,8%). Anéis, de fora para dentro:
tinta `#14140f` 1 px → bone `#c9c0a8` 2 px (ou **ouro** no líder) → cor do elemento 4 px (5 no líder).
Interior transparente.

| arquivo | tamanho | uso |
|---|---|---|
| `hex/hex_frame_<el>.png` | 132×138 | moldura de aliado (3×) |
| `hex/hex_frame_leader_<el>.png` | 176×184 | moldura de líder (4×, anel dourado) |
| `hex/hex_plate_3x.png` | 132×138 | fundo `#0b0d0a` do retrato (aliado) |
| `hex/hex_plate_4x.png` | 176×184 | fundo do retrato (líder) |
| `hex/hex_frame_<el>_2x.png` | 88×92 | versão compacta (listas, HUD reduzido) |
| `hex/crown_leader.png` | 52×24 | coroa do líder |

`<el>` = dragon · knight · nature · light · dark.

**No Godot** a placa e a moldura são dois `TextureRect` no mesmo Rect e o retrato entra no meio,
recortado por um `Control` com `clip_contents` + máscara hexagonal (ou um `Polygon2D` com a mesma
silhueta). Nunca use `clip-path` "suave": a máscara tem de seguir os degraus do pixel do asset,
senão sobram cantos escuros — foi exatamente o bug que apareceu na versão web.

## Personagens

Sprites `hero_<id>.png` no template **32 × 40 lógico** (ver `PERSONAGENS_32x40.md`).
Escalas usadas na batalha: **3×** (aliado), **4×** (líder), 4× e 6× (palco / chefe).
