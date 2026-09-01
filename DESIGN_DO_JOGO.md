# 1 Bit Heroes — Documento de Design

Status: direção de produto para o primeiro protótipo completo  
Plataforma inicial: Android, tela vertical  
Motor: Godot 4.7  

## 1. Visão do jogo

**1 Bit Heroes** é um puzzle RPG de coleção e progressão PvE em que o jogador
forma um time de cinco criaturas, atravessa mapas ilustrados em estilo 1-bit e
vence batalhas criando trios de cartas, preparando cascatas e explorando
fraquezas elementais.

Frase curta:

> Monte o time, preveja o BAG e crie cascatas para derrotar criaturas em um
> mundo desenhado em 1-bit.

O jogo combina três inspirações sem tentar reproduzi-las integralmente:

- a seleção de trios, o BAG e as cascatas de Digimon Heroes/Crusader;
- a clareza, simplicidade e leitura imediata de OneBit Adventure;
- a atmosfera, sobrevivência e economia visual de 1 Bit Survivor.

## 2. Pilares

Toda funcionalidade nova deve fortalecer pelo menos um destes pilares.

### 2.1 Fácil de tocar, interessante de decidir

O controle principal é tocar em cartas e inimigos. A profundidade vem da
ordem das cartas, do alvo, da afinidade, do contador inimigo e das habilidades.

### 2.2 O BAG é a assinatura do jogo

O jogador não olha apenas a mão atual. Ele prevê cartas futuras, prepara
sequências e modifica o BAG ao longo da progressão.

### 2.3 Cinco criaturas formam o time

O time do jogador possui cinco integrantes visíveis. Elementos, habilidades e
passivas tornam a montagem do grupo uma parte central da progressão.

### 2.4 Um mundo inteiro em 1-bit

Mapas, unidades, efeitos e interface usam uma linguagem gráfica consistente:
grafite `#27272F`, tons claros, pixel art legível e contraste controlado.

### 2.5 PvE reutilizável

Campanha, torre, raids e desafios usam o mesmo sistema de batalha. Os modos
mudam objetivos e restrições, não recriam o jogo do zero.

## 3. Loop principal

```text
Preparar time
      ↓
Escolher mapa ou modo
      ↓
Explorar e encontrar batalha/evento
      ↓
Selecionar alvo e formar trios
      ↓
Executar cascata e receber contra-ataque
      ↓
Ganhar recompensa e melhorar o time/BAG
      ↓
Avançar no mapa
```

## 4. Combate

### 4.1 Estrutura mantida

- Cinco aliados.
- Entre um e cinco inimigos.
- Dez cartas na mão, em duas fileiras de cinco.
- Duas casas de entrada.
- Três cartas fecham um trio.
- Números iguais ou sequenciais causam crítico.
- Coringa combina com qualquer elemento.
- Cápsula recupera o HP compartilhado do time.
- Cascatas automáticas recebem bônus progressivo.
- O jogador escolhe o alvo principal da corrente.
- O inimigo age após um número determinado de correntes.

### 4.2 Quantidade de inimigos

Cinco inimigos são suportados, mas não serão o padrão de todo encontro.

| Encontro | Quantidade recomendada | Objetivo visual e tático |
|---|---:|---|
| Comum | 1–3 | Leitura rápida e decisões claras |
| Horda | 4–5 | Controle de grupo e priorização de alvo |
| Elite | 1–2 | Criaturas maiores e mecânicas especiais |
| Chefe | 1 | Grande presença visual e múltiplas fases |
| Raid | 1 + partes ou invocações | Combate longo e alvo variável |

### 4.3 Afinidades

Relações elementais:

```text
Dragão → Natureza → Cavaleiro → Dragão

Luz ↔ Trevas
```

Valores iniciais para teste:

- vantagem: dano `×1,5`;
- neutro: dano `×1,0`;
- resistência: dano `×0,75`.

Esses valores são parâmetros de balanceamento, não decisões definitivas.

