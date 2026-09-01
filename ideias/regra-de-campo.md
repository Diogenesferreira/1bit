# Regra de campo — Digimon Heroes (remake)

Fonte: `BattleLogic.gd` (a lógica) + `Batalha.gd` (a tela) + `Bag.gd`/`CardData.gd`. Onde a mecânica diverge dos docs de ideia antigos, isto aqui reflete o **código real**.

---

## 1. O campo, de cima pra baixo

```
┌─────────────────────────────┐
│   Inimigo (topo)             │
├─────────────────────────────┤
│   Life Bar do time (50% H)   │
├─────────────────────────────┤
│   ATTACK ZONE (onde o trio   │
│   sobe e se funde)           │
├─────────────────────────────┤
│   Fileira 1 da mão: 5 cartas │
│   + coluna 6 = ENTRADA       │
│   Fileira 2 da mão: 5 cartas │
│   + coluna 6 = ENTRADA       │
├─────────────────────────────┤
│   BAG (86%–100% H): fileira  │
│   das 12 próximas cartas do  │
│   saco, visível              │
└─────────────────────────────┘
```

- **Mão = 2 fileiras de 5 cartas** (10 casas fixas). Cada carta mora na sua casa; ela não desliza pelo tabuleiro.
- **Coluna 6 de cada fileira = casa de ENTRADA.** É onde a carta que vem da BAG desce durante uma corrente. Fora de uma corrente ativa, as duas entradas ficam vazias.
- **BAG** é a fileira visível de **12 cartas** já sorteadas do saco, que ainda vão descer. `proximas[0]` é a próxima a sair (fica mais perto da mão); as outras 11 são planejamento — dá pra ver o que vem antes de jogar.
- **Hexágonos dos aliados** (rodapé): mostram o time, mas **não são clicáveis**. O jogador não escolhe quem ataca — a cor do trio decide isso sozinha.

---

## 2. Mão inicial (início do turno do jogador)

1. Compra **10 cartas do saco (Bag)**, uma por casa.
2. `_garantir_saida()` roda antes de mostrar qualquer coisa: nos vídeos do jogo original **nunca** existe uma mão de abertura sem trio possível. Se o sorteio entregar uma mão travada, uma única carta órfã (da cor com menos cópias) é **recolorida** para a cor mais abundante — o mínimo necessário para destravar.
3. A mão é **ordenada por cor e, dentro da cor, por valor crescente** — é assim que aparece nos prints do original, para facilitar enxergar os trios.
4. As **duas casas de ENTRADA começam vazias**.
5. A BAG é preenchida com as 12 próximas cartas do saco.

Não existe conceito de "escolher a bag" como ação separada — a BAG é só a vitrine do que vai descer. Quem entra nela é sempre a próxima carta do saco, na ordem.

---

## 3. O que acontece ao clicar em cada carta

### 3.1 Clicar numa carta livre da mão (1ª ou 2ª do trio)
- A carta **sai da casa** — a casa fica **vazia** no lugar exato dela (não fecha, não desliza nada por cima).
- Ela sobe e fica **pairando, piscando**, marcada.
- **No mesmo instante, uma carta nova desce da BAG para a casa de ENTRADA (coluna 6) da fileira dela.** Essa carta já pode ser usada para fechar o trio.
  - Se a entrada da fileira dela já estiver ocupada (pela carta que desceu por causa da 1ª marcação), a nova desce na entrada **da outra fileira** — por isso, numa corrente, as duas cartas que descem ficam **uma em cima da outra**, na mesma coluna 6.

### 3.2 Clicar de novo na carta marcada (desmarcar)
- Ela **volta para a casa original**.
- Se por causa dela uma carta tinha descido da BAG, **essa carta volta exatamente para o topo da fila da BAG** (desfaz a compra) — a BAG nunca "perde" uma carta por causa de um toque desfeito.

### 3.3 Clicar na 3ª carta da mesma cor (ou coringa) — fecha o trio
- Fecha na hora: **nenhuma carta nova desce desta vez** (só a 1ª e a 2ª marcação puxam da BAG).
- As 3 cartas sobem juntas ao centro (ATTACK ZONE), se fundem, e o valor delas **só é acumulado** no aliado daquela cor — o dano/cura não é aplicado ainda.
- Na sequência, o sistema testa **cascata** automaticamente (ver seção 4).

### 3.4 Clicar numa carta de cor diferente da corrente ativa
- **Abandona a cadeia inteira**: todas as cartas marcadas voltam pras casas delas, e qualquer carta que tinha descido da BAG por causa delas volta pro topo da fila.
- O jogo **não trava** — a carta tocada já inicia uma corrente nova, da cor dela.
- Abandono **conta como turno gasto** (ver seção 6), diferente de simplesmente marcar/desmarcar dentro da mesma cor, que é de graça.

### 3.5 Coringa
- Casa com **qualquer cor**. Numa corrente com coringa(s) + cartas coloridas, os coringas só "acompanham" — a cor do trio é a da primeira carta que não é coringa.
- Trio **só de coringas** (raro): bate no **time inteiro**, cada aliado recebendo a contribuição cheia.
- **Crítico** (×1.5 na contribuição do trio): as 3 cartas têm o **mesmo valor** (ex. 4-4-4) **ou** formam uma **sequência** (ex. 2-3-4).

