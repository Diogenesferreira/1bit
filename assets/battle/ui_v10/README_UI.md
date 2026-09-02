# UI de Batalha 1-bit — pacote de produção

Data: 2026-08-30 · pixel de autoria da chrome = **6 px de arquivo** · personagem = **3 px** · tudo PNG RGBA com alpha binário (0 ou 255)

Este README cobre a **tela de batalha completa**. Os selos de personagem estão em `README.md`,
o life/turno do inimigo em `README_INIMIGO.md`, e as animações de fusão / dano / impacto em `README_VFX.md`.

---

## 1. Conteúdo

| pasta | arquivo | tamanho | uso |
|---|---|---|---|
| `ui/` | `card_face_{el}_v1.png` | 78×108 | **usar no jogo** — face de carta (arte aprovada) |
| `ui/` | `card_face_{el}_v2.png` | 156×216 | variante alternativa, mais detalhada (moldura com rebites + emblema grande). Não usada na UI atual |
| `ui/` | `lbl_*.png` | ver §4 | rótulos de texto em pixel art |
| `ui/` | `val_*.png` | ver §4 | valores numéricos pré-renderizados |
| `ui/` | `ui_font_sheet_v1.png` | 1440×48 | **fonte em bitmap** — 40 células de 36×48, gere qualquer rótulo em runtime |
| `char/` | `fam_*.png` | 222×237 | gabaritos de proporção das 5 famílias de silhueta |
| `char/` | `mount_*.png`, `var_*.png` | 330×330 | exemplos de personagem montado no selo |
| `html/UI Batalha 1bit.dc.html` | — | — | a tela inteira como referência viva (é a fonte desta especificação) |
| `godot/BattleUI.gd` | — | — | script de montagem: BAG, mão, HP, energia, formação |

`{el}` = `dragon` | `knight` | `nature` | `light` | `dark` | `heal` | `wild`

`heal` e `wild` **só existem como carta** — não têm moldura de personagem nem posição na formação.

---

## 2. Paleta canônica (não inventar cores)

| uso | hex |
|---|---|
| fundo da janela | `#080908` |
| fundo do painel | `#0d0e0c` |
| fundo de campo / poço | `#101210` · `#121311` |
| traço / contorno | `#201f1d` |
| osso (linha e texto) | `#c9c0a8` |
| osso claro (realce) | `#e8e3d4` |
| osso apagado | `#8f886f` |
| encaixe/segmento vazio | `#3a3a35` |
| HP | `#c04a3e` (topo `#d9695c`, base `#8f3229`) |
| energia / ouro | `#c9a842` |

Cores de elemento: `dragon #a8443a` · `knight #5a86a8` · `nature #7d9455` · `light #c9a842` · `dark #7a5f9a` · `heal #b09a72` · `wild` = osso `#e8e3d4`.

Sombra de elemento (62%): `dragon #6e2a24` · `knight #35566e` · `nature #4e5c35` · `light #8a7020` · `dark #4a3760` · `heal #6f5f45` · `wild #8f886f`.

**Máximo 2 cores de fundo por tela.** Nunca gradiente, nunca glow no asset (o glow é da UI, em runtime).

---

## 3. Layout da tela (px de arquivo, largura de referência 940)

Pilha vertical, nada rola, nada reflui. Moldura externa: `2px #2b2b28` + `1px rgba(#c9c0a8,.30)`, padding 14, gap 14.

```
┌─ TOP BAR ───────────────────────── altura 44 ─────────────────────────┐
│ FLOOR 07        ◧ ◇◇◇◇◇ ◧        ⚡ 12/20        ☰ (3×34×5)          │
├─ PALCO ────────────────────────── altura 560 ─────────────────────────┤
│  cantos em L 16×16 · placas de inimigo 192×72 posicionáveis           │
├─ PARTY (régua) ─────────────────── altura 18 ─────────────────────────┤
├─ FORMAÇÃO ──────── 5 selos de 165×165, gap 8, padding 16/8/12 ────────┤
├─ BAG ──────────────────────────── altura ~140 ────────────────────────┤
│  8 cartas 78×108 distribuídas (space-between) │ ▶ │ NEXT + 1 carta    │
├─ HAND (régua) ─────────────────────────────────────────────────────── │
├─ HAND ──────── 2×6 slots, cartas 138×191, gap 10 ────────────────────┤
├─ RODAPÉ ───────────────────────── altura ~50 ─────────────────────────┤
│  ♥ 9999/9999      XP ▮▮▮▮▮▯▯ 1360                                    │
└───────────────────────────────────────────────────────────────────────┘
```