Antes de fechar um trio, a interface deve indicar no alvo:

```text
DANO PREVISTO: 6
VANTAGEM ×1,5
```

### 4.4 Intenção inimiga

Cada inimigo vivo mostra o que pretende fazer e em quantas correntes:

- espada: ataque em um alvo ou no HP do time;
- caveira: ataque em área ou efeito perigoso;
- escudo: defesa;
- coração quebrado: bloqueio ou redução de cura;
- invocação: chama outro inimigo.

A intenção transforma a seleção de alvo numa escolha tática. O jogador pode
explorar uma fraqueza ou eliminar primeiro o inimigo prestes a agir.

### 4.5 Habilidades dos aliados

Biblioteca de efeitos, riscos de balanceamento e primeiro conjunto proposto:
[`SKILLS_REFERENCIA_E_BALANCEAMENTO.md`](SKILLS_REFERENCIA_E_BALANCEAMENTO.md).

Um trio carrega a skill do aliado correspondente ao seu elemento. O medidor
possui oito blocos: combo comum carrega um, crítico carrega dois e Wild carrega
um em todos. Quando fica cheio, o medidor pulsa e pode ser tocado para ativar a
habilidade.

Funções possíveis:

- dano concentrado;
- dano em todos os inimigos;
- cura;
- escudo;
- manipulação da mão;
- manipulação do BAG;
- alteração de afinidade;
- bônus para o próximo crítico ou cascata.

Na primeira versão, cada aliado possui uma skill e uma passiva.

## 5. Times e personagens

### 5.1 Formação

O jogador entra em batalha com cinco aliados. Inicialmente, a regra mais clara
é usar um representante de cada elemento. Isso mantém a relação direta entre
carta, elemento e atacante.

A formação flexível com elementos repetidos pode ser estudada depois que o
combate básico estiver validado. Ela não faz parte do primeiro protótipo.

### 5.2 Elenco inicial

Meta recomendada para a primeira versão jogável:

- cinco aliados iniciais, um de cada elemento;
- cinco aliados desbloqueáveis, criando duas opções por elemento;
- cada opção muda a função e não apenas os números.

Exemplo: dois aliados de Dragão podem ser, respectivamente, um atacante de
área e um especialista em críticos.

### 5.3 Novos lançamentos

O jogo poderá receber personagens, mas não dependerá de lançamentos semanais.
Uma atualização de conteúdo pode trazer:

- um novo bioma ou parte de bioma;
- um ou dois aliados;
- alguns inimigos;
- um chefe;
- relíquias e modificadores.

Novos personagens devem ampliar estratégias. Evitar substituir personagens
antigos com versões numericamente superiores.

## 6. Direção de arte

### 6.1 Paleta

- grafite principal: `#27272F`;
- tons claros levemente quebrados para áreas grandes;
- branco puro reservado para seleção, brilho, impacto e informação urgente;
- afinidades usam acentos foscos e dessaturados, nunca preenchimentos neon;
- cards mantêm moldura e número monocromáticos; a cor vive principalmente no
  glifo e aumenta de forma controlada durante a seleção;
- pixel snapping, filtro nearest e posições inteiras.

### 6.2 Hierarquia dos inimigos

**Comuns:** uma silhueta forte, poucos detalhes e uma ideia visual principal.

**Elites:** maiores, mais acessórios e efeitos, sem atingir a complexidade de
um chefe.

**Chefes e raids:** artes espalhafatosas, assimétricas e muito detalhadas. Eles
podem ultrapassar discretamente a área normal e aparecer atrás de molduras.

Se todo inimigo for extremamente detalhado, nenhum parecerá especial e grupos
de quatro ou cinco ficarão visualmente confusos.

### 6.3 Aliados

Os aliados podem ter detalhe intermediário ou alto, pois são colecionáveis e
precisam gerar apego. Ainda assim, devem manter:

- silhueta reconhecível;

