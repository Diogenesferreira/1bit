# Pacote de entrega — Selos de Fragmento Elementais (07/09/2026)

Tela de batalha completa para integrar no Godot.

## Ordem de leitura

1. **`MANIFEST.md`** — canvas de design, espacos de coordenadas, indice de TODO
   arquivo (nativo, escalas legais, onde e usado).
2. **`CHANGELOG.md`** — o que mudou desde o export de 06/09: telas, regras,
   animacoes (tempos antigos -> novos), numeros de layout, assets.
3. **`spec/CONTRADICOES.md`** — as 9 contradicoes entre documentos e qual e a
   verdade de hoje. **Leia antes de implementar qualquer coisa.**
4. `spec/LAYOUT_GERAL.md` + `spec/layout_batalha.json` — geometria.
5. `spec/ANIMACOES_V2.md` + `spec/FUSAO.md` — tempos, curvas, gatilhos.
6. Specs por sistema: `PARTY_CARD.md`, `TOP_BAR.md`, `LIFE_BAR_V2.md`,
   `ENEMY_HUD.md`, `FORMACOES.md`, `PALETA.md`.
7. `godot/` — scripts de referencia que ja implementam o contrato.
8. `html/UI Batalha 1bit.dc.html` — a fonte da verdade viva; abre no navegador.

## Regras que valem para tudo

- **Um espaco de coordenadas por no, declarado.** CONTENT / STAGE / PARTY_CARD /
  HAND_GRID / ENEMY_PLATE — nunca misture.
- **Quem clipa, clipa explicitamente** (`clip_contents = true`).
- **Arte de personagem ancorada pelos PES** (`y = baseline - altura`).
- **Tamanhos de desenho sao tabelados**, nunca derivados de multiplicador.
- **Todo numero que muda vive em caixa de largura reservada, ancorado a direita.**
- **Escala inteira sempre**: `Filter = Nearest`, mipmaps off, zoom da tela em
  multiplo inteiro. As excecoes conhecidas estao em `spec/CONTRADICOES.md` §2.
- **Tremor por interpolacao de relogio**, nunca por animacao disparada.

---

# Historico dos exports anteriores

# Selos de Fragmento — pacote de produção v1

Data: 2026-08-30 · 5 elementos · PNG RGBA 330×330 · pixel art, grade lógica 55×55 (1 px lógico = 6 px de arquivo)

---

## 1. Conteúdo do pacote

