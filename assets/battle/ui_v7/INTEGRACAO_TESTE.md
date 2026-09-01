# UI de batalha v7 — experimento rejeitado

> Substituído pela implementação canônica em `assets/battle/ui_v9/`.

> Rejeitada visualmente em 31/08/2026. Nenhum arquivo desta pasta é carregado
> pela batalha. A interface voltou à base `ui_v6`, mantendo apenas as animações
> e correções funcionais já aprovadas. Conservar este pacote somente como
> referência de peças isoladas; não restaurar sua geometria completa.

Esta pasta contém a cópia integral do pacote
`Selos de Fragmento Elementais 2/export_godot`, integrada à batalha para
avaliação visual. A versão anterior permanece preservada em `ui_v6`.

## O que entrou no teste

- cinco retratos `char_*_battle_v1.png` dentro dos selos de 165×165;
- faces raster `card_face_*_v1.png` em 78×108 na BAG e 156×216 na mão;
- oito cartas visíveis na BAG, com sua última carta repetida em `NEXT`;
- réguas `PARTY`, `BAG`, `NEXT` e `HAND` do pacote;
- nova paleta de painéis `#080908`, `#0d0e0c`, `#101210` e `#121311`;
- energia/contador no cabeçalho e HP no rodapé.

## O que foi preservado

- regra de 10 cartas mais duas entradas tracejadas;
- seleção e elevação das cartas;
- alinhamento e convergência das três cartas no centro da mão;
- clarão, anel, 48 partículas em Bézier e rastros;
- carga dos oito segmentos, halo de skill pronta e clique;
- balão de dano acumulado no aliado;
- cinco impactos elementais e dreno do HP inimigo.

## Geometria do teste

| região | coordenadas no canvas 1152×2048 |
|---|---|
| palco + formação | `x 28, y 100, 1096×1010` |
| formação | selos 165×165, gap 8, `y local 829` |
| BAG | `x 42, y 1150, 1068×154` |
| mão | cartas em `y 1382` e `y 1612` |
| fusão | centro `(576, 1536)` |
| rodapé | início em `y 1900` |

Não promover esta geometria a padrão definitivo antes da aprovação visual.