Durante a batalha, os cinco aliados são apresentados em **Selos de Fragmento**
fixos na base da arena. O selo usa um retrato legível, moldura quadrada com
cantos discretamente recortados, marcador elemental e oito segmentos de skill.
O corpo inteiro aparece de forma temporária quando o aliado se manifesta para
atacar ou ativar sua habilidade. Inimigos, por outro lado, permanecem fisicamente
no cenário. Essa diferença faz parte da linguagem visual e da ficção do jogo.
- rosto legível;
- proporções consistentes;
- área limpa para o ícone elemental;
- leitura boa quando os cinco aparecem juntos.

### 6.4 Cenário e contraste

O cenário deve ter menos contraste e densidade de detalhes que personagens e
componentes interativos. A arte do chão pode ser rica, mas deve deixar áreas de
respiro ao redor das unidades.

## 7. Mapas em imagem

### 7.1 Decisão

Os mapas serão criados como imagens completas e padronizadas. Cada imagem pode
ter caminhos, paredes, construções, vegetação e identidade própria, mesmo
dentro do mesmo bioma.

O mapa em imagem é a base visual. Sistemas do Godot ficam por cima:

```text
Imagem completa do mapa
├── regiões caminháveis invisíveis
├── bloqueios e colisões invisíveis
├── pontos de evento
├── inimigos e NPCs
├── personagem do jogador
├── efeitos ambientais
└── interface
```

Isso permite produzir mapas muito diferentes sem montar manualmente cada
parede no motor e mantém o estilo 1-bit sob controle artístico.

### 7.2 Padrão técnico

Cada mapa deve compartilhar:

- o mesmo tamanho e proporção base;
- áreas seguras para a interface;
- escala de pixels consistente;
- posição conhecida para entrada e saída;
- máscara ou polígono separado indicando onde se pode andar;
- pontos de interesse definidos em dados, não pintados como botões na imagem.

Não colocar personagens, recompensas, números, botões ou UI dentro da imagem.

### 7.3 Variações de um bioma

Um bioma pode ter várias imagens completas:

- entrada;
- caminho comum;
- bifurcação;
- ruína ou evento;
- área de elite;
- arena do chefe.

Elas reutilizam paleta e vocabulário visual, mas não precisam reutilizar o
mesmo desenho.

### 7.4 Cenário de batalha

A batalha também pode usar uma imagem pronta por ambiente. O cenário fica
atrás das unidades e a interface permanece independente. Uma imagem de mapa
pode fornecer uma versão recortada ou uma arena relacionada visualmente para
a transição parecer contínua.

## 8. Biomas e campanha

Cada bioma possui:

- identidade visual;
- dois elementos predominantes;
- um conjunto próprio de inimigos;
- uma regra ambiental;
- encontros comuns, elite e chefe;
- recompensas relacionadas ao tema.

Antes de entrar, o jogo informa elementos frequentes e recomendações. Afinidade
facilita a passagem, mas não bloqueia completamente times favoritos.

Estrutura inicial de um capítulo:

```text
Mapa 1 — introdução ao bioma
Mapa 2 — primeira variação e evento
Mapa 3 — bifurcação e recompensa
Mapa 4 — elite
Mapa 5 — preparação
Mapa 6 — chefe
```

## 9. Progressão

### 9.1 Campanha

Vencer mapas libera novos mapas e biomas. O mapa mostra caminhos, encontros,
eventos e recompensas encontradas.

### 9.2 Conta

Permanece entre todas as partidas:

- personagens;
- níveis e evoluções;
- skills e passivas;
- relíquias descobertas;
- recursos;
- formações salvas;
- progresso de campanha.

### 9.3 Jornada ou modo

Pode ser temporária até sair do mapa, terminar a torre ou concluir a raid:

- melhorias no BAG;
- relíquias temporárias;
- bônus e maldições;
- recuperação de HP;
- escolhas de rota.

O crescimento deve trazer novas decisões antes de trazer apenas números
maiores.

## 10. Modos PvE

### 10.1 Campanha

Modo principal. Ensina sistemas, apresenta biomas, libera aliados e conta a
progressão do mundo.

