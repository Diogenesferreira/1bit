# Skills — referência, adaptação e balanceamento

Status: biblioteca de inspiração e proposta de teste. Este documento **não é
regra canônica** até as cinco skills iniciais serem aprovadas e transferidas
para `REGRAS_CANONICAS_ALPHA.md`.

Origem: lista de efeitos encontrada no jogo usado como inspiração. Os nomes e
textos originais não devem ser copiados literalmente; o objetivo é estudar as
famílias mecânicas e reinterpretá-las para o BAG, as cascatas, o HP
compartilhado e os cinco elementos de **1 Bit Heroes**.

## 1. Contrato já implementado

- Cada aliado possui um medidor radial de **8 blocos**.
- Combo comum do elemento carrega `+1` bloco.
- Combo crítico carrega `+2` blocos.
- Trio somente de Wild carrega `+1` em todos os aliados vivos.
- Ao chegar a 8, o medidor pulsa e fica clicável.
- O clique atual é apenas uma prévia visual: ainda não consome carga nem aplica
  efeito.

Contrato recomendado para a implementação real:

1. usar a skill não gasta uma corrente nem reduz o contador inimigo;
2. uma ativação bem-sucedida consome os 8 blocos;
3. skills que mexem em mão ou BAG só podem ser usadas sem cartas marcadas;
4. skills ofensivas usam o inimigo atualmente selecionado;
5. toda mudança nasce em `EstadoBatalha.gd` e vira evento para a tela animar;
6. depois de alterar cartas, a garantia de saída continua obrigatória;
7. nenhum efeito pode ultrapassar HP, contador, valor `1–9` ou quantidade de
   cartas prevista pela regra.

## 2. Famílias encontradas na referência

### 2.1 Dano direto

- dano alto em um inimigo;
- dano pequeno, médio ou grande em todos;
- ataque aleatório com variação enorme;
- ataque com sacrifício de HP;
- dano baseado no total recebido;
- absorção: causar dano e curar o mesmo valor;
- ataque que deixa o próprio HP em 1;
- chance de expulsar ou eliminar instantaneamente.

Adaptação útil: dano concentrado, dano em área, absorção e contra-ataque. Dano
aleatório extremo e morte instantânea retiram decisão do jogador e não combinam
com batalhas curtas.

### 2.2 Cura e sobrevivência

- recuperação parcial, grande ou total;
- escudo percentual;
- redução de dano de um elemento específico;
- redução do ataque inimigo;
- aumento da defesa do time.

Adaptação útil: cura percentual do HP compartilhado, escudo para o próximo
ataque e enfraquecimento temporário. Cura total recorrente pode apagar o risco
da batalha.

### 2.3 Buffs de ataque, defesa e suporte

- aumento pequeno a máximo para um elemento;
- aumento global para todo o time;
- aumento de cura/suporte;
- redução do tempo necessário para outras skills.

No nosso jogo, bônus por elemento perde valor com apenas um aliado de cada
tipo. É mais interessante fortalecer uma **regra de jogada**: próximo crítico,
próxima cascata, próxima cura ou próximo ataque inimigo.

### 2.4 Debuffs e controle de turno

- reduzir ataque ou defesa dos inimigos;
- atrasar o próximo ataque;
- reduzir drasticamente estatísticas de chefes específicos.

Adaptação útil: `+1` no contador inimigo, defesa reduzida durante uma corrente
ou ataque enfraquecido por um golpe. Atraso repetível sem limite cria trava
permanente e deve ter teto.

### 2.5 Alteração de valores

- aumentar todas as cartas em `+1` ou `+2`;
- transformar todos os valores em `9`.

Essa família conversa diretamente com trincas e sequências. `+1` com limite 9
é uma ótima skill; transformar tudo em 9 fabrica críticos garantidos e é forte
demais para uma habilidade recorrente.

### 2.6 Conversão de tipos

- Cura → elemento escolhido;
- elemento escolhido → Cura;
- transformar toda a mão em um elemento ou em Wild.

Conversão limitada a duas ou três cartas pode criar decisões interessantes.
Converter a mão inteira quase sempre entrega trio e cascata gratuitamente, por
isso deve ficar restrito a evento raro, relíquia ou modo especial.

### 2.7 Troca e remontagem da mão

- substituir toda a mão;
- substituir com maior chance de um elemento;
- trocar cartas atuais por um tipo específico.

