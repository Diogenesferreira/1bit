# Contradicoes entre documentos — leia antes de implementar

Levantamento honesto do que os documentos deste pacote dizem de diferente
entre si, e qual e a fonte da verdade HOJE (07/09/2026).

| # | contradicao | documento antigo | **verdade atual** |
| --- | --- | --- | --- |
| 1 | marca de lider no card | `PARTY_HERO.md`: **coroa** (`crown_leader.png`) · `PARTY_LEADER.md`: **placa "LEADER"** 117x22 no topo-direito | `PARTY_CARD.md`: **losango de 14 px** dourado em (-4,-4), sem coroa e sem placa. `crown_leader.png` e a placa estao **mortos**. |
| 2 | barra de life do jogador | `LIFE_BAR.md`: tiles `hp_tile_field.png` + `hp_tile_fill.png` em `STRETCH_TILE` | `LIFE_BAR_V2.md`: **dither procedural** (faixas de 3 px) no estilo da barra de energia, altura 24, borda 3. Os dois tiles nao sao mais usados no canvas. |
| 3 | anel do card do lider | `PARTY_LEADER.md` (1a versao): anel **dourado** | anel **sempre na cor do elemento**; dourado so no losango de lider |
| 4 | quem desce do BAG | `ANIMACOES.md` (06/09) nao definia | **a carta mais a direita** (`bag[7]`, junto do NEXT); a fila anda da esquerda pra direita e a nova entra no slot 0 |
| 5 | local da fusao | `ANIMACOES.md` §6: nucleo/aneis/projetil **no palco** | `FUSAO.md`: **no centro da grade da mao**; o palco nao participa |
| 6 | botao ATACAR | `ANIMACOES.md`: cascata disparada por botao ATACAR | **nao existe mais**; os toques resolvem tudo (3a carta fecha o trio sozinha) |
| 7 | escala do sprite do heroi | `PARTY_HERO.md`: "logico x 2" | tabela literal por elemento (`PARTY_CARD.md` §2) |
| 8 | folhas de fonte | `PARTY_HERO.md`: `ui_font_sheet_v1.png` (1440x48) | folhas **1:1** `font_1x_v1.png` (480x16), `digits_1x_v1.png`, `digits_card_1x_v1.png` |
| 9 | backdrops de stage | export 06/09 nao tinha backdrop | `stage_plains/forest/sea_v1.png` (222x140, x4). Os `stage-*.png` do design system foram **descartados** (tinham HUD alheio embutido). |

## 2. Escalas nao inteiras (divida tecnica, nao contradicao)

| asset | nativo | desenho atual | razao | como resolver |
| --- | --- | --- | --- | --- |
| `cards/card_face_*.png` | 78 x 108 | 138 x 191 (mao) | **1.769x** | reexportar a arte em 138x191 nativo, ou desenhar a mao em 156x216 (= 2x) |
| `char80/char_nature.png` | 240 x 232 | 112 x 108 | **2.14x** | reexportar em 224 x 216 (= 2x exato) |
| `card_party/sym_*.png` | 60 x 60 | 26 x 26 | **2.3x** | reexportar em 52 x 52 (= 2x exato) |
| `ui/val_account.png` e `lbl_*.png` | 48 px de altura | 16-18 px | 2.6-3x | trocar por `BitmapFontLabel` (as folhas 1:1 ja cobrem) |

As reducoes do HUD de inimigo (1/3 e 1/2) **sao** inteiras — aquelas estao ok.

## 3. Numeros de balanceamento provisorios

`aimAt` (leader) = 60 de dano · `activateAllySkill` = 340 · HP de inimigo = 100
· dano de elo = `max(1, 6 + media_do_trio*2) * (1 + 0.3*elo)`. O 340 mata tres
inimigos de 100 — sao **placeholders de leitura visual**, nao balanceamento.
