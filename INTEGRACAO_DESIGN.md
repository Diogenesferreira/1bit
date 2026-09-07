# Integração do design → código

Documento-ponte entre o que o Designer produz (canvas no Claude Design, exportado
em pacotes tipo `export_godot/`) e a tela de batalha implementada no Godot.

- **Visual** (layout, cores, tempos, look das animações): fonte de verdade = os
  `spec/*.md` e assets exportados pelo Designer.
- **Regra de jogo** (trio, cascata, dano, contador, skills): fonte de verdade =
  [`REGRAS_CANONICAS_ALPHA.md`](REGRAS_CANONICAS_ALPHA.md) + `tests/test_batalha.gd`.
- **Comportamento**: o código.

Contradições entre documentos do Designer são resolvidas **aqui**, uma vez, no
Log de decisões — não se rediscute.

Pacotes já avaliados:
- `novas animaoes e estilos.zip` → `export_godot/` (06/09/2026): contrato novo de
  animação (`spec/ANIMACOES.md`, `spec/FUSAO_NA_MAO.md`) + specs literais de layout.

---

## A. Manter do código atual (o pacote não invalida)

| # | item |
|---|---|
| A1 | Separação `EstadoBatalha` (regra) × `BattleScreen` (reprodução) por lista de eventos |
| A2 | `Saco.gd` — BAG estratificado, sem rajada |
| A3 | Regra de trio / cascata / renovação / chuva final + garantia de saída |
| A4 | Testes headless (`test_batalha.gd`, `_testar_regras_canonicas`) |
| A5 | Canvas 940×1685, snap de pixel, filtro nearest |
| A6 | `Arte.gd` como ponte única de asset |
| A7 | Party cards 152×188 (já batem com o pacote) |
| A8 | Card faces v3 (light/dark/wild) + fonte `ui_v11` (já batem) |
| A9 | `DamagePopup` (balão manga), `FusionStream`, `ElementImpact`, `BattleSfx` |
| A10 | Adaptação a telas altas (`_vertical_extra`) |
| A11 | A geometria do "juntar no meio" da fusão: ponto central da faixa da mão, 2 tempos (align → colapso), carta em 1:1 |

---

## B. Mudanças propostas (pacote de animação → código)

Status: `a decidir` · `aceito` · `adaptado` · `recusado`

