# UI de batalha v10 — integração canônica

Fonte visual: `reference/tela_completa.png`. Medidas: `spec/layout_batalha.json`.
Quando houver divergência entre uma implementação antiga e este pacote, vale o
conteúdo de `spec/`.

## Contrato da tela

- viewport lógico de 940×1685, `canvas_items`, `expand` e filtro Nearest;
- oito seções fixas nas coordenadas de `spec/LAYOUT_BATALHA.md`;
- cinco selos de 165×165;
- BAG com oito cartas de 78×108 e uma carta NEXT do mesmo tamanho;
- HAND em grade 2×6: cinco cartas iniciais por fileira e o sexto slot vago;
- os 12 slots usam 138×191, gap de 10 px e berço pontilhado permanente;
- cartas, selos, placas, números e rótulos usam os PNGs deste pacote.

## Reposição visual da mão

Na primeira e na segunda seleção, a carta de NEXT percorre, em 180 ms com
cubic-out, o caminho até o sexto slot de uma fileira. A última carta visível à
direita da BAG é sempre a mesma exibida em NEXT. Depois do pouso, a BAG desliza
da esquerda para a direita e NEXT mostra a próxima carta real.

## Limite conhecido do pacote

O export não fornece o backdrop definitivo de 888×558. Até essa arte chegar, o
projeto conserva o cenário provisório dentro do Stage; isso não altera nenhuma
geometria da interface.

## Evidências locais

- `novos modelos refeitos/alpha_jogavel/17_ui_final_v10.png` — tela completa;
- `novos modelos refeitos/alpha_jogavel/18_ui_v10_duas_entradas.png`
  — duas cartas selecionadas e as duas casas de ENTRADA alimentadas por NEXT;
- `tests/test_ui_next_refill.gd` — contrato visual da HAND/NEXT;
- `tests/test_batalha.gd` — simulação integral da regra e sincronização da tela.