| pasta | arquivo | tamanho | uso |
|---|---|---|---|
| frames/ | fragment_seal_{el}_v1.png | 330×330 | moldura de referência, arco já 8/8 na cor do elemento |
| frames/ | fragment_seal_{el}_empty_v1.png | 330×330 | **usar no jogo** — moldura com os 8 encaixes apagados (#3a3a35) |
| charge_sheets/ | fragment_seal_{el}_charge_sheet_v1.png | 330×2970 | **usar no jogo** — 9 quadros verticais (0/8 … 8/8), só o preenchimento do arco |
| sheet/ | fragment_seals_sheet_v1.png | 1650×330 | folha de inspeção com as 5 variantes |
| source_icons/ | card_icon_{el}_v2.png | original | sua arte de símbolo, sem alteração (fonte da tintura) |
| html/ | Selos de Fragmento.dc.html + image-slot.js | — | página de inspeção/animação (código-fonte, referência) |
| godot/ | FragmentSeal.gd | — | script pronto de empilhamento + animação |
| enemy/ | ver **README_INIMIGO.md** | 384×144 | life e turno do inimigo (placa, calha, barra, dígitos 0–9, rótulo TURN) |
| godot/ | EnemyBar.gd | — | script do life + turno (1 a 5 turnos) |
| — | **README_VFX.md** | — | fusão das 3 cartas, balão de dano manga e os 5 VFX de impacto (procedurais, com timelines) |
| ui/ | card_face_*, lbl_*, val_*, ui_font_sheet | ver **README_UI.md** | faces de carta, rótulos e fonte em bitmap da tela de batalha |
| char/ | fam_*, mount_*, var_*, ramp_*, dist_*, acc_* | ver **README_UI.md** §1 | gabaritos e exemplos de arte de personagem |
| godot/ | BattleUI.gd | — | script da tela de batalha (BAG, mão, HP, energia, seleção) |
| — | **README_UI.md** | — | **tela de batalha completa**: layout, paleta, escalas legais, movimento |

`{el}` = `dragon` | `knight` | `nature` | `light` | `dark`

## 2. Elementos e cores

| el | nome | cor da barra | tom de sombra do símbolo (62%) |
|---|---|---|---|
| `dragon` | Dragão/Fogo | `#a8443a` | 62% de #a8443a |
| `knight` | Cavaleiro | `#5a86a8` | 62% de #5a86a8 |
| `nature` | Natureza | `#7d9455` | 62% de #7d9455 |
| `light` | Luz | `#c9a842` | 62% de #c9a842 |
| `dark` | Trevas | `#7a5f9a` | 62% de #7a5f9a |

Traço do símbolo: `#201f1d`. Contorno da moldura: `#c9c0a8` (externo) e `#8f886f` (interno).
Corpo da moldura: `#2b2b28`. Encaixe apagado: `#3a3a35`.

`Wild` e `Cura/Cápsula` são mecânicas de carta: **não têm moldura**.

## 3. Geometria (coordenadas em px de arquivo, 330×330)

- Canvas: 330×330 RGBA, alpha binário (0 ou 255), **zero pixels semi-transparentes** — sem halo ao recortar.
- Área ocupada por pixel: ~25% do canvas. Todo o resto é alpha 0.
- **Abertura do personagem (área útil): x 54–276, y 45–282** → 222 × 237 px, topo em arco de raio 111, base reta.
  - Ponto de apoio dos pés: y ≈ 276. Centro horizontal: x = 165.
- Arco de skill: centro (165, 150), raio externo 141, raio interno 111 (arco e haste vertical alinhados na mesma coluna), 8 encaixes divididos por 1 px lógico de contorno, varredura de 180° a 0°.
- Socket elemental (afinidade, sem glifo): x 24–71, y 144–233 (retângulo vertical, preenchido na cor do elemento).
- Símbolo do elemento: rodapé, centralizado em x = 165, encostado na base (y até 329), sem placa e sem fundo.
- Geometria **idêntica** nas cinco variantes. Não redimensionar nem reposicionar partes internas por personagem.

## 4. Camadas na cena (ordem de desenho)

1. fundo escuro da janela / cena;
2. **sprite do personagem** — PNG com fundo transparente, dentro da área útil;
3. `fragment_seal_{el}_empty_v1.png` (a moldura fica na frente do personagem);
4. `fragment_seal_{el}_charge_sheet_v1.png` — quadro `carga` (0–8);
5. estado cheio: halo + varredura + anel.

Recorte recomendado do personagem: máscara igual à abertura (retângulo 222×237 com topo em arco r111) para que nada escape pelas laterais do arco.

## 5. Barra de carga (0–8)

- A folha é vertical: **offset Y = −carga × 330**. Carga 0 = quadro 1 (nada aceso), carga 8 = quadro 9 (arco cheio).
- Preenchimento **da esquerda para a direita** (encaixe 1 = ponta esquerda do arco).
- Em Godot: `AtlasTexture` com `region = Rect2(0, carga * 330, 330, 330)`.

## 6. Regras de animação

| evento | duração | curva | efeito |
|---|---|---|---|
| ganho de 1 encaixe | 420 ms | ease-out | troca de quadro + pip da HUD acende (transição de cor 160 ms) |
| chegada em 8/8 | 1× | — | dispara o loop de "skill ready" abaixo |
| halo pronto (loop) | 1300 ms | ease-in-out, infinito | glow na cor do elemento: raio 3 px → 13 px + 26 px e brilho 1.00 → 1.12, e volta. O glow lê o alpha do PNG, então acompanha a silhueta (nunca um retângulo) |
| varredura de brilho (loop) | 1300 ms | ease-in-out, infinito | cópia do quadro 8/8 em blend aditivo, opacidade 0 → 0.85 (45%) → 0 |
| anel de impacto (loop) | 1300 ms | ease-out, infinito | contorno de 2 px na cor do elemento, escala 1.00 → 1.16, opacidade 0.55 → 0 |
| gasto da skill | 120 ms | snap | volta a carga 0 no mesmo quadro, sem fade |
| toque no selo | 120 ms | snap | escala 0.985 e leve aumento de brilho |

Sem sombra externa suave em nenhum estado — a profundidade é toda por glow.

## 7. Import no Godot 4

1. Copie `frames/` e `charge_sheets/` para `res://art/seals/`.
2. Em cada textura, no painel Import: **Filter = Nearest**, **Mipmaps = off**, **Fix Alpha Border = off**, Compress → Lossless. Reimport.
3. Projeto → Display → Window: `Stretch Mode = viewport` ou `canvas_items`, `Stretch Aspect = keep`, para manter os pixels inteiros.
4. Use `godot/FragmentSeal.gd` (instruções de nós no topo do arquivo).

## 8. Checagens já feitas

- alpha binário nas 5 molduras (0 pixels semi-transparentes);
- alpha 0 nos cantos, na abertura e fora da moldura;
- geometria bit-a-bit idêntica entre as variantes (só cor e símbolo mudam);
- folha de carga alinhada quadro a quadro com `_empty` (mesma origem 0,0).

## 9. Se precisar regerar

Os assets são gerados por código (grade 55×55, escala 6). Para mudar tamanho, gere em múltiplos inteiros de 55 (55, 110, 165, 220, 330, 440) — nunca escale um PNG existente por fator não inteiro.

## Faixa de party — modelo final (02/09/2026)

Cinco cards de 152×188 **do mesmo tamanho**; o líder é marcado por placa `LEADER`
no topo-direito (a coroa foi removida) + anel dourado + halo. Spec completa:
`spec/PARTY_LEADER.md`. Fontes: usar as folhas 1:1 `ui/font_1x_v1.png`,
`ui/digits_1x_v1.png`, `ui/digits_card_1x_v1.png` — as antigas
(`ui_font_sheet_v1`, `enemy_digits_sheet_v1`) borram ao reduzir.
Migração de heróis 32×40: `MIGRACAO_HEROIS.md`.

## Alinhamento no Godot — LEIA PRIMEIRO

Se qualquer coisa aparecer fora de lugar: `spec/POSICIONAMENTO.md`. Contém a
árvore de nós normativa do card, a tabela de desenho do herói por elemento,
as regras de espaço de coordenadas / clip / ancoragem pelos pés, e o checklist
de integração. `godot/PartyCard.gd` v2 já implementa esse contrato.

## Barra de LIFE do jogador

`spec/LIFE_BAR.md` + `godot/PlayerLifeBar.gd`. Mesmo contrato do card:
árvore de nós normativa, `WELL` como único nó que clipa, fill crescendo da
esquerda por largura (nunca `scale`), tiles em `STRETCH_TILE`, rótulo e valor
via `BitmapFontLabel` na folha 1:1 — os PNGs `lbl_hp`/`val_hp*` foram
aposentados.

## Área superior + STAGE

`spec/TOP_BAR.md` + `godot/TopBar.gd` + `godot/StagePlate.gd`.
Regra central: todo número que muda vive em caixa de largura reservada,
ancorado à direita (`BitmapFontLabel.align_right_in`) — o layout não desloca
quando o valor cresce. Tetos: moeda 7 dígitos, gema 5, energia `999/999`,
LV 3. Moeda e gema num rack único; energia em plate próprio com borda mais
forte (recurso de combate). Plate de STAGE agora é OPACO e usa a folha 1:1 —
era o alpha .72 + PNG reescalado que o deixava ilegível.

## Animações de combate + fusão na mão (06/09/2026)

Canvas de teste completo: `html/Laboratorio de Animacoes.dc.html` (abre no
navegador, testável ao vivo — stage 1→2→boss, dano em cascata, tremor,
seleção de carta, fusão, skills de energia e leader).

Specs: `spec/ANIMACOES.md` (regras e tempos de tudo) + `spec/FUSAO_NA_MAO.md`
(fusão saiu do palco e agora acontece na faixa da mão — leia esta segunda
ANTES de implementar fusão, ela substitui a seção 6 da primeira).
