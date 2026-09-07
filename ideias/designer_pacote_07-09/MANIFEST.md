# MANIFEST — pacote de entrega para Godot

**Data:** 07/09/2026 · **Projeto:** Selos de Fragmento Elementais
**Fonte da verdade viva:** `html/UI Batalha 1bit.dc.html` (abre no navegador)

---

## 0. Canvas de design e espacos de coordenadas

```
CANVAS ..................... 940 x auto  (largura FIXA, nao reflui)
  borda externa 2 px  +  padding 10  +  borda interna 1  +  padding 14
COLUNA DE CONTEUDO ......... 888 px   <- toda medida de secao vive aqui
```

| espaco | origem | tamanho | quem vive nele |
| --- | --- | --- | --- |
| **CONTENT** | canto sup-esq da coluna | 888 x auto | as 8 secoes da pilha, gap 14 |
| **STAGE** | canto sup-esq do palco | 888 x 560 | inimigos, plate de STAGE, flash |
| **PARTY_CARD** | canto sup-esq do card | 152 x 188 | moldura, heroi, selo, barra, placa |
| **HAND_GRID** | canto sup-esq da grade | 888 x 394 | 12 casas, fusao, ghost do BAG |
| **ENEMY_PLATE** | canto sup-esq da placa | 32k x 12k (k=4 ou 6) | digito TURN, label, barra de HP |

Pilha vertical (CONTENT, gap 14): barra da conta 72 · palco 560 · rotulo PARTY 18 ·
faixa do party 226 · caixa BAG 138 · rotulo HAND 34 · grade da mao 394 · life 38.

Numeros legiveis por maquina: **`spec/layout_batalha.json`**.

---

## 1. spec/ — contratos

| arquivo | cobre | status |
| --- | --- | --- |
| `LAYOUT_GERAL.md` | canvas, espacos, pilha vertical, regras R1-R6 | **novo** |
| `layout_batalha.json` | todos os numeros, legivel por maquina | **atualizado** |
| `ANIMACOES_V2.md` | 26 animacoes: gatilho, duracao, curva | **novo** (substitui `ANIMACOES.md`) |
| `FUSAO.md` | 5 fases da fusao na mao + energia ate o aliado | **novo** (substitui `FUSAO_NA_MAO.md`) |
| `PARTY_CARD.md` | arvore de nos, tabela de desenho do heroi, estados | **novo** (substitui `PARTY_HERO.md`) |
| `ENEMY_HUD.md` | placa por escala, arvore, clip do fill | **novo** |
| `FORMACOES.md` | 4 formacoes + sequencia de stage + trilha | **novo** |
| `LIFE_BAR_V2.md` | barra de life com dither procedural | **novo** (substitui `LIFE_BAR.md`) |
| `TOP_BAR.md` | barra da conta + plate de STAGE | mantido (ver CHANGELOG) |
| `PALETA.md` | paleta fechada, elementos + chrome + alphas | **novo** |
| `CONTRADICOES.md` | **9 contradicoes** entre documentos + escalas nao inteiras | **novo — leia primeiro** |
| `POSICIONAMENTO.md` | regras de ancoragem/clip (base do contrato) | mantido |
| `ASSETS.md`, `PARTY_HEX.md`, `PERSONAGENS_32x40.md`, `LAYOUT_BATALHA.md` | historico de fases anteriores | legado |
| `ANIMACOES.md`, `FUSAO_NA_MAO.md`, `LIFE_BAR.md`, `PARTY_LEADER.md` | **superados** — mantidos so para rastreio | legado |

---

## 2. Assets — tamanho de origem e escalas inteiras legais

