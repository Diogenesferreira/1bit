# 07 · Interações, estados e animações

Tudo o que a tela de batalha **faz** no mockup: o que dispara cada mudança, os estados de cada peça, tempos, curvas e quais texturas do kit usar.
Os valores foram tirados da lógica que roda no canvas. Medidas em **px na escala 1024 × 1600** (o dobro dos valores do mockup).

> **Como ler:** "Mockup" = o que já existe e deve ser reproduzido igual. Blocos marcados **Sugestão para o Godot** são ideias de polimento que o mockup não tem — use se quiser, mas não fazem parte do visual aprovado.

Referências quadro a quadro de cada interação estão em **`reference/sequences/`**:
- uma pasta por interação, com `fN_<nome>_tela.png` (tela inteira) e `fN_<nome>_<peça>.png` (recortes)
- `NN_<nome>_tira.png` — tira comparativa: uma linha por peça, uma coluna por quadro
- `sequences_index.json` — lista de quadros e o estado usado para gerar cada um

---

## 0. Curvas e tempos usados

| nome no mockup | tempo | curva | o que faz | onde aparece |
|---|---|---|---|---|
| transição de valor | **0.30 s** | `ease` (cubic-bezier .25,.1,.25,1) | anima largura da barra / arco do anel | HP da equipe, vida no pop-up, anéis de chão |
| transição da carta | **0.12 s** | `ease` | subir/descer e ligar/desligar o anel âmbar | carta selecionada |
| `pop` | **0.18 s** (pop-up) · **0.16 s** (aviso) | `ease-out` | opacidade 0→1 e deslocamento vertical **+10 px → 0** | pop-up do alvo, aviso |
| `ret` | **1.4 s** loop | `ease-in-out` | opacidade 0.6 → 1.0 → 0.6 | mira do alvo |
| `fast` | **0.8 s** loop | `ease-in-out` | opacidade 1.0 → 0.5 → 1.0 | contador de ataque iminente (chip e caixa ATQ do pop-up) |

Tempos de lógica:

| evento | tempo |
|---|---|
| 3ª carta escolhida → combo resolve | **280 ms** |
| aviso de dano → aviso de ataque inimigo | **950 ms** depois |
| duração de um aviso na tela | **1900 ms** — um aviso novo substitui o anterior e **reinicia** a contagem |

Equivalente no Godot: `Tween` com `TRANS_CUBIC`/`EASE_OUT` para `pop`; `TRANS_SINE`/`EASE_IN_OUT` em loop para `ret` e `fast`; `TRANS_QUAD`/`EASE_IN_OUT` aproxima o `ease` do CSS.

---

## 1. Seleção de cartas e combo

Referência: `reference/sequences/01_selecao_de_cartas/` · `01_selecao_de_cartas_tira.png`

### Regras
- Toque numa carta → seleciona. Toque de novo na mesma → **desmarca** (as outras mantêm a ordem).
- Máximo **3**. Toques numa 4ª carta são ignorados.
- Ao escolher a **3ª**, espera **280 ms** e resolve.
- Combo válido:
  - 3 cartas do **mesmo elemento**; **Wild** substitui qualquer elemento.
  - 3 Wild → usa o elemento do aliado **A1** (líder).
  - 3 **Capsule** → cura.
  - Capsule misturada com qualquer outra → **inválido**.
  - Dois elementos diferentes (fora os Wild) → **inválido**.
- Combo inválido: aviso vermelho, a seleção é limpa, **as cartas ficam** e **o turno não passa**.

### Estados visuais de cada carta
| estado | visual (1024) | textura |
|---|---|---|
| normal | sombra `0 6 14` preto 50% | `cards/card_<elemento>@2x.png` + `card_value_plate.png` |
| selecionada | **sobe 10 px**; anel âmbar de **5 px**; brilho âmbar blur 36 px 60%; sombra `0 16 28` 55% — tudo em **0.12 s** | `cards/card_frame_selected.png` + `card_order_badge.png` |
| índice | selo 28×28 âmbar, a 6 px da direita e 8 px do topo, número 1/2/3 na ordem do toque | `cards/card_order_badge.png` (texto Martian Mono 16 px peso 600 `#1A1105`) |