### 3.1 Top bar
- `lbl_floor07.png` à esquerda, altura 24.
- Indicador de rodada no centro: quadrado 15×15 (elemento ativo, borda `#c9c0a8` 2px), 5 diamantes 9×9 rotacionados 45° (preenchidos = turnos gastos), quadrado 15×15 final (boss).
- **Energia** (era o "SP" do rodapé): raio 16×26 em `#c9a842` + `val_energy.png` (altura 18). Formato `12/20`.
- Menu: 3 barras de 34×5 em `#c9c0a8`, gap 6.

### 3.2 Palco
Área 940-ish × 560, fundo `#101210`, borda `1px rgba(#c9c0a8,.35)`, `overflow:hidden`.
Cantos em L de 16×16 (2px) nos quatro vértices — **decorativos, `pointer-events:none`**.
Placas de inimigo (192×72) posicionadas livremente; ver `README_INIMIGO.md`.

### 3.3 Formação (5 selos)
Faixa `#121311`, filete `1px rgba(#c9c0a8,.22)` em cima e embaixo.
Cinco selos de **165×165** (metade exata do asset 330×330), gap 8.

Empilhamento por selo, de baixo para cima:
1. arte do personagem — recorte `left 27, top 23, 111×118`, `clip-path: inset(0 round 55px 55px 0 0)`;
2. `fragment_seal_{el}_empty_v1.png` a 165×165 — **`pointer-events:none`**;
3. quadro do `charge_sheet` a 165×1485, `background-position: 0 -(n×165)`, n = 0…8 — **`pointer-events:none`**.

Marcadores por slot (acima do selo, faixa de 9 px de altura):
- **líder**: 3 blocos `#c9c0a8` (5×5, 5×9, 5×5), gap 3;
- **ativo**: dois cantos em L de 16×9 na cor do elemento + `drop-shadow(0 0 7px cor)` no selo + triângulo 11×6 apontando para baixo embaixo;
- **amigo/convidado**: 1 diamante 9×9 vazado;
- slots comuns: faixa vazia.

**Não há barrinha sob o personagem** — a carga de skill é o arco de 8 encaixes do próprio selo. Não duplicar.

### 3.4 BAG
Painel `1px rgba(#c9c0a8,.35)`, fundo `#101210`, padding `16 16 14`, `align-items:flex-end`, gap 14.
`lbl_bag.png` (altura 16) numa aba sobre a borda superior: `left 12, top -9`, fundo `#0d0e0c`, padding lateral 6.

- **Fila**: 8 cartas de **78×108**, `flex:1` + `justify-content:space-between` (gap resultante ~12).
  A fila é a sequência real do baralho, **da esquerda para a direita**. Sem `+`, sem separadores.
- **Divisor**: `border-left 1px rgba(#c9c0a8,.25)`, `padding-left 14`, `margin-left 8`.
- **Seta** 12×18 em `#c9c0a8` (`polygon(0 0,100% 50%,0 100%)`), `margin-bottom 46` para apontar para o meio da carta.
- **NEXT**: `lbl_next.png` (altura 14, opacidade .8) e, abaixo, **a mesma carta que encerra a fila**, 78×108, realce `box-shadow: 0 0 0 2px #c9c0a8` (usar box-shadow, não outline com offset — não muda o tamanho).
  Numeral: 10,5×12 a partir do sheet a `background-size:105px 12px` (meia escala exata de uma célula 21×24).

> Regra de estado: **a carta do NEXT é sempre o último item da fila.** Se divergirem, o jogador lê como bug.

### 3.5 Mão
Grid de 6 colunas × 2 linhas: cinco cartas iniciais e uma ENTRADA vazia por
fileira. Cartas de **138×191**, gap 10, centralizado. O tracejado pertence ao
slot e permanece sob a carta. Seleção usa apenas contorno, sem deslocamento.
Numeral em `left 14, top 14`, 21×24, sheet a `background-size:210px 24px` (1:1).
Carta selecionada: `outline: 2px solid <cor do elemento>` com `outline-offset: 2px`.
Slot vazio: `2px dashed rgba(#c9c0a8,.28)` com diamante 22×22 vazado no centro.