É uma das famílias mais adequadas ao projeto, desde que o jogador não consiga
descartar indefinidamente uma mão ruim. Preferir escolher até três cartas ou
usar uma troca automática única.

### 2.8 Manipulação do BAG

- aumentar incidência de elemento, Cura ou Wild;
- limitar as próximas cartas a três elementos;
- limitar às polaridades Luz/Trevas;
- selar temporariamente um elemento;
- fazer aparecer apenas ataque ou apenas Cura.

Esta é a família com maior identidade para **1 Bit Heroes**, porque transforma
a fila futura em planejamento. Os efeitos devem atuar em uma janela curta —
por exemplo, as próximas cinco compras — sem reconstruir silenciosamente o
saco inteiro.

## 3. Faixas de segurança

### Verde — apropriadas para a primeira alpha

- dano concentrado moderado;
- dano pequeno em todos;
- cura de `25–35%` do HP máximo compartilhado;
- reduzir o próximo dano inimigo em `35–50%`;
- atraso de `+1`, respeitando um contador máximo;
- aumentar valores da mão em `+1`, com teto 9;
- substituir até três cartas;
- influenciar somente as próximas cinco cartas do BAG.

### Amarela — fortes, mas testáveis com limites

- absorção de dano;
- devolver parte do dano recebido;
- converter até três cartas de tipo;
- reduzir defesa durante uma corrente;
- substituir a mão inteira uma única vez por batalha;
- aumentar temporariamente a incidência de Wild.

### Vermelha — reservar para eventos ou descartar

- KO instantâneo;
- dano aleatório com amplitude gigantesca;
- deixar o HP em 1 para causar dano máximo;
- cura total repetível;
- transformar todas as cartas em 9;
- transformar toda a mão em Wild ou num único elemento;
- gerar somente um tipo indefinidamente;
- reduzir todo dano recebido a 1;
- atrasar inimigos repetidamente sem teto.

Esses efeitos podem ser divertidos como relíquias raras, desafios de uma fase
ou recompensas temporárias. Como skills carregáveis, tendem a remover o puzzle.

## 4. Primeiro conjunto recomendado para teste

Os números são pontos iniciais, não decisões finais.

| Aliado | Skill provisória | Efeito | Por que combina |
|---|---|---|---|
| Draco de Brasa | **Impacto de Brasa** | causa dano concentrado equivalente a aproximadamente `2,5×` um combo comum no alvo | simples, agressiva e boa para finalizar ameaça |
| Guardião de Ferro | **Bastião** | reduz em `45%` o próximo dano inimigo ao HP do time | cria escolha entre atacar agora ou preparar defesa |
| Maga do Bosque | **Crescimento** | aumenta em `+1` o valor das cartas atuais, máximo 9 | interage com trincas, sequências e planejamento da mão |
| Clériga Astral | **Luz Restauradora** | recupera `30%` do HP máximo compartilhado | função clara e fácil de medir |
| Oráculo Chacal | **Eclipse** | adiciona `+1` ao contador inimigo, sem ultrapassar o teto definido | compra tempo para preparar uma cascata |

Esse conjunto cobre dano, defesa, manipulação de cartas, cura e controle de
tempo. Ele permite avaliar cinco experiências diferentes sem introduzir ainda
buffs empilháveis ou interfaces secundárias.

## 5. Alternativas por personagem

- **Dragão:** pequeno dano em todos; sacrifício controlado; bônus ao próximo
  crítico.
- **Cavaleiro:** provocar contra-ataque; converter parte do dano em carga;
  proteger somente contra o próximo elemento inimigo.
- **Natureza:** trocar até três cartas; converter duas Curas em Natureza;
  influenciar as próximas cinco compras.
- **Luz:** limpar debuff; converter até duas cartas em Cura; aumentar a próxima
  cura.
- **Trevas:** absorver HP; reduzir defesa do alvo durante uma corrente; devolver
  parte do último dano recebido.

## 6. Perguntas antes de canonizar

1. A skill pode ser ativada no meio de uma seleção `1/3` ou apenas com a mão
   livre? Recomendação: apenas com a mão livre na primeira versão.
2. A carga permanece entre batalhas? Recomendação: começar cada batalha em 0.
3. Aliado derrotado mantém carga? Recomendação: mantém, mas não pode ativar.
4. Escudo e debuff duram um ataque, uma corrente ou vários turnos?
5. Chefes podem resistir a atraso e redução de defesa?
6. A skill da Natureza afeta também as duas ENTRADAS ou somente as dez cartas
   da mão?