### Indicadores do banco
- **Combo** (3 quadrados 18×18, espaço 6): acendem em `#F2A33C` conforme a quantidade selecionada; apagados `rgba(242,163,60,.18)`. Texturas `hud/bank/bank_combo_off.png` e `bank_combo_2of3.png`. Não animam no mockup.
- **Fila**: próximas 4 cartas (32×38), opacidades **1.0 · 0.8 · 0.6 · 0.4**. Ao resolver, as cartas usadas são trocadas pelas próximas da fila, **no mesmo lugar do grid**.

### Resultado do combo (válido)
| | fórmula |
|---|---|
| dano | soma dos 3 números × **20** (× **1.25** arredondado se o líder estiver ativo) |
| cura | soma × **35**, limitada ao HP máximo |
| dano excedente | se o alvo morrer, o resto passa para o próximo inimigo vivo (ordem E1 → E2 → E3) |
| novo alvo | se o alvo morrer, o alvo passa para o primeiro inimigo vivo |
| skill | o aliado daquele elemento ganha **+34** (máx. 100) — só em combo de dano |

### Linha do tempo de um combo (mockup)
```
t = 0 ms     3ª carta: sobe 10px (0.12s), selo "3", quadrado 3 acende
t = 280 ms   resolve, tudo no mesmo quadro:
             · seleção limpa → as cartas descem (0.12s)
             · cartas usadas trocadas pelas da fila (troca instantânea)
             · anel de vida do alvo e barra do pop-up diminuem (0.30s)
             · anel de skill do aliado do elemento enche (0.30s)
             · contadores de ataque descem 1; quem chega a 0 ataca e volta a 3
             · HP da equipe cai pelo ataque (0.30s)
             · aviso "DANO 360 · DRAGON" entra (0.16s)
t = 1230 ms  se houve ataque: aviso vermelho "DUSK DRAGON ATACOU · -130" substitui o anterior
t = 3130 ms  aviso some
```

> **Sugestão para o Godot:** separar em batidas — cartas saem (0.15 s) → dano no alvo com número flutuante → contra-ataque (0.95 s) com tremor leve do visor e o HP da equipe caindo junto do aviso vermelho → cartas novas entram da fila (0.2 s, escalonadas).

---

## 2. Botão de líder

Referência: `reference/sequences/02_lider/` · `02_lider_tira.png`

### Ciclo
```
DISPONÍVEL ──toque──▶ ATIVO ──toque──▶ DISPONÍVEL   (cancelar, sem custo)
                        │
                        └─ combo de dano resolve ─▶ dano × 1.25 ─▶ RECARGA 3
RECARGA n ──cada combo de dano resolvido──▶ RECARGA n-1 … ─▶ DISPONÍVEL
RECARGA n ──toque──▶ nada muda; aviso vermelho "LIDERANÇA RECARREGA · n"
```
- Ativar: aviso âmbar **"LIDERANÇA ATIVA · +25% NESTE TURNO"**. Cancelar: aviso âmbar **"LIDERANÇA CANCELADA"**.
- O bônus vale só para **o próximo combo de dano**; depois disso o botão entra em **recarga de 3**. Ex.: Dragon 4 + Dragon 4 + Wild 10 = 18 × 20 = 360 → com líder **450**.
- **Comportamento atual do mockup (revisar ao programar):** combos de **cura** e **combos inválidos** não gastam o líder ativo nem descontam a recarga; o disparo de skill também não.

### Estados visuais
| estado | fundo | contorno | coroa + texto | texto | textura (caixa / referência) |
|---|---|---|---|---|---|
| disponível | `#201C13` | interno 2 px `rgba(242,163,60,.3)` | `#F2A33C` | **LÍDER** | `buttons/button_leader_normal.png` / `_normal_ref.png` |
| ativo | `#F2A33C` | — | `#1A1105` | **LÍDER ON** | `button_leader_active.png` / `_active_ref.png` |
| recarga | `#201C13` | interno 2 px `rgba(242,163,60,.3)` | coroa `rgba(245,239,226,.3)`, texto `.35` | **CD 3 / CD 2 / CD 1** | `button_leader_cooldown.png` / `_cooldown_ref.png` |