### 3.6 Rodapé
- **HP**: coração 28×26 em `#c04a3e` (`polygon(50% 100%,0 45%,0 18%,18% 0,50% 18%,82% 0,100% 18%,100% 45%)`) + `val_hp_9999.png` (altura 22). **Teto de 9999.**
- **XP**: `lbl_xp.png` (14) + calha `1px rgba(#c9c0a8,.55)` fundo `#121211` padding 2, altura 20, preenchida com listras verticais de 3 px alternando `#c9c0a8`/`#8f886f`, + `val_xp.png` (14).
- A energia **não** fica aqui — subiu para a top bar.

---

## 4. Escala dos assets — regra obrigatória

Todo asset só pode ser exibido em **múltiplo ou divisor inteiro** do tamanho de origem. Fora disso o pixel quebra.

| asset | origem | tamanhos legais |
|---|---|---|
| `card_face_*_v1` | 78×108 | 78×108 (BAG/NEXT) · 138×191 (HAND revisada) · 156×216 (2× legado) |
| `card_face_*_v2` | 156×216 | 156×216 · 78×108 · 52×72 · 312×432 |
| `fragment_seal_*` | 330×330 | 330 · 165 · 110 · 660 |
| `enemy_*` placas | 384×144 | 384×144 · 192×72 |
| `enemy_digits_sheet_v1` | 210×24 (10 células de 21×24) | célula 21×24 (1:1) · 10,5×12 (½) · 7×8 (⅓) |
| `ui_font_sheet_v1` | 1440×48 (40 células de 36×48) | 36×48 · 18×24 · 12×16 · 9×12 |

**Nunca** 62×86, 110×12 ou qualquer valor que não caia nessa tabela.

### Fonte em bitmap
`ui_font_sheet_v1.png` — ordem das células: `0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ/-:` (índices 0…38; a 40ª é espaço).
Célula = 36×48 (glifo 6×8 de autoria a 6×). Avanço = 36 px. Largura de um rótulo de *n* caracteres = `n×36 + 6`.

Rótulos já renderizados: `lbl_floor07` (294×48) · `lbl_party` · `lbl_hand` (150×48) · `lbl_bag` · `lbl_next` (150×48) · `lbl_fusion` · `lbl_chain3` · `lbl_apply` · `lbl_enemy` · `lbl_hp` (78×48) · `lbl_xp` · `lbl_sp` · `lbl_energy`.
Valores: `val_hp` (70/70) · `val_hp_9999` (9999/9999, 330×48) · `val_xp` · `val_sp` · `val_energy` (12/20).

---

## 5. Movimento (a mesma linguagem dos outros pacotes)

| ação | duração | curva |
|---|---|---|
| toque / press | 120 ms | ease-snap · escala 0,94 + brilho +8% |
| seleção de carta | 120 ms | sobe 9 px, realce 2px na cor do elemento |
| carta sai da BAG → mão | 180 ms | ease-out · translada e a fila desliza 1 posição |
| barra de XP / energia | 200 ms | ease-out |
| segmento do arco de skill | 200 ms por encaixe | ease-out |
| dreno de HP | 420 ms | ease-out |
| avanço de turno / rodada | 420 ms | ease-out |
| arco cheio (8/8) | loop 900 ms | halo pulsante — ver `README_VFX.md` |

Sem hover (é mobile). Carta gasta: brilho 35% + dessaturada. Unidade morta: greyscale a 45%.
Chrome desabilitada: opacidade 40%, **nunca** recolorida.

---

## 6. Nomes de arquivo (contrato)

```
card_face_<el>_v1.png            78×108     face de carta
fragment_seal_<el>_empty_v1.png  330×330    moldura
fragment_seal_<el>_charge_sheet_v1.png 330×2970  9 quadros de carga
enemy_turn_plate_<el>_v1.png     384×144    placa de inimigo
char_<id>_<el>_battle_v1.png     222×237    personagem no selo
char_<id>_<el>_gacha_v1.png      330×420    arte de invocação
char_<id>_<el>_icon_v1.png       72×72      ícone
char_<id>_<el>_idle_v1.png       444×237    2 quadros de idle
```

O `<id>` de um personagem nunca muda, mesmo que a arte seja refeita — só o `v`.