### 10.2 Torre

Sequência de batalhas com HP persistente, recompensas acumuladas e dificuldade
crescente. Pode ter uma semente diária ou semanal no futuro.

### 10.3 Raid

Chefe grande, várias fases, partes selecionáveis, mudanças de afinidade e
limite de correntes ou tentativas. A primeira raid pode ser individual; não é
necessário implementar multijogador para validar o formato.

### 10.4 Eventos e desafios

Reutilizam conteúdo existente com regras diferentes, como:

- somente determinados elementos;
- cura reduzida;
- BAG inicial fixo;
- inimigos mais rápidos;
- objetivo de maior cascata ou pontuação.

## 11. Interface de batalha

Mockup de direção visual: [`novos modelos refeitos/mockup_ui_batalha_limpa_v1.png`](novos%20modelos%20refeitos/mockup_ui_batalha_limpa_v1.png).

O mockup demonstra hierarquia e distribuição dos elementos. Ele não é um asset
final para aplicação direta no jogo; dimensões, ícones e textos serão recriados
com os componentes nativos do projeto.

Sequência revisada, já sem Fusion Lane e com cenário escuro:

1. [`Mão inicial`](novos%20modelos%20refeitos/conceito_batalha_final/01_mao_inicial.png)
2. [`Três cartas se fundindo dentro da mão`](novos%20modelos%20refeitos/conceito_batalha_final/02_cartas_se_fundindo.png)
3. [`Energia chegando e acumulando no aliado`](novos%20modelos%20refeitos/conceito_batalha_final/03_energia_no_aliado.png)
4. [`Estudo de contraste com clareiras naturais`](novos%20modelos%20refeitos/conceito_batalha_final/04_contraste_com_clareiras.png)

A animação usa uma camada temporária sobre a própria mão. As cartas não entram
na arena; somente a energia resultante atravessa a interface e chega ao aliado.

No estudo de contraste, as bordas do cenário permanecem escuras e detalhadas,
enquanto as formações ocupam zonas naturais de tom médio e menor densidade. Um
contorno off-white fino separa as unidades sem exigir variantes dos assets.

### 11.1 Hierarquia

Ordem de atenção desejada:

1. alvo e intenção inimiga;
2. cartas da mão;
3. cartas selecionadas e resultado previsto;
4. próximas cartas;
5. skills e HP do time.

### 11.2 Permanecer visível

- inimigos, HP e intenções;
- cinco Selos de Fragmento com retratos e medidores de oito segmentos;
- mão;
- área temporária de fusão sobre a própria mão;
- fila de próximas cartas;
- HP compartilhado;
- contador do próximo ataque;
- menu.

### 11.3 Remover ou tornar contextual

- score durante a batalha;
- moedas e gemas durante a batalha;
- indicador de rodada que ainda não possui função;
- diagrama completo de afinidades;
- molduras puramente decorativas que competem com áreas tocáveis.

### 11.4 Feedback de jogada

Ao iniciar um trio, mostrar:

- aliado que atacará;
- alvo atual;
- vantagem ou resistência;
- dano aproximado;
- progresso `1/3`, `2/3` e fechamento;
- mudança provocada no contador inimigo.

### 11.5 Linguagem elemental implementada

- Cards: glifo em vermelho queimado, azul-aço, verde-musgo, amarelo
  envelhecido ou roxo acinzentado; Cura é marrom e Wild reúne as cinco cores.
- Unidades: o tipo é mostrado por um quadrado pequeno de cor fosca, sem glifo,
  sempre no mesmo canto relativo ao sprite.
- Inimigos: HUD proporcional com marcador, `X TURN` e life vermelho.
- Aliados: oito blocos em arco ao redor do marcador. Combo comum carrega um;
  crítico carrega dois; Wild carrega um em todos.
- A cor deve orientar, não dominar: sem aura permanente e sem brilho suave
  grande em repouso.

## 12. Monetização planejada

