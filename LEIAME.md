# 1 Bit Heroes — tela de batalha

O direcionamento de produto, progressão, mapas, modos e monetização está em
[`DESIGN_DO_JOGO.md`](DESIGN_DO_JOGO.md).
As famílias de habilidades encontradas na referência, seus riscos e o primeiro
conjunto proposto estão em
[`SKILLS_REFERENCIA_E_BALANCEAMENTO.md`](SKILLS_REFERENCIA_E_BALANCEAMENTO.md).

Projeto Godot 4.7. O **visual** é o handoff (`ideias/godot_handoff_battle_screen/`),
recriado nativo; a **regra** é a mecânica de trio + cascata dos MDs
(`ideias/regra-de-campo.md`, `mecanica-do-binario.md`), portada para os
elementos e as unidades do handoff. `ideias/` fica fora do projeto
(`.gdignore`) — é material de referência.

## Rodar

```
godot --path .                                    # jogar
godot --headless --path . --script res://tests/test_batalha.gd   # testar
godot --path . --script res://tests/test_batalha.gd              # testar + prints em user://
```

## Como se joga

O campo tem **12 casas**: 2 fileiras de 5 (a mão) + a **coluna 6 de cada
fileira**, que é a casa de ENTRADA e começa vazia.

1. Toque numa carta: ela fica **levantada na própria casa**. No mesmo instante
   **uma carta do topo do saco desce na
   ENTRADA** da fileira — e ela já pode fechar o trio.
2. Segunda carta do mesmo tipo: mesma coisa, a segunda desce na outra
   ENTRADA.
3. Terceira carta: **fecha o trio na hora** (nada desce).

- **Desfazer:** tocar na carta que está na lane **ou na casa vazia de onde
  ela saiu** devolve a carta — e a que tinha descido do saco volta pro topo
  da fila, na mesma ordem. Dá pra desfazer as duas marcações, uma por vez.
- Tocar num tipo diferente **abandona** a cadeia e começa outra — e gasta
  turno, como marcar um combo de verdade.
- **Coringa** (`wild`) casa com qualquer tipo; trio só de coringas bate em
  todos os inimigos. **Cápsula** (`capsule`) é a carta de cura.
- **Crítico** (×1.5): as 3 cartas com o mesmo valor (4-4-4) ou em
  sequência (2-3-4). Por isso o valor 1–9 aparece no canto de cada carta.

**CASCATA:** fechado um trio, todo trio já pronto no resto da mão dispara
sozinho, um atrás do outro, **de graça** — e pode puxar a carta do topo
do BAG para completar. Cada elo soma +30% ao dano. Durante a cascata não
há reposição: as casas vão esvaziando. Se sobrar no máximo 1 carta, a mão
inteira **se renova** e a corrente continua.

Só no fim da corrente o dano acumulado é aplicado de uma vez, as ENTRADAS
entram na mão, o saco faz a chuva final e a mão é redistribuída (agrupada
por tipo, valor crescente) — sempre com trio possível.

O **raio do rodapé** não é energia: mostra quantas correntes faltam para o
inimigo atacar (contador 3, regra de campo §6).

## Estrutura

| Arquivo | O que é |
|---|---|
| `scenes/battle/BattleScreen.tscn` | a tela (cena principal) |
| `scripts/battle/EstadoBatalha.gd` | **a regra**: trio, cascata, entradas, chuva final |
| `scripts/battle/BattleScreen.gd` | monta o layout e reproduz os eventos; não decide regra |
| `scripts/battle/Carta.gd` | a carta: tipo do handoff + valor 1–9 dos MDs |
| `scripts/battle/Saco.gd` | o BAG determinístico (composição fixa, sem rajada) |
| `scripts/battle/Unidades.gd` | os 5 inimigos e 5 aliados (posição, HP, elemento) |
| `scripts/battle/Arte.gd` | única ponte com os assets: arquivos, paleta, fonte |
| `scripts/battle/SkillGauge.gd` | medidor radial persistente de oito blocos |
| `scenes/battle/{Bag,Field,Lane}Slot.tscn` | as casas, uma cena por componente |
| `shaders/inverter*.gdshader` | o `filter: invert(1)` do protótipo (crachá, hit flash, flash de tela) |

A tela recebe a corrente **inteira já resolvida** como lista de eventos e
só reproduz em ordem — nunca consulta o estado no meio da animação.

## Decisões que tive que tomar

- **Campo 2×6.** O handoff desenha 2×5. A coluna 6 (ENTRADA) é exigência
  da mecânica, então as casas encolheram de 171×141 para 138×114 para
  caber no **mesmo vão horizontal** do design (80 a 1063).
- **Valor na carta.** O crítico depende do número, então ele aparece no
  canto. O handoff não tinha número nenhum.
- **Um aliado por elemento.** O lineup v2 cobre diretamente Dragão, Cavaleiro,
  Natureza, Luz e Trevas; cada trio alimenta o aliado correspondente.
- **A corrente inteira bate no mesmo inimigo.** O alvo é sorteado no
  primeiro combo e os elos da cascata somam em cima dele — assim uma
  corrente de 3 combos vira um "-8" visível num bicho só, em vez de três
  "-1" espalhados que não pareciam nada.
- **Balanço** (`EstadoBatalha.gd`, constantes no topo): trio = 2 de dano,
  +30% por elo, crítico ×1.5, cura 1,5, inimigo bate 4 a cada 3 correntes.
  Medido em 30 partidas simuladas: aproximadamente 10,9 turnos por partida,
  2,81 combos por turno e maior corrente de 9 combos.

## O que ainda não existe

- Afinidade elemental: o diagrama está desenhado mas não afeta dano.
- Rodadas: os pips mostram 1/3 e não avançam.
- Efeitos das cinco skills: a carga de oito blocos e o toque já funcionam, mas
  o toque ainda não consome a barra nem executa habilidade.
- HP individual dos aliados não é exibido: o dano vai no HP único do time
  (o coração do rodapé), como decisão canônica.
- Botão de desfazer: a regra tem `desfazer()` com pilha de snapshots (volta
  toque a toque), mas na tela o desfazer é por clique na carta, sem botão.
