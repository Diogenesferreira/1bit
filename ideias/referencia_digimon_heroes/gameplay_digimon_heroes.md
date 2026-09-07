# Digimon Heroes / Crusader — mecânicas de gameplay (varredura da wiki/guias)

Fontes: guias derivados da DigimonWiki (Big Shark Gaming parte 1–2, GameRevolution,
Android Authority, MMOHuts). A `Module:Digimon_Heroes_Data/Skills` do Fandom está
bloqueada para leitura automática — o conteúdo dela já está em `skill_list.lua`.

---

## 1. Batalha por cartas (match-3)

- Mão de **10 cartas**, espécie/cor misturadas, valores **1–9**, com duplicatas
  possíveis, mais **coringas (wild)**.
- O jogador escolhe **3 cartas** por turno; o resto da corrente é **automático**
  (a IA encadeia).
- Ao marcar a 1ª carta aparece a **11ª**; ao marcar a 2ª aparece a **12ª**. Com a
  carta do **NEXT** o jogador enxerga de fato **13 cartas**.
- Se a mão chegar a **1 carta**, as **12 são substituídas**.
- Usar **todas as 12** dá bônus de **1,5× de ataque**.

## 2. Trio, sequência e crítico

- Fecha combo com **3 da mesma espécie/cor** OU **3 em sequência numérica**
  (1-2-3, 2-3-4, …).
- **3 valores iguais** OU **3 em sequência** = **crítico** (mais dano).
- **Coringa** casa em qualquer combo; **3 coringas** = "Wild Critical Attack"
  (todos os monstros atacam).
- Fechado um combo, **todo grupo de 3 pronto na mão dispara em cadeia**,
  automático.

## 3. Elementos e afinidade

Cinco tipos: **Dragon, Knight, Holy (Luz), Darkness (Trevas), Nature**.

```
Dragon > Nature > Knight > Dragon   (ciclo)
Holy <-> Darkness                   (mútuo)
```

Guias não dão os multiplicadores exatos de vantagem/resistência. Cartas de
**dois elementos** existem (ex.: "Devimon vs. Patamon" = luz + trevas).

## 4. Skills — ativa (main) e de líder

- Cada Digimon tem **uma skill ativa** e **uma skill de líder**.
- Ambas **carregam por turnos**; duração/cooldown observado entre **5 e 18 turnos**
  (`main_skill_turns` 3–23, `leader_skill_turns` 3–24 na base bruta).
- Efeitos: dano, buff, debuff, cura, manipulação de mão/BAG — ver as 13 famílias
  em `../skill_list_plano.md`.