Ícones: `icons/ui/icon_crown_normal`, `icon_crown_active`, `icon_crown_cooldown` (.svg / 48 / 96). Altura do botão 38 px, raio 10, a largura acompanha o texto.
No mockup a troca de estado é **instantânea**.

> **Sugestão para o Godot:** ao ativar, um pulso de escala 1.0→1.08→1.0 em 0.2 s e um brilho âmbar; em recarga, o número pode fazer um *tick* (escala 1.15→1) quando desce.

---

## 3. Skill do aliado

Referência: `reference/sequences/03_skill_do_aliado/` · `03_skill_do_aliado_tira.png`

### Regras
- Carga de **0 a 100**. Cada combo de dano do elemento do aliado dá **+34**.
- Toque no aliado:
  - com carga **< 100** → aviso âmbar **"SKILL DRAGON 45%"** e nada acontece;
  - com **100** → **600 de dano** no alvo (ou no primeiro inimigo vivo), a carga volta a **0** e aparece o aviso **"SKILL DRAGON · -600"**.
- Disparar skill **não passa o turno** (os contadores de ataque não descem).

### Visual
| estado | anel de chão | chip |
|---|---|---|
| carregando | arco na **cor viva do elemento** proporcional à carga; anima **0.30 s** a cada mudança | `hud/stage/chip_ally_box.png` + selo + "LV 38" |
| pronta (100) | arco cheio + **brilho** da cor do elemento (blur 10 px) | moldura âmbar 2.6 px + brilho âmbar 20 px 60% (`hud/stage/chip_frame_ready.png`) e texto **PRONTA** âmbar (Martian Mono 12 px, 600) |
| disparou | arco volta a 0 (0.30 s), brilho e PRONTA somem | volta ao normal |

Anel: `hud/stage/ring_<slot>_under.png` + `_progress.png` (branco, com `tint_progress` = cor do elemento) + `_over.png`. `TextureProgressBar`: `fill_mode = CLOCKWISE`, `radial_initial_angle = 90`, valor = carga.
Cores vivas dos anéis: Dragon `#FF5A3D` · Knight `#4DA8FF` · Nature `#5BD75B` · Light `#FFC93C` · Dark `#B06BFF`.
No mockup o brilho de "pronta" é **fixo**, sem piscar.

> **Sugestão para o Godot:** pulsar o brilho do anel pronto (0.6 → 1.0 em 1.2 s) para chamar o toque; no disparo, um flash no aliado e um rastro até o alvo.

---

## 4. Contador de ataque dos inimigos

Referência: `reference/sequences/04_contador_de_ataque/` · `04_contador_de_ataque_tira.png`

### Regras
- Cada inimigo tem um intervalo de ataque (**3** para todos no mockup) e um contador.
- A cada **combo válido resolvido** (dano ou cura), cada inimigo vivo desconta **1**.
- Quando o contador chega a **0** o inimigo ataca a equipe, somando o dano de todos que atacaram, e o contador **volta para 3**.
- Dano de ataque no mockup: Long Ear Guardian **220**, Dusk Dragon **130**, Twin Tail **150**.
- Aviso vermelho **"DUSK DRAGON ATACOU · -130"** (ou `"A + B ATACOU · -350"` com dois) **950 ms** depois do aviso do combo.

### Visual (chip e caixa ATQ do pop-up usam a mesma regra)
| contador | cor do número e segmentos | segmentos acesos | animação |
|---|---|---|---|
| 3 | `rgba(242,163,60,.75)` · segmentos `.55` | 3 | nenhuma |
| 2 | `#F2A33C` | 2 | nenhuma |
| 1 (iminente) | `#FF6B4A` | 1 | **`fast` 0.8 s** (opacidade 1 ↔ 0.5) |

Segmento apagado: `rgba(242,163,60,.18)`. Segmentos do chip 10×5 px (raio 2); no pop-up 14×6 px.
Referências: `hud/stage/chip_turn_amber_ref.png`, `chip_turn_red_ref.png`, `chip_enemy_imminent_ref.png`; caixa ATQ do pop-up `hud/popup/popup_turn_box_amber.png` / `_red.png` (o contorno interno assume a cor da tabela).