| # | sistema | hoje | proposto | status |
|---|---|---|---|---|
| B1 | **Fusão na mão** | espalha 148px, sem leque, núcleo branco puro | 5 fases (`spec/FUSAO.md`): leque −6/0/+6 → aquecimento (glow radial + cartas brilham) → estouro (núcleo radial 230 + 2 ondas + 12 estilhaços + flash bone + tremor de tela) → feixe vertical 28×300 → energia ao aliado. A energia até o aliado segue no `FusionStream` (curvo) por ora | **feito** |
| B2 | **Popups de cascata** | float `COMBO xN` + `+N` por aliado; dano real só em `ataque_final` | um popup **por carta** na cor daquela carta, faixas de 26px, passo 95ms; chip `TOTAL` por inimigo | **recusado** (C7 = manter dano no fim) |
| B3 | **Tremor (shake)** | só flash de shader, sem deslocamento | shake por relógio no `_process`. Inimigo amp 6/2 300ms; **tela amp 5 380ms** no `BattleScreen._process`, disparado no estouro da fusão | **feito** |
| B4 | **Morte do inimigo** | sprite → `alpha 0.12` + HUD cinza 45% | dessaturar + brightness .45 na **placa e no corpo** (mantém silhueta) | **feito** |
| B5 | **Seleção de carta** | só rim (decisão no código: "cartas ficam paradas na grade") | sobe −14px + brightness 1.14 + halo + pulso único de anel | **feito** |
| B6 | **Ciclo de 3 stages / boss** | 3 inimigos fixos; todos mortos = vitória; rodada 1/3 nunca avança | batalha = stage 1 → 2 → 3; formações **trio → dupla → boss** (teste rápido); último inimigo a 0 → flash bone → troca do conjunto → trilha avança; `StagePlate` lê o estado | **feito** |
| B7 | **Formações de inimigo** | `Unidades.ENEMY_PRESETS` com números próprios + preset de 4 | conferido: presets 1/2/3 (`centros`) já batem com `FORMATIONS` do `battle_layout.gd`; dígito do turno já deriva de `hud_tam` (escala k). Presets 4/5 ficam como estão (não usados nas fases normais) | **feito (já alinhado)** |
| B8 | **Fonte em escala fracionária** | `1240` vira `: 240`; `AtlasTexture` sem `filter_clip` | `atlas.filter_clip = true` em `BitmapFontLabel` + dígitos inimigo/party | **feito** (`CONTENT_SCALE` integer fica pendente de avaliação) |
| B9 | **Top bar / StagePlate × estado** | `TopBar` com coins/gems/energy/nome/level hardcoded; `_txt_*` mortos; `estado.score/gems/moedas` ignorados | **parte feita:** removidos `_txt_score/rodada/gems/moedas`, `_bitmap()`, `_caveira()`, `MOLDURAS`, `ROTULOS`, `CAVEIRA_LADO` (código morto). **Pendente:** DESIGN 11.3 manda esconder moeda/gema em combate, mas o `spec/TOP_BAR.md` do Designer mantém a carteira — resolver com o `coisasdogame`; e ligar nome/nível/XP precisa de uma camada de conta que ainda não existe | **parcial** |
| B10 | **Rótulos PNG → fonte bitmap** | `lbl_bag/hand/next/party` como PNG | migrar pra `BitmapFontLabel` (ou manter — são estáticos). Baixa prioridade | adiado |
| B11 | **Cenário de palco por stage** | 1 placeholder `battle_background_ruined_forest` fixo | `backdrops/stage_plains_v1` (1/3) · `stage_forest_v1` (2/3) · `stage_sea_v1` (boss), ×4 nearest. Crossfade de 600ms na troca de stage | **feito** |
| B17 | **Chip TOTAL no inimigo** | dano acumulado vira placa `+N` no aliado | `EnemyUnit.definir_total(n)`: chip `TOTAL n` abaixo do HUD, acumulado por `_anim_combo`, some ao zerar no fim da corrente | **feito** |
| B18 | **TURN por inimigo** | todos espelham `estado.contador_inimigo` | **só leitura de HUD:** cada inimigo tem um `turno` próprio (trio 2/3/1) que desce junto e reseta quando o contador global dispara. A **cadência de ataque continua global** (contador começa em 3, um ataque) — a versão "cada um dispara sozinho" foi testada e **triplicou o DPS inimigo** (28/30 derrotas). Ícones de intenção por inimigo ficam pra depois | **feito (display) / mecânica global mantida** |
| B19 | **Skill de líder (MIRA)** | não existe | botão `★ ACTIVE SKILL LEADER n/4` na faixa da HAND; clicar entra em **modo de mira** (inimigos capturam clique, anel dourado); clicar no inimigo resolve; cooldown 4 turnos contado pra cima. Dano placeholder | a implementar |
| B20 | **Botão de skill no card do aliado** | `_ao_skill_clicada` só solta `"SKILL!"` | com 8 pips, aparece um **botão no próprio card**; clicar **consome** a carga e dá um golpe. Efeitos reais pendentes de `REGRAS_CANONICAS_ALPHA.md` | a implementar (efeito placeholder) |
| B12 | **Skill do aliado (medidor de 8)** | 8 pips no card; `_ao_skill_clicada` só solta `"SKILL!"`, não consome | 8 pips = "8 energias" que ativam a skill do aliado; ao encher, toque ativa e **consome** a carga. Efeitos das 5 skills ainda a definir | novo — a implementar (efeitos pendentes) |
| B13 | **Skill de líder** | não existe | pronta a cada **4 turnos** (cooldown, por ora fixo; depois depende de nível/personagem), independente das 8 energias; entra em **modo de mira** (`aiming`) e resolve no inimigo clicado | novo — a implementar |
| B14 | **Barra de HP do jogador** | tiles `hp_tile_*` | **dither procedural**: tile 6×1 gerado em runtime (3px base + 3px lit) em `STRETCH_TILE`; fundo `#14140f`; borda 3px por dentro | **feito** |
| B15 | **Dano final no inimigo — por elemento** | um `ElementImpact` + um `_flutuar("-N")` genérico por alvo (tipo dominante) | `EstadoBatalha` passa a emitir, em cada `golpe`, as **parcelas por elemento** (`[{tipo, dano}]`, soma = dano do alvo). `_anim_ataque_final` roda **um impacto + um número por parcela**, cada número na cor clara do seu elemento, empilhados em faixas e escalonados (~110 ms). Número usa a curva `labRise` (nasce .7 → 1.12 em 18% → sobe 34px → some) + sombra `#201f1d`. Timing inalterado (C7: dano no fim) | **aceito** |
| B16 | **VFX de impacto por elemento** | `ElementImpact.gd` já existe e roda em `_anim_ataque_final` | conferir contra `README_VFX.md §3` (fogo: labaredas + brasas · cavaleiro: 3 ondas em diamante + estilhaços · natureza: espinhos + folhas · luz: raios radiais + anéis · trevas: implosão + floração escura); ajustar coreografia/tempos ao contrato (total 900 ms) | a decidir (depende do pacote novo) |

