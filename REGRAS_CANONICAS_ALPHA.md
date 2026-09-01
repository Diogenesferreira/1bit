# Regras canônicas — Alpha jogável

Este documento é a fonte de verdade da batalha da versão alpha. Os documentos em `heroes/docideias` continuam como pesquisa e histórico, mas não devem ser usados isoladamente para alterar o código.

## Hierarquia das decisões

1. Decisões explícitas do projeto têm prioridade: cinco aliados, até cinco inimigos, HP compartilhado e escolha manual do alvo.
2. Descobertas marcadas como confirmadas em `mecanica-do-binario.md` corrigem hipóteses dos documentos antigos.
3. `regra-de-campo.md` define o fluxo do campo quando não contradiz uma descoberta posterior.
4. Números que não puderam ser recuperados do servidor original são balanceamento da alpha e aparecem abaixo como **estimativa**.

## Campo e BAG

- A mão possui 10 cartas: duas fileiras de cinco.
- Existe uma sexta casa de ENTRADA em cada fileira. Elas começam vazias.
- A regra mantém 12 cartas futuras conhecidas. A caixa fixa `NEXT`, no extremo direito, exibe a primeira; a faixa `PRÓXIMAS` exibe as cinco seguintes.
- A primeira carta da fila é sempre a próxima a descer. Visualmente, ela sai da caixa `NEXT` à direita e entra no campo por esse mesmo lado.
- O saco possui 100 cartas: 16 de cada uma das cinco afinidades, 12 de cura e 8 Wild.
- Valores vão de 1 a 9 e não pode haver mais de três cartas consecutivas do mesmo tipo no saco.
- A mão entregue ao jogador é agrupada por afinidade, ordenada por valor e sempre tem uma saída possível.

## Seleção manual

- A primeira e a segunda cartas escolhidas levantam na própria mão, recebem contorno luminoso e puxam uma carta da BAG para uma ENTRADA.
- Tocar novamente em uma carta levantada a devolve e restaura exatamente a carta que havia descido.
- Tocar uma afinidade incompatível abandona a corrente atual, restaura suas cartas e inicia outra corrente. Abandono gasta um turno.
- A terceira carta compatível fecha o trio imediatamente e não puxa outra carta.
- Wild combina com qualquer afinidade. A primeira carta não-Wild determina a afinidade do trio.

## Fusão e carga

- Não existe Fusion Lane permanente.
- Ao fechar o trio, cópias visuais das cartas convergem dentro da área da mão, se sobrepõem e colapsam em um núcleo de energia.
- A energia percorre um rastro curvo até o aliado da afinidade correspondente.
- Cada contribuição aparece como carga acumulada no aliado.
- A skill possui oito blocos persistentes. Combo comum acende `+1`; combo
  crítico acende `+2`; trio somente de Wild acende `+1` em todos os aliados
  vivos. Dano e carga de skill são valores independentes.
- Ao completar oito blocos, o medidor pulsa e aceita toque. Enquanto os cinco
  efeitos de skill não forem definidos, o toque apenas confirma a interação e
  não consome a carga.
- O aliado não causa dano naquele momento: todo dano e toda cura são resolvidos somente ao terminar a corrente completa.
- Trio composto apenas por Wild carrega todos os aliados disponíveis; todos contribuem contra o alvo atual.

## Cascata automática

- Depois do primeiro trio, o sistema procura outros trios nas cartas restantes e pode usar a primeira carta da BAG.
- Não há reposição durante a cascata. As casas ficam vazias até a corrente terminar.
- A carta da BAG é preferida em empate para preservar recursos da mão.
- Afinidades cujo aliado esteja morto ou indisponível são ignoradas.
- A prioridade confirmada pelo binário usa três passadas:
  1. quantidades 2, 5 e 8 (`quantidade % 3 == 2`);
  2. quantidades 4 e 7 (`quantidade % 3 == 1`);
  3. quantidades 3, 6 e 9 (`quantidade % 3 == 0`).
- Dentro da mesma passada vence a combinação com maior nota de crítico.
- Cada elo recebe `+30%` sobre a contribuição base daquele trio.
- Se restar no máximo uma carta, ocorre RENOVAÇÃO e a cascata pode continuar.

## Crítico e Wild

- Wild substitui valores ausentes, mas não concede crítico gratuitamente.
- Três valores iguais geram nota `valor × 10`.
- Uma sequência de três valores gera nota `maior valor × 3` na alpha.
- Qualquer nota maior que zero ativa o multiplicador crítico de `1,5×`.
- A nota também desempata a seleção automática dos trios.