### 3.6 Desfazer
- Cada toque que **não fechou trio** empilha um snapshot. "Desfazer" volta um toque por vez, até antes da corrente começar.
- Assim que um trio fecha de verdade, a pilha de desfazer **zera** — não dá mais pra voltar atrás daquele combo.

---

## 4. Cascata (o que acontece sozinho depois de cada trio)

Depois que um trio fecha, o sistema **procura automaticamente** outro trio pronto entre as cartas que sobraram na mão (sem o jogador tocar em nada):

- Escolhe sempre o trio da **cor com MENOS cartas na mão** (desentope órfãos primeiro; empate vai pela cor que sobra mais cartas / depois por ordem fixa de cor).
- Pode usar a **carta do topo da BAG** como 3ª carta se ela servir (mesma cor ou coringa) — isso puxa a fila da BAG e é preferido sobre gastar um coringa da mão.
- **Durante a cascata NÃO há reposição**: as casas ficam vazias mesmo, a corrente vai se esgotando sozinha.
- Cada elo de cascata soma **+30% de dano** ao próximo trio daquela corrente (`× (1 + 0,3 × cadeia)`), não multiplica por N como um valor solto.
- Se sobrar **no máximo 1 carta** na mão, acontece **RENOVAÇÃO**: a mão inteira (a carta que sobrou incluída) é descartada e recomprada da BAG, e a corrente pode continuar puxando trios novos.
- Quando não há mais trio nenhum e sobra mais de 1 carta: a cascata para e a corrente termina.

---

## 5. Fim da corrente: como o campo volta ao normal

Quando a cascata não acha mais nenhum trio (corrente encerrada):

1. **O que estiver esperando nas 2 casas de ENTRADA entra primeiro** nas casas vazias da mão (mais à esquerda disponível).
2. **A BAG completa o resto**: toda casa que ainda estiver vazia recebe carta nova do saco — é a "chuva final".
3. **Redistribuição**: as 10 cartas da mão são reunidas e **espalhadas de novo, agrupadas por cor e em ordem numérica crescente dentro da cor** — igual ao original, pra facilitar enxergar o próximo trio.
4. `_garantir_saida()` roda de novo em cima da mão redistribuída: se por azar ela não tiver nenhum trio possível, uma carta órfã é recolorida — a mão **sempre** volta jogável.
5. As duas casas de ENTRADA ficam **vazias** de novo, prontas pro próximo toque.

Só **depois** disso tudo o dano/cura acumulado na corrente inteira é resolvido de uma vez: soma tudo, desconta a **defesa do inimigo uma única vez** (não por combo), aplica no HP do inimigo, e a cura entra no HP do time.

---

## 6. Turno do inimigo

- O inimigo tem um contador que começa em **3**.
- **Cada corrente que fecha um combo real, OU cada abandono de cor**, desconta 1 do contador. Marcar/desmarcar sem soltar a mesma cor não gasta nada.
- Quando o contador chega a **0**: o inimigo ataca o HP do time (dano = ataque do inimigo − metade da defesa média do time + variação aleatória, nunca menos que 5), e o contador **reseta pra 3**.
- HP é **único do time** (soma dos 5 aliados), não por aliado — os medalhões mostram HP individual só visualmente.

---

## Resumo do ciclo completo

```
Mão inicial (10 cartas, ordenada, com saída garantida) + BAG com 12 visíveis
        │
        ▼
Toque 1ª/2ª carta → marca, casa fica vazia, BAG desce carta na ENTRADA
        │
        ▼
Toque 3ª carta da mesma cor → fecha trio → acumula dano/cura (não aplica ainda)
        │
        ▼
Cascata automática (sem reposição, +30%/elo, até renovação ou esgotar)
        │
        ▼
Fim da corrente → ENTRADA entra na mão → BAG faz a chuva final →
mão redistribuída por cor/valor → saída garantida de novo
        │
        ▼
Resolve dano total (− defesa do inimigo, 1x) e cura total
        │
        ▼
Contador do inimigo -1 (por combo ou abandono) → se zerar, inimigo ataca
        │
        ▼
Volta pro jogador com a mão nova
```

---

## Parâmetros ajustáveis (em `BattleLogic.gd`)

| Parâmetro | Valor atual | Significado |
|-----------|------------|-------------|
| `QTD_PROXIMAS` | 12 | Cartas visíveis no BAG |
| `contador_inimigo_max` | 3 | Quantos combos até inimigo atacar |
| `MULTIPLICADOR_CRITICO` | 1.5 | Multiplicador de crítico |
| `FRACAO_TRIO_CORINGA` | 1.0 | Fração de dano por aliado em trio só de coringas |

No Bag:
| Parâmetro | Valor atual | Significado |
|-----------|------------|-------------|
| `TAMANHO` | 100 | Cartas no saco |
| `POR_COR_ATAQUE` | 16 | Cartas por cor de ataque (5 cores × 16 = 80) |
| `QTD_CURA` | 12 | Cartas de cura no saco |
| `QTD_CORINGA` | 8 | Coringas no saco |
| `MAX_SEQUENCIA` | 3 | Máximo de cartas da mesma cor seguidas |