> **Sugestão para o Godot:** quando o contador vira 1, um *pop* de escala no chip; no ataque, o inimigo avança alguns pixels e volta, com um flash vermelho no HP da equipe.

---

## 5. HP da equipe

Referência: `reference/sequences/05_hp_da_equipe/` · `05_hp_da_equipe_tira.png`

| HP / máximo | cor da barra e do rótulo "EQUIPE HP" |
|---|---|
| acima de 40% | menta `#6FE3B8` |
| de 40% até 20% | âmbar `#F2A33C` |
| abaixo de 20% | vermelho `#FF6B4A` |

- A largura anima em **0.30 s**; a cor troca **no mesmo instante** em que cruza o limiar.
- Texto: `2840` em cream + `/3200` em cream 38% (Martian Mono 19 px, 500).
- HP chega a **0** → aviso vermelho **"DERROTA · EQUIPE CAÍDA"**.
- Texturas: `hud/team/team_hp_under.png` + `team_hp_progress.png` (branco, com `tint_progress` pela tabela) ou as prontas `team_hp_progress_mint/amber/red.png`.

---

## 6. Inimigo abatido

Referência: `reference/sequences/06_inimigo_abatido/` · `06_inimigo_abatido_tira.png`

- Vida chega a 0 → o personagem fica com **opacidade 35% e em escala de cinza** (troca instantânea no mockup); o anel de vida mostra 0.
- Deixa de atacar e sai da contagem de turnos.
- **Comportamento atual do mockup (revisar ao programar):** o chip do abatido continua visível e mostra o último contador de ataque (inclusive o "1" vermelho piscando). O esperado é esconder o contador ou o chip inteiro.
- Tocar nele → aviso vermelho **"ALVO ABATIDO"**; o alvo não muda.
- Se era o alvo, a mira e o pop-up passam para o primeiro inimigo vivo.
- Todos abatidos → aviso menta **"VITÓRIA · SETOR LIMPO"**.

> **Sugestão para o Godot:** 0.35 s de fade + dessaturação e um leve afundar (4–6 px) em vez da troca seca.

---

## 7. Alvo, mira e pop-up

Referência: `reference/sequences/07_popup_do_alvo/` · `07_popup_do_alvo_tira.png`

### Regras
| ação | resultado |
|---|---|
| toque em inimigo vivo que **não** é o alvo | vira o alvo, a mira vai até ele e o pop-up **abre** |
| toque no alvo com pop-up **aberto** | pop-up **fecha** (a mira continua no alvo) |
| toque no alvo com pop-up **fechado** | pop-up **abre** |
| toque em inimigo abatido | aviso "ALVO ABATIDO" |

- A tela começa com o pop-up **fechado** e o alvo em **E1**.
- A **mira fica sempre** no alvo, piscando com `ret` (1.4 s).
- Pop-up entra com `pop` **0.18 s**. No mockup ele some sem animação ao fechar.
- **Posição:**
  - se couber acima da cabeça, abre centralizado acima do alvo (preso às bordas do visor), com a seta para baixo;
  - se não couber, abre no topo do visor, à esquerda do alvo, com a seta para a direita.
  - Regra completa em `05_palco.md`.
- Conteúdo que atualiza ao vivo: % de vida, barra (0.30 s), `hp / max`, contador ATQ.
- Texturas: `hud/popup/popup_target_box.png`, `popup_target_arrow_down.png`, `popup_target_arrow_right.png`, `popup_hp_under/progress.png`, `popup_turn_box_amber/red.png`; mira `hud/visor/aim_chefe.png`, `aim_inimigo.png`, `aim_chefe_sozinho.png` (ou 4 cantoneiras de 34 px, traço 3 px `#FF6B4A`).

> **Sugestão para o Godot:** mira deslizando até o novo alvo em 0.15 s; pop-up fechando com o `pop` invertido (0.12 s).

---

## 8. Avisos (toast)

Referência: `reference/sequences/08_avisos/` · `08_avisos_tira.png`

- Uma única faixa centralizada, topo em **y = 904**, altura 50 px, raio 14, fundo `rgba(16,13,9,.96)`, contorno interno de 2 px e texto na **cor do tom**, sombra `0 12 40` 60%.
- Texto Martian Mono 19 px, peso 600, espaçamento 0.6 px.
- Entra com `pop` **0.16 s**, fica **1900 ms**; um aviso novo substitui o atual e reinicia o tempo. No mockup some sem animação.
- Texturas: `hud/toast/toast_box_amber.png`, `toast_box_red.png`, `toast_box_mint.png` (9-slice; largura acompanha o texto, padding 28 px nas laterais).

