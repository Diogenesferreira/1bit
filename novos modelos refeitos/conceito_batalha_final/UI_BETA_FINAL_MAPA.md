# Mapa canônico da UI de batalha — primeiro beta

Data: 30/08/2026. Canvas lógico: **1152×2048**, orientação vertical.

Este documento congela a interface do primeiro beta antes da troca dos cenários
por backgrounds animados. A nova arte de cenário deve entrar atrás da batalha;
não deve deslocar HUD, aliados, cartas ou rodapé.

## Hierarquia vertical

| Zona | Retângulo lógico | Responsabilidade |
|---|---|---|
| Cabeçalho | `y 16–120` | andar, progresso e menu |
| Arena | `x 43, y 126, 1065×1093` | cenário e inimigos |
| Mundo inimigo | arena local `y 0–845` | background animado, inimigos, turno, life e impactos |
| Faixa dos aliados | arena local `x 0, y 846, 1065×247` | cinco Selos de Fragmento fixos |
| Próximas | `y 1247–1398` | fila da bag e carta `NEXT`; permanece estável no combo |
| Campo | `y 1408–1769` | duas linhas de cinco cartas e duas entradas tracejadas |
| Rodapé | `y 1896–1950` | life universal, progresso e contador inimigo |

## Decisões definitivas

- A arena física pertence aos inimigos. Aliados não permanecem de corpo inteiro
  sobre o cenário.
- Os aliados possuem uma faixa carvão plana, separada do mundo apenas pela
  divisória superior. Não há uma segunda caixa fechada em volta da formação.
- Selos medem 190×190, com espaçamento de 20 px e posições sempre fixas.
- Batalha e futuro menu usam `FragmentPortrait.gd`; nenhuma segunda máscara ou
  moldura pode ser criada para o mesmo personagem.
- O campo continua obedecendo a mecânica real 2×5 + duas casas de entrada. Não
  copiar layouts ilustrativos que removam as entradas ou escondam o saco.
- A fila `PROXIMAS` permanece visível e não participa da fusão.
- As três cartas se alinham e convergem no centro do próprio campo, em
  `(576, 1538)`, preservando a leitura espacial original.
- O HUD inimigo permanece compacto e proporcional; não voltar às barras grandes
  que competiam com as criaturas.

## VFX canônicos

### Fusão e energia

1. 0–420 ms: três cartas alinham no campo, com posição arredondada em px inteiro.
2. 420–820 ms: convergem ao centro.
3. 820–1020 ms: clarão osso.
4. 820–1360 ms: anel de 26 quadrados.
5. 1020–1980 ms: 48 partículas percorrem Bézier, cada uma com rastro de três.
6. A carga aplicada continua sendo a regra real do jogo: +1 em combo normal e
   +2 em crítico. A densidade das 48 partículas é visual e não altera balanceamento.
7. Em 8/8, o selo mantém o loop de halo de 1300 ms.
8. Conforme a energia chega, o balão junto ao selo mostra o dano acumulado
   daquele aliado (`+N`).

O fluxo é desenhado por um único `FusionStream`, evitando criar 144 nós por
combo no celular.

### Impacto e dano

- Cada golpe conserva seu elemento dominante até o evento final.
- `ElementImpact.gd` oferece fogo, aço, natureza, luz e trevas em 900 ms.
- O inimigo recebe apenas o impacto elemental e o número de dano final (`-N`).
- O balão manga pertence ao acumulador dos aliados e não aparece no inimigo.
- O life inimigo drena em 420 ms ao mesmo tempo que o impacto acontece.

## Contrato do background animado

O próximo cenário deve substituir somente a textura do nó `BattleBackground`.
Use sprite sheet ou sequência de frames com filtro `Nearest`, sem modificar:

- `Unidades.ARENA` e `Unidades.ARENA_TAM`;
- presets e bases dos inimigos;
- limite local `y = 846`, onde começa a faixa dos aliados;
- coordenadas da fusão, campo e rodapé;
- ordem de desenho: cenário → inimigos → VFX de mundo → faixa dos aliados → UI.

O movimento entre turnos deve atuar na câmera/background, não reposicionar a
interface. Biomas diferentes precisam respeitar uma zona segura de contraste
atrás dos HUDs inimigos.

## Arquivos centrais

- `scripts/battle/BattleScreen.gd`: composição e timelines.
- `scripts/battle/Unidades.gd`: geometria fixa.
- `scripts/battle/FragmentPortrait.gd`: máscara canônica do retrato.
- `scripts/battle/FusionStream.gd`: energia em Bézier.
- `scripts/battle/ElementImpact.gd`: ataques elementais.
- `scripts/battle/DamagePopup.gd`: soma/dano visível.
- `assets/battle/ui_v6/`: molduras, carga e HUD inimigo.