### ui/ — chrome e fontes
| arquivo | nativo | escalas legais | onde e usado |
| --- | --- | --- | --- |
| `font_1x_v1.png` | 480 x 16 | x1 (celula 12x16), x2, x3 | **toda** letra/numero da UI |
| `digits_1x_v1.png` | 120 x 14 | x1 (celula 12x14), x2, x3 | LV/energia/contadores do HUD |
| `digits_card_1x_v1.png` | 190 x 21 | x1 (celula 19x21), x2 | valor da carta na mao |
| `hp_heart_card.png` | 27 x 24 | x1, x2 | coracao da barra de life |
| `icon_coin/gem/energy.png` | 20 x 20 | x1, x2, x3 | contadores da barra da conta |
| `lbl_party/bag/hand/next.png` | 114-186 x 48 | 1/2, 1/3 (usado a ~1/3) | rotulos de secao |
| `val_account.png` | 288 x 48 | 1/2, 1/3 | nome da conta |
| `hp_tile_field/fill.png` | 24x24 / 24x18 | x1 | **aposentados** (ver CONTRADICOES 2) |
| `ui_font_sheet_v1.png` | 1440 x 48 | 1/3 | **aposentado** (borrava; use `font_1x_v1`) |

### cards/ — faces de carta em uso
| arquivo | nativo | escalas legais | onde |
| --- | --- | --- | --- |
| `card_face_dragon_v1.png` | 78 x 108 | x1 (BAG), **x2 = 156x216** | mao + BAG |
| `card_face_knight_v1.png` | 78 x 108 | x1, x2 | mao + BAG |
| `card_face_nature_v1.png` | 78 x 108 | x1, x2 | mao + BAG |
| `card_face_light_v3.png` | 78 x 108 | x1, x2 | mao + BAG |
| `card_face_dark_v3.png` | 78 x 108 | x1, x2 | mao + BAG |

> A mao desenha **138 x 191** hoje = 1.769x (nao inteiro). Existem `_v2` em
> 156 x 216 (= x2 exato) em `ui/`. Ver CONTRADICOES secao 2.

### enemy/ — HUD do inimigo
| arquivo | nativo | escalas legais | onde |
| --- | --- | --- | --- |
| `enemy_turn_plate_<el>_v1.png` (5) | 384 x 144 | **1/3 = 128x48**, **1/2 = 192x72** | moldura da placa |
| `enemy_hp_well_v1.png` | 384 x 144 | 1/3, 1/2 | trilho de HP |
| `enemy_hp_fill_v1.png` | 384 x 144 | 1/3, 1/2 | preenchimento (clipado) |
| `enemy_label_turn_v1.png` | 144 x 48 | 1/3, 1/2 | palavra TURN |
| `enemy_digits_sheet_v1.png` | 420 x 48 | 1/3, 1/2 | 10 digitos, celula 42x48 |
| `enemy_bar_*_preview_v1.png` | 384 x 144 | — | so referencia visual |

### char80/ — herois do card de party
| arquivo | nativo | desenho | escala |
| --- | --- | --- | --- |
| `char_dragon.png` | 228 x 216 | 114 x 108 | 1/2 exato |
| `char_knight.png` | 176 x 232 | 88 x 116 | 1/2 exato |
| `char_light.png` | 216 x 224 | 108 x 112 | 1/2 exato |
| `char_dark.png` | 208 x 216 | 104 x 108 | 1/2 exato |
| `char_nature.png` | 240 x 232 | 112 x 108 | **2.14x — reexportar em 224x216** |
| `char_heal.png` | 184 x 216 | (reservado) | 1/2 |

### card_party/ — interior do card
| arquivo | nativo | escalas legais | onde |
| --- | --- | --- | --- |
| `scene_<el>.png` (5) | 150 x 138 | x1 | cena no topo do FRAME |
| `field_<el>.png` (5) | 24 x 24 | x1 (TILE) | padrao de fundo do FRAME |
| `sym_<el>.png` (5) | 60 x 60 | desenha 26x26 (**2.3x — reexportar 52x52**) | selo do elemento |
| `party_arc.png` | 888 x 228 | x1 | arco decorativo atras da faixa |
| `crown_leader.png` | 52 x 24 | — | **MORTO** (ver CONTRADICOES 1) |

### backdrops/ — fundo do palco
| arquivo | nativo | escala legal | desenho |
| --- | --- | --- | --- |
| `stage_plains_v1.png` | 222 x 140 | **x4** | 888 x 560 (stage 1/3) |
| `stage_forest_v1.png` | 222 x 140 | **x4** | 888 x 560 (stage 2/3) |
| `stage_sea_v1.png` | 222 x 140 | **x4** | 888 x 560 (boss 3/3) |

