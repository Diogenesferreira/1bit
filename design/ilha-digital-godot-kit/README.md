# Ilha Digital — kit de UI para Godot

Tudo o que existe na tela de batalha **Terminal** do canvas, separado para recriar do zero no Godot 4.
Nada aqui depende do projeto antigo. Regras de batalha e animações ficam para uma etapa futura.

- Resolução de referência: **1024 × 1600** (2× do mockup 512 × 800). Todas as medidas dos docs e dos JSON estão nessa escala.
- Cada textura foi recortada do render real da tela (mesmo HTML/CSS do canvas), com fundo transparente.
- Onde uma peça tem texto, existe a versão `_ref` (com texto, para conferir) e a versão sem texto (caixa), para 9-slice.

## Estrutura

```
assets/
  background/   cenários 1024x1600, recortes do visor 976x736, película (scanline, vinheta), máscara do visor   (7)
  hud/          header, faixa de instrumentos, visor, anel de chão + chips, pop-up do alvo, HP da equipe, banco, avisos (81)
  cards/        7 cartas em 1x/2x/4x + moldura de selecionada, selo de índice, placa de valor                   (26)
  characters/   5 aliados (PNG 256, pé em 128,248)                                                                 (5)
  enemies/      2 inimigos (256) + chefe (512, pé em 256,504)                                                       (3)
  icons/        emblemas dos elementos, selos, moedas, navegação, menu e coroa (SVG + PNG 48/96)                   (62)
  buttons/      botões de navegação (normal/principal) e botão de líder (normal/ativo/recarga)                     (12)
fonts/          Instrument Sans e Martian Mono (variáveis, OFL)
data/           layout medido por estado, tipografia, paleta, posições do palco, cartas, personagens, componentes
reference/      a tela inteira em cada estado, overlay com os retângulos das peças e
                sequences/ — cada interação quadro a quadro (cartas, líder, skill, ataque, HP, abatido, pop-up, avisos)
source/         SVG-fonte das cartas
docs/           guia completo
```

## Leia nesta ordem
1. `docs/01_visao_geral.md` — anatomia da tela, camadas e estados
2. `docs/02_layout.md` — posição e tamanho de cada bloco
3. `docs/03_tema.md` — cores, tipografia, espessuras, efeitos
4. `docs/04_componentes.md` — cada componente, estados e texturas
5. `docs/05_palco.md` — cenário, personagens, anel de chão, mira e pop-up
6. `docs/06_godot.md` — como importar e montar no Godot 4
7. `docs/07_interacoes_e_animacoes.md` — o que cada toque faz, estados, tempos, curvas e as referências quadro a quadro