## Final da corrente

1. Cartas das ENTRADAS ocupam primeiro os espaços livres da mão.
2. A BAG completa as casas restantes.
3. A mão é redistribuída por afinidade e valor.
4. A garantia de saída corrige uma carta órfã somente se necessário.
5. As contribuições são somadas por alvo.
6. A defesa do inimigo é aplicada uma única vez, percentualmente.
7. O dano aparece no inimigo e somente o contador visual temporário da corrente
   é limpo. A carga de skill permanece entre correntes, limitada a oito blocos.

## Combate da alpha

Os dados individuais de ataque e defesa são parte do modelo definitivo. A fórmula numérica, porém, é uma **estimativa de balanceamento**, pois as tabelas originais vinham de um servidor desativado.

```text
contribuição = max(1, (ataque do aliado + média das cartas) × 0,18)
contribuição *= 1 + 0,30 × índice da cascata
se crítico: contribuição *= 1,5

redução de defesa = defesa / (defesa + 60)
dano final = max(1, soma das contribuições × (1 − redução))
```

- A redução é percentual e tem retorno decrescente; defesa nunca é subtraída diretamente do dano.
- O HP do time é único e começa como a soma do HP máximo dos cinco aliados.
- O contador inimigo começa em 3. Uma corrente com combo ou um abandono reduz o contador uma vez.
- Ao chegar a zero, o primeiro inimigo vivo ataca e o contador volta a 3.
- Dano inimigo da alpha: `max(5, ataque − metade da defesa média do time + variação de -1 a +1)`.

## Alvo e afinidades

- O jogador escolhe um inimigo vivo; toda a corrente permanece nesse alvo.
- Se o alvo morrer, o próximo inimigo vivo é selecionado automaticamente.
- Existem exatamente cinco elementos de personagem: Dragão/Fogo (vermelho),
  Cavaleiro (azul), Natureza (verde), Luz (amarelo) e Trevas (roxo).
- Wild e Cura/Cápsula são mecânicas exclusivas das cartas. Não representam
  afinidades de personagem e não recebem unidade ou Selo de Fragmento.
- Vantagens elementais ainda não entram nesta alpha. O sistema futuro será Dragão → Natureza → Cavaleiro → Dragão e Luz ↔ Trevas.

## Contrato visual da alpha

- Paleta: grafite `#27272F`, cinzas intermediários e branco suave.
- Cartas altas com moldura dupla, placa de valor no canto e glifo central em
  cor elemental fosca. Moldura, número e fundo permanecem majoritariamente
  monocromáticos.
- Dragão usa vermelho queimado; Cavaleiro, azul-aço; Natureza, verde-musgo;
  Luz, amarelo envelhecido; Trevas, roxo acinzentado; Cura, marrom.
- A Wild reúne as cinco cores no glifo sem usar arco-íris neon.
- Seleção: elevação, borda mais grossa, halo fosco da afinidade e pixels
  pulsantes. Branco puro fica reservado para impacto e informação urgente.
- Fusão: três cartas sobrepostas, núcleo claro/escuro e explosão de pixels.
- Energia: caminho curvo com linha e partículas quadradas na cor fosca do trio.
- Carga: `+N` junto ao aliado até o ataque final.
- O tipo de aliados e inimigos é um pequeno quadrado preenchido pela cor da
  afinidade, sem glifo interno. Ele mantém borda 1-bit e não deve parecer LED.
- Inimigo: corpo inteiro no cenário e HUD proporcional acima do sprite, com
  marcador de tipo, `X TURN` e barra de life vermelha.
- Aliado: cinco **Selos de Fragmento** ocupam posições fixas na base da arena.
  Cada selo reúne moldura, retrato, quadrado elemental fosco e arco de oito
  blocos. O aliado não permanece de corpo inteiro no campo; sua manifestação
  completa será temporária durante ataque ou skill. O HP do time permanece
  universal no rodapé.
- A arena usa periferia escura e clareiras de cinza médio para preservar os contornos dos personagens.

## Fora do escopo desta alpha

- Skills ativas, buffs e debuffs.
- Vantagem elemental aplicada ao dano.
- Evolução, equipamentos e raridades.
- Fórmula definitiva recuperada do jogo original.
- Balanceamento de torres, raids e chefes.