### seals_1a/, frames/, char32/, hex/, sheet/
Legado das fases anteriores (selos de fragmento, molduras hexagonais, herois
32x40). Nao sao usados pela tela de batalha atual; mantidos porque o contrato
de nomes exige que `<id>` nunca mude. Especificados em
`spec/PARTY_HEX.md` e `spec/PERSONAGENS_32x40.md`.

**Formato de todos os PNG:** RGBA, alpha binario (0 ou 255), sem glow pintado —
o glow e sempre feito em runtime (box-shadow / material). `Filter = Nearest`,
mipmaps off, em todos.

---

## 3. godot/ — scripts de referencia

| arquivo | cobre | status |
| --- | --- | --- |
| `BitmapFontLabel.gd` | texto na folha 1:1, `tracking`, `align_right_in` | atualizado |
| `PartyCard.gd` | card 152x188, FRAME que clipa, losango de lider, botao de skill | **atualizado** |
| `TopBar.gd` | barra da conta, caixas reservadas, energia 999 | atualizado |
| `PlayerLifeBar.gd` | barra de life com **dither procedural** | **atualizado** |
| `StagePlate.gd` | plate de STAGE + trilha (boss vence na forma) | atualizado |
| `FusionOnHand.gd` | fusao ancorada na mao | atualizado |
| `DamagePopup.gd` | popup de dano com SCATTER + placa opaca | **novo** |
| `EnemyPlate.gd` | placa de TURN + HP com FILL_CLIP, tremor por relogio | **novo** |
| `StageBackdrop.gd` | backdrop x4 + crossfade de 600 ms | **novo** |
| `BattleScreen.gd`, `BattleUI.gd`, `battle_layout.gd` | montagem da tela | legado |
| `EnemyBar.gd`, `FragmentSeal*.gd`, `PartySeal.gd` | fases anteriores | legado |

---

## 4. html/ — referencia viva

| arquivo | o que e |
| --- | --- |
| `UI Batalha 1bit.dc.html` | **a tela de batalha atual** — tudo desta entrega |
| `Laboratorio de Animacoes.dc.html` | canvas de teste de animacoes (stage, cascata, skills) |
| `support.js`, `image-slot.js` | runtime necessario para abrir os dois |
| `Selos de Fragmento.dc.html`, `Selos Quadrados.dc.html`, `Personagens · corpo inteiro.dc.html` | telas das fases anteriores |

---

## 5. reference/ — renders de estado

| arquivo | estado |
| --- | --- |
| `01_mao_inicial.png` | mao inicial (2 fileiras de 5 + 2 ENTRADAS vazias) |
| `02_carta_marcada.png` | 1a carta marcada (levanta 14 px, rim na cor do elemento) |
| `03_segunda_marcada_bag_desce.png` | 2a marcada + carta do BAG descendo na ENTRADA |
| `04_fusao_estouro.png` | fusao no estouro (cartas brancas, nucleo, choque) |
| `05_mao_embaralhada.png` | mao redistribuida pos-combo (agrupada por elemento) |
| `06_mao_pos_combo.png` | mao assentada depois do pop de embaralhar |
| `07_palco_formacao_3.png` | palco, formacao de 3, backdrop 1/3 |
| `08_palco_impacto.png` | palco no impacto do dano acumulado |
| `09_faixa_party.png` | faixa do party (5 cards, lider com losango) |
| `10_barra_conta.png` | barra da conta (moeda/gema/energia separadas) |
| `tela_completa.png`, `formacao_*.png`, `bag.png`, `mao.png`, etc. | renders das fases anteriores |

Estados **nao** capturados nesta rodada (dependem de 4+ turnos de jogo):
skill de aliado pronta, leader em modo de mira, troca de stage em andamento.
Estao especificados em `ANIMACOES_V2.md` (itens 22-26) e visiveis ao vivo no
HTML.

---

## 6. Contrato de nomes

`<id>` de personagem/elemento **nunca muda** — so o sufixo `_vN`:
`char_nature.png`, `sym_nature.png`, `scene_nature.png`,
`enemy_turn_plate_nature_v1.png`, `card_face_nature_v1.png`.
Elementos: `dragon`, `knight`, `nature`, `light`, `dark` (+ `heal` reservado).