- A skill de líder parece **disparar sozinha no ciclo** ("Agumon: restaura HP a
  cada 6 turnos"), não por toque manual. **Diferença** para o nosso plano atual
  (líder por mira + cooldown 4).

## 5. Stats das unidades

**Attack · Defense · HP · Support.**
O **Support** escala cura e força de skill — **não existe no nosso modelo** (só
ataque/defesa/HP). Decidir se entra.

## 6. Coleção e progressão

- **Raridade 1–5 estrelas**; nível máximo amarrado à raridade.
- **Digivolução**: nível mínimo + Digimon complementares de tipo/nível +
  **Capacitores de Evolução** (por cor: RED/BLUE/…) + moeda **Bit**.
  Ex.: *MetalGreymon = nível 20 + dragão nível 8 + cavaleiro nível 3 + trevas
  nível 3 + 10 Capacitores Médios (RED) + 2000 Bit*.
- **Energia**: cada fase custa **4–5**, regenera **1 a cada 3 min** — é recurso
  de entrada de fase (confirma: no nosso jogo a energia da top bar é meta, não
  alimenta skill).
- Cada fase tem **3–5 rounds** (bate com o nosso trio → dupla → boss = 3).

---

## O que CONFIRMA o nosso design

| nosso | referência |
|---|---|
| mão 10 + 2 ENTRADAS + NEXT | 10 + 11ª/12ª + NEXT = "13 cartas" |
| mão chega a ≤1 → renovação | "chega a 1 carta → 12 substituídas" |
| `DISTRIBUICAO_FINAL_ACELERACAO = 1,5` | "todas as 12 = 1,5× ataque" |
| crítico por trinca ou sequência | igual |
| trio de wild bate em todos | "Wild Critical Attack, todos atacam" |
| afinidade Dragon>Nature>Knight>Dragon, Luz↔Trevas | igual |
| cascata automática de trios prontos | "grupo de 3 dispara em cadeia" |
| energia da top bar = meta (entrar em fase) | "fase custa 4–5, regen 1/3min" |
| batalha em 3 estágios | "3–5 rounds por fase" |

## 7. Estatísticas da coleção (varredura dos 987 cards do CSV)

As páginas `/Collection/Dragon|Knight|Nature|Dark|Holy` do Fandom = o
`colecao_cartas.csv` desta pasta. Nada novo pra baixar. O que ele mostra:

### Escada de geração (stats médios atk/def/hp/support · max_lv)
| geração | n | atk | def | hp | sup | max_lv |
|---|---:|---:|---:|---:|---:|---:|
| Child | 92 | 79 | 72 | 85 | 74 | ~22 |
| Adult | 153 | 120 | 105 | 114 | 93 | ~36 |
| Perfect | 228 | 145 | 134 | 139 | 117 | ~51 |
| Ultimate | 410 | 163 | 148 | 163 | 129 | ~58 |
| Armor / Hybrid | 61 | ~135 | ~137 | ~144 | ~123 | ~50 |

Cada degrau ≈ **+20–40%** nos stats. É uma curva de progressão limpa pra copiar
a forma (não os números).

### Raridade → poder total (soma dos 4 stats)
`Common ~209 · Uncommon ~277 · Rare ~370` → tiers evoluídos
`Queen ~471 · King ~523 · God ~601 · SP+ ~683 · Legendary Rare ~794`.
Há **dois sistemas de raridade** na base: palavra (Common…Rare) e o tier de topo
(Queen/King/God/SP/Legendary).

### Os elementos NÃO são diferenciados por stat
Proporção média atk/def/hp/sup, por elemento:
`Dragon 29/24/27/21 · Dark 28/24/27/21 · Knight 27/26/25/21 · Nature 25/25/28/22 · Holy 25/25/26/24`.
Praticamente iguais. **A diferença entre elementos é a skill e a afinidade, não
o espalhamento de stats.** (Holy pende levemente pra support; Dragon/Dark pra
atk.) → nossos aliados com `ataque` 7/5/6/4/6 é escolha nossa, não exigência.

### Outros
- `main_skill` ≠ `leader_skill` em **99%** dos cards — cada unidade tem duas
  skills genuinamente distintas.
- `cost` (energia de fase): 1–53, mediana **5**.
- Contagem por elemento: Dragon 233 · Nature 207 · Knight 204 · Dark 197 ·
  **Holy 146** (o mais raro).

## Diferenças / lacunas a decidir

1. **Stat de Support** — a referência tem 4 stats; nós temos 3. Cura/skill sem
   Support fica só no valor das cartas + constante.
2. **Skill de líder auto-dispara no ciclo** (não por toque). Nosso plano é mira
   manual + cooldown 4. Escolher um dos dois.
3. **Multiplicadores de afinidade** — a referência não publica; manter os nossos
   `×1,5 / ×1,0 / ×0,75` de teste.
4. **Cartas de dois elementos** — existem lá; fora do escopo da alpha.
5. **Raridade, digivolução, Capacitores, Bit** — progressão fora da batalha;
   `DESIGN_DO_JOGO.md` já cobre "níveis e evoluções" de forma mais simples.
6. **Range de turnos de skill 5–18** — o nosso 8 pips + líder 4 é bem mais
   curto (deliberado, pra testar rápido).
