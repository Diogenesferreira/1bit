# Selos de Fragmento Elementais v6 — versão preservada

> A batalha atual usa o pacote canônico `assets/battle/ui_v9/`. Esta versão
> permanece no projeto apenas como histórico e fonte de compatibilidade.

Esta é a implementação oficial dos retratos aliados na batalha. Os assets vieram
do pacote `Selos de Fragmento Elementais/export_godot` e preservam sua geometria,
pixel art e transparência sem redesenho.

As molduras e folhas de carga foram sincronizadas novamente em 30/08/2026 após
o ajuste final do pacote externo. Não restaurar cópias anteriores desses PNGs.

## Cinco afinidades

| Elemento | Cor | Moldura vazia | Folha de carga |
|---|---|---|---|
| Dragão/Fogo | vermelho fosco | `frames/fragment_seal_dragon_empty_v1.png` | `charge_sheets/fragment_seal_dragon_charge_sheet_v1.png` |
| Cavaleiro | azul aço | `frames/fragment_seal_knight_empty_v1.png` | `charge_sheets/fragment_seal_knight_charge_sheet_v1.png` |
| Natureza | verde musgo | `frames/fragment_seal_nature_empty_v1.png` | `charge_sheets/fragment_seal_nature_charge_sheet_v1.png` |
| Luz | amarelo/dourado | `frames/fragment_seal_light_empty_v1.png` | `charge_sheets/fragment_seal_light_charge_sheet_v1.png` |
| Trevas | roxo | `frames/fragment_seal_dark_empty_v1.png` | `charge_sheets/fragment_seal_dark_charge_sheet_v1.png` |

`Wild` e `Cura/Cápsula` continuam sendo apenas mecânicas de carta.

## Geometria e carga

- Molduras: canvas RGBA transparente de 330×330.
- Abertura útil: polígono em arco dentro do canvas 330×330, definido uma única
  vez em `scripts/battle/FragmentPortrait.gd`.
- Apoio visual dos pés: aproximadamente `y = 276`, centro `x = 165`.
- Folhas de carga: 330×2970, com nove quadros verticais de 330×330.
- Quadro 0 é 0/8; quadro 8 é 8/8.
- O Godot seleciona o quadro com `AtlasTexture`, sem cortar PNGs em runtime.

## Contrato obrigatório do personagem

- A arte deve ser PNG RGBA com fundo realmente transparente.
- Não exportar fundo preto, branco, xadrez ou cenário junto do personagem.
- Cabeça, chifres, orelhas e elmo devem permanecer na área segura superior.
- Corpo pode ultrapassar a janela: o jogo usa escala `cover` e corta o excesso.
- Os pés devem terminar próximos ao apoio inferior para parecerem assentados na
  moldura, e não uma miniatura flutuando.
- Personagens futuros podem usar `retrato`, `retrato_recorte`, `retrato_zoom` e
  `retrato_offset`; a geometria da moldura nunca muda por personagem.

O fundo carvão e o retrato usam o mesmo polígono da abertura. Não usar
`ColorRect` ou recorte retangular aqui: eles aparecem nos cantos transparentes
do arco e fazem o fundo preto vazar para fora da moldura.

Os cinco aliados agora usam os PNGs individuais transparentes em
`assets/battle/characters_v3/`. O jogo aplica um recorte de conteúdo por
personagem antes da escala `cover`; assim a margem vazia do canvas 1254×1254
não reduz o personagem dentro do selo.

## Ordem de camadas na cena

1. fundo carvão dentro da janela;
2. retrato transparente, recortado pela janela;
3. moldura vazia do elemento;
4. quadro de carga correspondente a 0/8–8/8;
5. brilho pulsante e área clicável quando a skill chega a 8/8.

O código consumidor está em `scripts/battle/AllyUnit.gd`,
`scripts/battle/SkillGauge.gd` e `scripts/battle/Arte.gd`.

As instruções e o componente de referência originais foram preservados em
`reference/`, apenas para consulta.

## HUD inimigo v6

O mesmo pacote define o life e o turno dos inimigos em `enemy/`:

- canvas compartilhado de 384×144;
- socket quadrado já colorido para uma das cinco afinidades;
- número de turno vindo de uma folha 0–9 com células de 42×48;
- rótulo `TURN` raster, sem fonte do sistema;
- life vermelho com área útil de 360 px, revelado por recorte horizontal;
- drenagem de dano em 420 ms com curva cúbica ease-out;
- pulso em HP crítico, abaixo ou igual a 25%;
- HUD escurecido quando o inimigo chega a zero.

A batalha aceita visualmente turnos de 0 a 5. A geometria é escalada como uma
unidade conforme o tamanho do inimigo, preservando as proporções do pacote. Na
formação atual sua largura fica entre 155 e 230 px do canvas lógico, para não
competir visualmente com as criaturas.

## Integração no primeiro beta

Os selos medem 190×190, com 20 px de intervalo, e ficam sobre uma faixa carvão
plana na base da arena. Apenas a divisória superior delimita a interface, sem
uma segunda moldura fechada em volta dos personagens. Essa faixa é interface,
não parte do background. Fusão, fluxo de energia e popup
de dano e cinco impactos elementais seguem `reference/README_VFX_ORIGINAL.md`.
O mapa completo das zonas está em
`novos modelos refeitos/conceito_batalha_final/UI_BETA_FINAL_MAPA.md`.