| mensagem | tom | quando |
|---|---|---|
| `DANO 360 · DRAGON` | âmbar `#F2A33C` | combo de dano |
| `CURA +770` | menta `#6FE3B8` | combo de 3 Capsules |
| `COMBO INVÁLIDO · CAPSULE NÃO MISTURA` | vermelho `#FF6B4A` | Capsule misturada |
| `COMBO INVÁLIDO · ELEMENTOS DIFERENTES` | vermelho | elementos diferentes |
| `LONG EAR GUARDIAN ATACOU · -220` | vermelho | ataque inimigo (+950 ms) |
| `SKILL DRAGON 45%` | âmbar | toque em aliado sem carga |
| `SKILL DRAGON · -600` | âmbar | skill disparada |
| `LIDERANÇA ATIVA · +25% NESTE TURNO` | âmbar | líder ativado |
| `LIDERANÇA CANCELADA` | âmbar | líder desativado |
| `LIDERANÇA RECARREGA · 2` | vermelho | toque no líder em recarga |
| `ALVO ABATIDO` | vermelho | toque em inimigo abatido |
| `VITÓRIA · SETOR LIMPO` | menta | todos os inimigos abatidos |
| `DERROTA · EQUIPE CAÍDA` | vermelho | HP da equipe em 0 |
| `EQUIPE · TELA RESERVADA` (INVOCAR, LOJA) | âmbar | botões de navegação ainda sem tela |
| `FASES · NOVA PARTIDA` | âmbar | FASES reinicia a partida |

---

## 9. Navegação

- **EQUIPE / INVOCAR / LOJA**: aviso "… · TELA RESERVADA" (placeholder até as telas existirem).
- **FASES** (botão principal âmbar): reinicia a partida com o estado inicial abaixo.
- Texturas: `buttons/button_nav_normal.png`, `button_nav_primary.png`; ícones `icons/nav/`.
- No mockup os botões não têm estado pressionado.

> **Sugestão para o Godot:** estado pressionado com escala 0.96 e contorno âmbar 40%.

---

## 10. Áreas de toque

| peça | área |
|---|---|
| personagem (aliado ou inimigo) | retângulo centralizado no pé, largura = quadro × 0.62, altura = quadro × 0.97 × 0.9, **acima** do pé |
| carta | o slot inteiro (152 × 177) |
| líder, navegação | o botão inteiro |

Pop-up, chips, anéis e aviso **não** capturam toque.

---

## 11. Estado inicial da partida (mockup)

| | valor |
|---|---|
| HP da equipe | 2840 / 3200 |
| round | 3 / 3 |
| alvo | E1 · pop-up fechado |
| líder | disponível (recarga 0) |
| aliados (LV · skill) | A1 Crimson Clamp dragon 38 · 45 — A2 Bone Raider dark 38 · 30 — A3 Panda Gunner knight 38 · 55 — A4 Twin Apes light 38 · 30 — A5 Flora Fairy nature 38 · 30 |
| inimigos (LV · HP · dano · contador) | E1 Long Ear Guardian light 40 · 1850/4000 · 220 · 2 — E2 Dusk Dragon dark 36 · 1200/1200 · 130 · 1 — E3 Twin Tail nature 36 · 1400/1400 · 150 · 3 |
| poder das cartas | Dragon 4 · Knight 7 · Nature 6 · Light 9 · Dark 8 · Capsule 5 · Wild 10 |
| banco (esq→dir, cima→baixo) | Dragon, Knight, Nature, Light, Dark, Wild / Capsule, Dragon, Knight, Nature, Wild, Light |
| ordem da fila (cíclica) | Knight, Nature, Light, Dark, Wild, Dragon, Light, Nature, Dragon, Dark, Knight, Wild, Capsule, Nature, Light, Dragon, Dark, Knight |

Esses números são de teste do mockup — as regras finais de balanceamento ficam para a etapa de gameplay.