A monetização só será ativada depois de o loop principal demonstrar retenção e
vontade de repetir batalhas.

### 12.1 Anúncios recompensados

Possíveis usos:

- reviver uma vez;
- trocar opções de recompensa;
- ganhar um baú adicional;
- duplicar uma recompensa comum;
- recuperar uma tentativa de raid.

Nunca interromper uma batalha ou colocar anúncio antes de uma fase começar.

### 12.2 Compras

- remoção de anúncios;
- pacote de apoiador;
- skins e paletas;
- cosméticos de perfil e interface;
- pacotes diretos e transparentes de personagens;
- passe de evento somente quando houver conteúdo suficiente.

Caixas aleatórias pagas não fazem parte da primeira versão.

## 13. Escopo da primeira versão completa

O primeiro objetivo não é lançar todos os modos. É produzir uma fatia vertical
que mostre como o jogo final se comportará.

Conteúdo mínimo:

- uma UI de batalha clara;
- afinidades funcionando;
- intenção dos inimigos;
- cinco skills básicas;
- um mapa ilustrado navegável;
- três encontros comuns;
- um elite;
- um chefe;
- cinco aliados;
- tela simples de formação;
- recompensa e salvamento de progresso.

## 14. Ordem de produção

### Etapa 1 — Validar o combate

1. Simplificar a UI atual.
2. Juntar BAG e NEXT numa leitura única.
3. Implementar vantagem e resistência elemental.
4. Mostrar dano previsto no alvo.
5. Mostrar intenção e contador por inimigo.
6. Criar uma skill para cada aliado.
7. Testar repetidamente no celular.

Critério de aprovação: o jogador deve olhar o campo e decidir tanto **qual
trio fazer** quanto **qual inimigo precisa cair primeiro**.

### Etapa 2 — Criar a primeira fatia de mundo

1. Definir o primeiro bioma.
2. Criar uma imagem de mapa completa.
3. Colocar caminhada, limites e pontos de interação sobre a imagem.
4. Fazer a transição mapa → batalha → resultado → mapa.
5. Criar três encontros, um elite e um chefe.

### Etapa 3 — Progressão

1. Tela de formação.
2. Segundo aliado de cada elemento.
3. Recompensas.
4. Melhorias e desbloqueios.
5. Salvamento.

### Etapa 4 — Repetição e modos

1. Torre usando inimigos existentes.
2. Primeira raid individual.
3. Desafios diários ou semanais.
4. Eventos com modificadores.

### Etapa 5 — Monetização e publicação

1. Medir duração, derrotas, escolhas e repetição.
2. Implementar anúncios recompensados.
3. Implementar remoção de anúncios e cosméticos.
4. Preparar loja, privacidade, consentimento e publicação.

## 15. O que não fazer agora

- PvP.
- Multiplayer de raid.
- Dezenas de personagens sem skills distintas.
- Loja ou anúncios antes de validar o combate.
- Evoluções complexas.
- Eventos sazonais dependentes de servidor.
- Vários biomas antes de terminar um mapa completo.
- Refazer novamente todas as artes antes de testar a nova hierarquia da UI.

## 16. Próxima tarefa recomendada

A reorganização visual principal está concluída: lineup v2, HUD inimigo,
Selos de Fragmento fixos, cards elementais, fusão na mão e energia até o aliado
já estão na tela jogável. Os aliados não ocupam mais permanentemente o campo;
o próximo passo visual é a manifestação temporária durante seus ataques.

Próxima sequência recomendada:

1. definir e implementar as cinco skills, incluindo consumo dos oito blocos;
2. implementar vantagem/resistência e previsão de dano no alvo;
3. criar alerta discreto quando um inimigo chegar a `1 TURN`;
4. testar toque, legibilidade e duração em celulares pequenos;
5. somente depois começar mapa, recompensa e progressão.

Não acrescentar novos painéis permanentes antes desses testes. Informações de
vantagem e dano previsto devem ser contextuais à seleção para preservar o
espaço negativo conquistado na arena.
