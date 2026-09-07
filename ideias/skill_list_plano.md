# Skills — da lista gigante para 5 testáveis

`skill_list.lua` tem ~150 skills do Digimon Heroes/Crusader. **Não** dá pra
implementar/testar tudo agora. Este arquivo é o recorte.

## As ~150 skills cabem em 13 famílias de efeito

| # | família | exemplos da lista | mexe em |
|---|---|---|---|
| 1 | dano a 1 alvo | Damage Enemy, Gamble Attack | HP do inimigo |
| 2 | dano em área | Small/Large Damage to All | HP de todos |
| 3 | dano com custo | Sacrifice Strike, Suicide Attack | HP inimigo + HP time |
| 4 | reflexão de dano | Damage Return | dano recebido na corrente |
| 5 | absorção (dano→cura) | Absorption | HP inimigo + HP time |
| 6 | expulsão / KO por chance | One/All blow, KO Enemy | remove inimigo (rng) |
| 7 | cura | Small/Medium/Large/Total Recovery | HP do time |
| 8 | buff de ataque | Attack Boost (por elemento / todos) | `ataque` do aliado, N turnos |
| 9 | buff de defesa / escudo | Defense Boost, 25%/75% Defense, Weaken | dano recebido, N turnos |
| 10 | debuff no inimigo | Enemy Attack/Defense Down | `ataque`/`defesa` do inimigo |
| 11 | controle de tempo | Enemy Attack Delay, Skill Boost | `contador_inimigo` / carga de skill |
| 12 | valor das cartas | Evolution +1/+2, All Nine | `mao[].valor` |
| 13 | manipulação do BAG/mão | Drive/Support, Reshuffle, Replace, Release, Seal, All-X, Wild Boost | `mao` / `proximas` / composição do `Saco` |

A família 13 é a assinatura do jogo (BAG). O `SKILLS_REFERENCIA_E_BALANCEAMENTO.md`
na raiz já tem essa quebra em §2 e faixas de segurança (verde/amarela/vermelha) em §3.

## O conjunto da alpha já está escolhido

`SKILLS_REFERENCIA_E_BALANCEAMENTO.md` §4 — um por aliado, cobrindo famílias
diferentes:

| aliado | skill | família | efeito |
|---|---|---|---|
| Draco de Brasa (dragon) | **Impacto de Brasa** | 1 — dano a 1 alvo | ~2,5× um combo comum no alvo selecionado |
| Guardião de Ferro (knight) | **Bastião** | 9 — escudo | −45% no próximo dano inimigo ao HP do time |
| Maga do Bosque (nature) | **Crescimento** | 12 — valor das cartas | +1 no valor de todas as cartas da mão (teto 9) |
| Clériga Astral (light) | **Luz Restauradora** | 7 — cura | +30% do HP máximo compartilhado |
| Oráculo Chacal (dark) | **Eclipse** | 11 — tempo | +1 no contador inimigo (sem passar do teto) |

## Como implementar (forma, não é muito código)

Segue o mesmo contrato do resto do jogo: **lista de eventos já resolvida**.

1. `EstadoBatalha.usar_skill_aliado(indice) -> Dictionary`
   - checa `aliados[indice].skill >= skill_max` (8 pips) e vivo;
   - zera `aliados[indice].skill` (consumo — atualiza a regra que hoje diz
     "não consome");
   - aplica o efeito da skill daquele elemento;
   - devolve `{tipo:"jogada", eventos:[{tipo:"skill_aliado", elemento, ...}, ...]}`.
2. Cada um dos 5 efeitos é uma função curta:
   - Impacto de Brasa → reusa o caminho de dano de `_resolver_ataque_final`;
   - Bastião → grava `escudo_proximo := 0.45`, consumido em `_turno_inimigo`;
   - Crescimento → `for c in mao: c.valor = mini(9, c.valor + 1)`;
   - Luz Restauradora → `hp = mini(hp_max, hp + round(hp_max * 0.3))`;
   - Eclipse → `contador_inimigo = mini(contador_inimigo_max, contador_inimigo + 1)`.
3. `BattleScreen._anim_skill(ev)` anima cada tipo; `PartyCard` já emite
   `skill_activated` quando a barra enche (8 pips).
4. Skill de líder = mesma mecânica, cooldown de 4 turnos + modo de mira.
5. Teste headless: cada efeito é verificável isolado em `test_batalha.gd`
   (chama `usar_skill_aliado` e confere o estado).

Números de dano/percentual ficam em constantes no topo de `EstadoBatalha`, como
o resto do balanceamento — ajustáveis pelas 30 partidas simuladas.

## Cooldown / "peso" de cada família (dado real da referência)

O `Module:.../Skills` do Fandom **só tem as descrições** — nenhum número. Os
turnos de recarga estão em `referencia_digimon_heroes/colecao_cartas.csv`
(colunas `main_skill_turns` / `leader_skill_turns`). Faixa global: **3 a 23**
turnos (média ~10). Por família:

| skill de referência | turnos (min/méd/máx) | leitura |
|---|---|---|
| Evolution 1 (+1 no valor) | 4 / 5 / 6 | mais barata |
| Small Absorption | 4 / 5 / 6 | barata |
| Evolution 2 (+2) | 6 / 7 / 8 | barata |
| Medium Recovery (cura 50%) | 6 / 7 / 8 | barata |
| All Nine | 8 / 9 / 10 | média |
| 25% Defense | 8 / 9 / 10 | média |
| Small Enemy Attack Delay | 8 / 9 / 10 | média |
| Large Recovery | 9 / 9 / 10 | média |
| Large Damage Return | 9 / 10 / 10 | média |
| Big Enemy Attack Delay | 14 / 14 / 15 | cara |
| Large Damage to All | 14 / 15 / 16 | cara |
| Damage Enemy (dano máx. 1 alvo) | 15 / 15 / 16 | cara |
| 75% Defense | 15 / 16 / 16 | cara |
| Large Skill Boost | 18 / 19 / 19 | muito cara |
| Damage All Enemies (dano máx. em todos) | 20 / 21 / 21 | a mais cara |

**Padrão:** barato = manipulação de carta / cura pequena / delay pequeno;
caro = AoE forte / escudo forte. As 5 da alpha, na régua da referência:

| alpha | equivalente | peso relativo |
|---|---|---|
| Crescimento | Evolution 1 | ~5 (barata) |
| Luz Restauradora | Medium/Large Recovery | ~7–9 |
| Eclipse | Small Enemy Attack Delay | ~9 |
| Bastião | 25% Defense (leve) / 75% (forte) | ~9 a ~15 |
| Impacto de Brasa | Damage Enemy | ~15 (cara) |

Na alpha tudo carrega em **8 pips** (simples, pra testar). O tiering acima é a
intenção pra quando as skills forem canonizadas — não precisa entrar já.

## Stat de Support

O CSV tem 4 stats, não 3: `atk`, `defense`, `hp`, **`support`** (média ~110–134
por elemento, mesma ordem de grandeza dos outros). É o multiplicador de cura e
força de skill. Não temos. Decisão em `gameplay_digimon_heroes.md` §"Diferenças".