---

## C. Decisões abertas (travam parte de B)

| # | pergunta | decisão (06/09/2026) |
|---|---|---|
| C1 | Seleção de carta | **(b)** carta sobe −14px + pulso |
| C2 | Arquitetura de skill | **(b)** 8 pips por aliado = recurso que ativa a skill do aliado. Skill de líder = cooldown à parte (4 turnos por ora; depois depende de nível/personagem). "Energia 0–20" da top bar **não** é recurso de skill — é meta/fora de batalha |
| C3 | Carga por combo | **(a)** manter a regra canônica: +1 comum / +2 crítico / +1 wild em todos. A fórmula exata do original não foi recuperada (servidor morto); a alpha é a referência. `EstadoBatalha` já faz isso — nada muda |
| C4 | Stages | **stages sim**, mas **trio → dupla → boss** (para testar mais rápido) |
| C5 | Card de líder | ~~(a) placa LEADER~~ → **SUPERSEDIDO pelo pacote 07/09** (`spec/CONTRADICOES.md` #1): nem placa nem coroa — **losango dourado 14×14 em (-4,-4)** + glow. `crown_leader.png` e a placa estão mortos |
| C6 | Life bar | ~~(b) tiles~~ → **SUPERSEDIDO pelo pacote 07/09** (`spec/LIFE_BAR_V2.md`): **dither procedural** de faixas de 3px (como a barra de energia), borda 3px, sem textura. Os `hp_tile_*` estão aposentados |
| C7 | Popups de cascata | **(b) com ajuste (06/09 rodada 3):** o dano continua aplicando **só no fim da corrente** (não há rajada durante a cascata). Mas, no momento do ataque final, mostrar **um VFX de impacto + um número subindo por elemento que atacou**, cada um na cor do seu elemento, juntos no mesmo alvo — em vez de um único `-N` genérico |

---

### 2026-09-07 — pacote `coisasdogame` (export 07/09) digerido

Chegou o pacote completo que respondeu ao pedido: `CHANGELOG.md`, `MANIFEST.md`,
`spec/CONTRADICOES.md`, specs V2 e renders de estado numerados. Copiado para
`ideias/designer_pacote_07-09/`; backdrops para `assets/battle/backdrops/`.

**Confirmações (o pacote valida o que já fizemos):**
- B3 tremor por relógio ✓ (amp mudou 7 → **6** vivo; ajustar).
- B4 cinza de morte na placa e no corpo ✓.
- B5 seleção sobe 14px + pulso 340ms ✓ (render `02_carta_marcada.png`).
- B6 stages **trio → dupla → boss** ✓ exatamente (`spec/FORMACOES.md`).
- B8 folhas 1:1 + nearest + célula inteira ✓.

**Superseded:**
- C5 → losango dourado 14×14 (não placa, não coroa).
- C6 → dither procedural (não tiles, não sólido).

**Especificações que destravam o que estava bloqueado:**
- B1 fusão → `spec/FUSAO.md` + `spec/ANIMACOES_V2.md` + `FusionOnHand.gd` + render
  `04_fusao_estouro.png`. 5 fases, âncora centro da HAND_GRID (444,197), cartas
  138×191, feixe 28×300, energia `dx = ELS.indexOf(el)*180.5 - 362`, `dy = -560`,
  chegada = 1780ms.
- B14 life bar → `spec/LIFE_BAR_V2.md` (dither procedural).
- B15 popup → por **elo** (trio), **espalhado em 8 posições (SCATTER)**, placa
  opaca com gradiente + borda `lit` + glow, contorno preto 4 direções, curva
  `b1Rise`. Passo da cascata 90ms.
- B16 VFX impacto → `README_VFX.md §3` (inalterado).
- B12/B13/B19/B20 skills → `spec/ANIMACOES_V2.md §5`: ally = botão no card que
  consome 8 pips; leader = modo de mira, cooldown 4 contado pra cima. Números de
  dano são placeholder (leader 60, ally 340).

**Dívida técnica do Designer (não é code):** `card_face_*` a 1.769×,
`char_nature` 2.14×, `sym_*` 2.3× — ele mesmo marcou "reexportar". Deixar como
está até vir a re-exportação.

**Backdrops antigos descartados:** os `stage-*.png` do design system tinham HUD
do jogo de referência embutido na foto (fonte do "hexágono roxo fantasma"). O
nosso `battle_background_ruined_forest` **não** é um deles, mas será trocado
pelos 3 backdrops novos por stage (B11).

### 2026-09-07 — rodada 4 (B11 + C5 + B3-ajuste)

- **B11 feito.** `Arte.backdrop(estagio)` + `_criar_cenario()`; `BattleScreen` usa
  o backdrop do estágio atual e faz **crossfade de 600ms** na troca de stage (o
  novo entra por cima, atrás dos inimigos; o antigo sai). Assets copiados para
  `assets/battle/backdrops/` e importados. Captura: stage 1/3 já mostra o
  `stage_plains` (planície + montanhas), bem mais claro que a floresta antiga.
- **C5 feito.** `PartyCard`: a placa "LEADER" virou **losango dourado 14×14** no
  canto sup-dir + halo suave na cor `lit`. Sem placa, sem coroa
  (`spec/PARTY_CARD.md §3`). Visível no card do SYLWEN na captura.
- **B3 ajustado.** Amplitude do tremor do inimigo 7 → 6 (ANIMACOES_V2 §2).
- Observação: contra o backdrop claro, a formação de inimigos ficou alta com
  muito chão verde vazio na frente — o `y` das formações foi afinado pro palco
  escuro de 558px. Afinar depois (não bloqueia).

### 2026-09-07 — rodada 5 (B14 + B15-scatter + B17 + B18 + formação-Y)

- **B14 feito.** `PlayerLifeBar`: fill agora é um tile 6×1 gerado em runtime
  (3px `#a8443a` + 3px `#d9705f`) em `STRETCH_TILE`; fundo virou ColorRect
  `#14140f`. Sem `hp_tile_*`.
- **B15-scatter feito.** `_dano_subindo(txt, centro, tipo, lane)`: número por elo
  numa das 8 posições `POPUP_SCATTER`, placa opaca `rgba(8,9,8,.82)` + borda
  `lit` 2px + sombra, curva b1Rise, passo da cascata 90ms.
- **B17 feito.** `EnemyUnit.definir_total(n)` + acumulador `_total_por_alvo` em
  `_anim_combo`; zera no `_reproduzir` e no `_anim_ataque_final`.
- **B18 feito (display).** `FORMACAO_TURNOS = {1:[1],2:[2,1],3:[2,3,1]}`; cada
  inimigo mostra seu `turno`. Cadência de ataque **permanece global** — a versão
  por-inimigo foi revertida por quebrar o balanceamento (28/30 derrotas).
- **Formação-Y** empurrada pra baixo (`bases` de 1/2/3) pro palco claro. Ainda
  sobra chão; afinar fino depois.
- `test_batalha.gd`: a asserção "nenhum inimigo tomou dano" agora aceita
  `estagio > 1` como prova (o teste da tela é não-determinístico).

### 2026-09-07 — rodada 6 (B1 fusão + flash de tela)

- **B1 feito.** `_anim_trio` reescrito nas 5 fases: leque (cartas 138×191 sobem
  ~128px, ±88 de offset, rotação ∓6°) → aquecimento (`_glow_fusao` radial cresce
  70→190, cartas → `modulate` 2.6 branco) → estouro (`_estouro_fusao`: núcleo
  230, 2 ondas de choque ×2.6, 12 estilhaços a 30° + `_piscar_tela` + `_tremor_tela`)
  → `_feixe_fusao` (28×300 sobe do centro). `_pulso_fusao` removido.
- **Flash de tela** deixou de ser a inversão dura do protótipo: agora é um
  overlay bone `#f4ecd8` que aparece a .85 e some (~450ms), como manda
  `spec/PALETA.md` / `ANIMACOES_V2 §18`.
- Captura `12c_fusao_estouro`: cartas convergidas + glow + brilho branco + flash
  quente — bate com o render `04_fusao_estouro.png` do Designer.

### 2026-09-07 — rodada 7 (branch `layout-do-designer`)

Checkpoint `checkpoint-animacoes` commitado e no GitHub. Reconstrução do layout
contra `spec/layout_batalha.json` numa branch própria:

- **`scripts/battle/LayoutBatalha.gd`** — o JSON inteiro em constantes (pilha
  vertical de 8 seções com Y/alturas, formações, party card, grade da mão,
  paleta). Fonte única de layout.
- **Palco encorpado:** `Unidades.ENEMY_PRESETS` com sprites ~40% maiores (trio
  270, dupla 320, boss 430) e ancorados mais abaixo; `_montar_scrim` (gradiente
  do JSON, topo −15% / base −55%). Resolve "inimigos pequenos e altos" + "campo
  vazio".
- **Alinhamento à coluna de 888:** grade da mão x0 27 / passo 150 (gap 12) /
  linhas [1152,1355]; party cards gap 16 centrados; barra de HP em y 1574.

Ainda na branch: herói do party card lê pequeno (dimensões batem com o spec —
pode ser a arte `char80` com padding); número da carta na mão ainda pouco
legível; botão de skill do líder na linha do rótulo HAND (é a mecânica B19).

## Falta

- **B19 / B20 — skills.** Precisa de decisão de regra antes: `REGRAS_CANONICAS_ALPHA.md`
  hoje diz "o toque **não consome** a carga"; o pacote do Designer quer consumir +
  golpe. E os números de dano do pacote são placeholder ("340 mata três
  inimigos"). Fazer sem isso arrisca outra regressão de balanceamento (como a
  B18 por-inimigo, que deu 28/30 derrotas). **Ação:** definir os 5 efeitos +
  dano no `REGRAS_CANONICAS`, aí implemento consumo + botão no card + mira do
  líder.
- **B16 — VFX de impacto por elemento.** `ElementImpact.gd` já roda; falta
  conferir a coreografia contra `README_VFX.md §3` e afinar tempos (900ms).
- **Afinar `y` das formações** contra os backdrops claros.
- **B9** — enxugar de vez a top bar (score/moeda/gema fora da batalha) — depende
  de definir a camada de conta.
- Dívida do Designer: reexportar `card_face_*`, `char_nature`, `sym_*` em escala
  inteira.

## Como seguimos

## Como seguimos

1. Preencher C1–C7.
2. Marcar cada B como `aceito` / `adaptado` / `recusado`.
3. Quando chegar `Downloads\coisasdogame`: comparar e acrescentar o que for novo à tabela B.
4. Implementar em commits pequenos, um sistema por vez, testes verdes.

---

## Log de decisões

### 2026-09-06 — rodada 1 (C1–C7)

- **C1 = b.** Carta selecionada sobe −14px + pulso único. Revoga o comentário de
  `FieldSlot` ("cartas ficam rigorosamente paradas na grade").
- **C2 = b.** Skill do aliado usa o medidor de **8** ("8 energias"). Skill de líder
  é cooldown independente (**4 turnos** por ora). A "energia 0–20" da top bar é
  recurso de meta (entrar em batalhas), não alimenta skill — fica só exibida.
- **C3 = a.** Mantida a regra canônica de carga (+1 / +2 crítico / +1 wild em
  todos). O "+3 por fusão" do laboratório do Designer é só simplificação de
  demo; não entra. Sem mudança em `EstadoBatalha`.
- **C4.** Stages entram agora, com formações **trio → dupla → boss** (mais rápido
  de testar do que trio → trio → boss).
- **C5 = a.** Cinco party cards do mesmo tamanho, líder marcado por placa LEADER.
  Razão: (1) é o que o doc mais recente do Designer diz (`README.md` §party,
  02/09 — "cinco cards do mesmo tamanho... a coroa foi removida"); (2) é o que a
  render de referência `reference/tela_completa.png` mostra; (3) um card central
  15% maior aperta a faixa de 890px e quebra o ritmo dos 5 slots iguais.
  `spec/PARTY_CARD.md` (176×214 + coroa) fica como histórico.
- **C6 = b.** Life bar com tiles (`spec/LIFE_BAR.md`). A `LAYOUT_BATALHA §8` e a
  render mostram barra sólida — contradição resolvida a favor do spec dedicado e
  mais recente.
- **C7 = b.** Dano continua acumulando na corrente e aplicando de uma vez no fim
  (`_anim_ataque_final`). Sem popup por carta / sem chip TOTAL.

### 2026-09-06 — rodada 2 (implementação)

Passos 1–3 da ordem de execução, testes headless verdes:

- **B8 feito.** `atlas.filter_clip = true` em `BitmapFontLabel`, `CardIcon`,
  `EnemyUnit`, `PartyCard`. Captura confirma: `1240` na top bar volta a ler
  certo em zoom fracionário.
- **B5 feito.** `CardIcon`: subida da seleção 10 → 14 px, brilho 1.05 → 1.14,
  curva CUBIC, e novo `_pulso_selecao()` (anel que abre até 1.22 e some em
  340 ms, uma vez por clique).
- **B4 feito.** Novo `shaders/dessaturar.gdshader` + `Arte.material_dessaturar()`.
  `EnemyUnit` morto agora dessatura + brilho .45 no sprite (antes ia a
  `alpha 0.12`); HUD segue no cinza 45%.
- **B3 feito (parte do inimigo).** `EnemyUnit.tremer(vivo)` grava `hit_ms` e o
  `_process` aplica o deslocamento pela fórmula de relógio do spec (amp 7 vivo /
  2 morto, 300 ms, sem tween). Chamado em `_anim_ataque_final` por golpe. O
  tremor de tela inteira (amp 5, 380 ms) entra junto do B1.

Pendente de conferência visual: tremor em movimento e cinza de morte (o teste
headless roda o caminho sem erro, mas não dá pra ver num PNG estático).

### 2026-09-06 — rodada 3 (B15 + B6/B7)

- **B15 feito.** `EstadoBatalha` agora emite `parcelas` por elemento em cada
  golpe (reparte o dano do alvo proporcional à contribuição bruta, a última
  fecha a conta). `BattleScreen._anim_ataque_final` roda um `ElementImpact` +
  um `_dano_subindo()` por parcela — número na cor clara do elemento, curva
  `labRise` (pop .7 → 1.12), sombra `#201f1d`, empilhados e escalonados
  (~110 ms). Timing do dano inalterado (C7).
- **B6 feito.** `EstadoBatalha`: `ESTAGIOS = [[0,1,2],[3,4],[0]]`, `_montar_estagio(n)`,
  `estagio`/`estagios_totais`. Último inimigo a 0 → se não é o último estágio,
  emite `troca_estagio` e reconstrói `inimigos` (boss × `BOSS_MULT` = 3).
  `BattleScreen`: `_construir_inimigos()` extraído, `_anim_troca_estagio()`
  (flash bone + troca do conjunto no pico + `StagePlate.set_stage`).
  Sim de regra: 30/30 vitórias, ~17 turnos/partida (era ~6). Tela: avança de
  trio → dupla dentro de 5 turnos, `_inimigos` e `estado.inimigos` em sincronia.
- **B7 feito (já alinhado).** Presets 1/2/3 de `Unidades` já batem com
  `battle_layout.gd`; dígito do turno já escala por `hud_tam`.
- **StagePlate** agora lê `estado.estagio` (mostrava "2/3" fixo; agora "1/3").
- Resíduo do B8: em viewport minúsculo (450px do `capture_phone_ratio`) a moeda
  ainda lê `: 240` — é subamostragem do próprio glifo, não sangramento; some com
  `CONTENT_SCALE` inteiro. Na janela real do projeto (558px) já lê `1240`.

### Ordem de execução acordada

1. B8 (fonte `filter_clip`) — rápido, destrava leitura.
2. B5 (seleção sobe + pulso).
3. B3 (tremor por relógio) + B4 (morte por dessaturação).
4. B1 (fusão na mão: leque + glow + feixe reto) — afinar quando chegar o pacote novo.
5. B6 + B7 (stages trio→dupla→boss + formações do `battle_layout.gd`).
6. B9 (enxugar top bar) + B14 (life bar em tiles).
7. B12/B13 (skills: consumo dos 8 pips + skill de líder com mira) — depois de
   `REGRAS_CANONICAS_ALPHA.md` receber os efeitos das 5 skills.
8. B11 (cenário) quando o asset chegar. B10 adiado.
