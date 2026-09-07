# Paleta fechada

Nenhuma cor fora desta tabela entra na tela. Elementos tem base + lit; o resto
e chrome neutro.

## 1. Elementos

| elemento | base | lit | usos |
| --- | --- | --- | --- |
| dragon | `#a8443a` | `#d9705f` | anel do card, pips, popup, faixa da carta |
| knight | `#5a86a8` | `#8ab6d4` | idem |
| nature | `#7d9455` | `#a8c07a` | idem + no "atual" da trilha de stage |
| light | `#c9a842` | `#f0d478` | idem + chrome de leader/energia |
| dark | `#7a5f9a` | `#a37fd0` | idem |
| heal (reservado) | `#b09a72` | `#d0bb92` | carta de cura (arte existe, regra nao) |

## 2. Chrome

| token | hex | uso |
| --- | --- | --- |
| bone | `#c9c0a8` | **borda de toda carta** (sample do proprio PNG), trilhos, filetes |
| bone-lit | `#e8e3d4` | texto de destaque, lua do backdrop |
| bone-mute | `#8f886f` | texto secundario, linha de teste |
| ink | `#14140f` | corpo de placa, fundo de trilho |
| plate | `#0d0e0c` | corpo de card, selo, plate de STAGE (`#0b0d0a`) |
| plate-2 | `#121211` | caixas de contador, fundo da barra de skill |
| plate-3 | `#141512` | plate da energia, moldura do emblema |
| slot-off | `#1a1a16` | pip apagado, no futuro da trilha |
| edge-dark | `#2a2620` | ponta do fill da barra de life |
| boss-edge | `#c04a3e` | borda do no do boss |
| boss-bg | `#2a1512` | miolo do no do boss |
| flash | `#f4ecd8` | flash de tela e de carga |
| page-bg | `#080908` | fundo fora do quadro |
| frame-out | `#2b2b28` | borda externa de 2 px do quadro |

## 3. Alphas usados

`rgba(201,192,168,X)` — X = .15 (slot vago) / .22 (ENTRADA vaga) / .25 / .28 /
.30 / .32 (borda de contador) / .35 / .45 (borda de barra) / .5 / .55 (borda
forte) / .6 (emblema). Nunca invente um alpha novo — reaproveite um destes.

## 4. Regra de aplicacao

- A **borda** de card/placa e sempre bone. Quem carrega a cor de estado e uma
  **faixa** (3 px) ou o **anel interno** — nunca o contorno externo.
- Dourado (`#c9a842`) fora de light = chrome de leader/energia, nao elemento.
- Texto sobre arte precisa de placa opaca atras (ver popup de dano).
