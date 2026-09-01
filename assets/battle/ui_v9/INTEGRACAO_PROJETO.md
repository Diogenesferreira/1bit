# UI de batalha v9 — integração no projeto

Estado: **implementada e validada em 31/08/2026**.

## Fontes canônicas

A implementação segue esta ordem de autoridade:

1. `reference/tela_completa.png` — composição visual;
2. `spec/layout_batalha.json` — medidas exatas;
3. `spec/LAYOUT_BATALHA.md` — regras e intenção;
4. `README_GODOT.md` — configuração do motor.

O viewport lógico é 940×1685. A captura em celular de teste é 558×1000, com
`canvas_items`, `expand` e coordenadas inteiras.

## Estrutura implementada

| Região | Y | Altura |
|---|---:|---:|
| Header | 25 | 64 |
| Stage | 103 | 560 |
| Party | 711 | 222 |
| Bag | 947 | 160 |
| Hand | 1153 | 446 |
| Footer | 1615 | 41 |

- Party: cinco selos fixos de 165×165 e personagens de `characters_v4`.
- Bag: oito cartas compactas de 78×108 mais `NEXT`.
- Hand: dez casas em grade 5×2, cartas de 156×216.
- Inimigos: formações de 1 a 5, HUD proporcional e afinidade por cor.
- Footer: vida global do time, sem competir com a área das cartas.

## Comportamentos preservados

- seleção de trio e cascata;
- alinhamento e convergência das cartas no centro da HAND;
- clarão, anel e partículas em Bézier até o selo correto;
- oito encaixes de carga e halo clicável em 8/8;
- impacto elemental, dano, cura e mudança de turnos;
- balão de soma dos aliados separado do HUD inimigo.

As duas ENTRADAS continuam existindo apenas no estado da regra. Elas nunca são
desenhadas como sexta coluna: a compra anima até a carta que a puxou, é guardada
fora da cena e só reaparece quando entra numa das dez casas reais da HAND.

## Evidência visual e funcional

- `novos modelos refeitos/alpha_jogavel/15_ui_final_v9.png` — cena completa;
- `08_medidores_skill_cheios_clicaveis_v1.png` — cinco skills em 8/8;
- `12a` a `12e` — sequência de fusão, energia e impacto;
- `tests/test_batalha.gd` — regra e tela sincronizadas, sem erro de execução.

## Próxima etapa visual

O bloco de interface está pronto para receber os backgrounds animados por
sprites. Essa etapa deve alterar somente o conteúdo interno do `Stage`; header,
Party, Bag, Hand e Footer permanecem fixos.