7. O jogador deve confirmar o clique? Recomendação: ativação direta, exceto
   skills que exigirem selecionar cartas.

## 7. Ordem de implementação sugerida

1. criar o contrato de evento `skill_usada` na regra;
2. implementar consumo de 8 blocos e bloqueios de uso;
3. começar por Dragão e Luz, que não alteram mão nem BAG;
4. adicionar Cavaleiro e Trevas com estado temporário explícito;
5. implementar Natureza por último, com testes de trio possível, ENTRADAS,
   snapshots e garantia de saída;
6. simular 30 partidas com e sem uso de skills e comparar duração, cura,
   derrotas e quantidade de ativações.

## 8. Coleção estruturada encontrada

Fonte de pesquisa:

- [índice da coleção de Digimon Heroes!](https://digimon.fandom.com/wiki/Digimon_Heroes!/Collection);
- [módulo de descrições das skills](https://digimon.fandom.com/wiki/Module:Digimon_Heroes_Data/Skills).

Licença indicada pela wiki: conteúdo comunitário sob CC BY-SA, salvo indicação
contrária. Usar como referência histórica e mecânica; não copiar nomes,
personagens, textos ou artes para o jogo.

A página visual é apenas um índice. A API do MediaWiki expõe cinco páginas
elementais com blocos `Card Infobox DH-DM`:

```text
Digimon Heroes!/Collection/Dragon
Digimon Heroes!/Collection/Knight
Digimon Heroes!/Collection/Nature
Digimon Heroes!/Collection/Dark
Digimon Heroes!/Collection/Holy
```

Cada bloco pode conter:

```text
name, card, rarity, max_lv, cost,
atk, defense, hp, support,
main_race, secondary_race, generation,
main_skill, main_skill_turns,
leader_skill, leader_skill_turns
```

Isso confirma que a função Lua encontrada anteriormente era somente uma camada
de consulta da wiki. Os dados dos personagens e cartas ficam nestas tabelas e
infoboxes.

### 8.1 Resultado da primeira varredura

Foram encontrados **987 registros de carta**, incluindo versões e raridades
repetidas do mesmo personagem:

| Coleção | Registros |
|---|---:|
| Dragon | 233 |
| Knight | 204 |
| Nature | 207 |
| Dark | 197 |
| Holy | 146 |

Raridades observadas: Common, Uncommon, Rare, Queen, King, God, God+, SP, SP+
e Legendary Rare.

Tempo das skills na referência:

| Campo | Mínimo | Média | Máximo |
|---|---:|---:|---:|
| `main_skill_turns` | 3 | 10,16 | 23 |
| `leader_skill_turns` | 3 | 9,47 | 24 |

Os números não devem ser transplantados diretamente: o “turno” do jogo de
referência não é necessariamente igual a um combo ou corrente de 1 Bit Heroes.
Ainda assim, a média próxima de 10 confirma que habilidades fortes eram
deliberadamente espaçadas. Nosso medidor de 8 blocos é mais rápido, adequado à
alpha curta, e deve ser reavaliado quando houver partidas longas.

Skills principais mais recorrentes na primeira análise incluem retorno de
dano, aceleração de skill, dano em área, absorção, `Evolution +1/+2`, atraso de
ataque e enfraquecimento. Nas skills de líder aparecem com força manipulação de
valores, absorção, Wild Boost, atrasos e filtros de elementos.

### 8.2 Como aproveitar sem copiar

- `main_skill` inspira habilidades ativas do medidor radial.
- `leader_skill` inspira passivas, relíquias, bônus de formação ou regras de
  jornada — não precisa virar uma segunda skill carregável.
- `main_skill_turns` ajuda a comparar potência relativa dentro da referência,
  não a definir diretamente nossos oito blocos.
- ataque, defesa, HP e suporte ajudam a estudar arquétipos e proporções, não a
  importar balanceamento bruto.
- versões repetidas do mesmo personagem permitem observar como raridade muda
  números e efeitos, mas nosso jogo deve priorizar novas decisões em vez de
  simples inflação estatística.

### 8.3 Próxima análise útil

1. agrupar as 987 cartas por família de skill;
2. cruzar família, elemento, raridade e tempo de ativação;
3. identificar quais efeitos eram comuns e quais eram reservados a cartas
   raras;
4. separar habilidades ativas de passivas/liderança;
5. usar as distribuições para revisar as cinco propostas originais sem copiar
   nomes ou valores.
