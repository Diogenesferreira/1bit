# Retratos aliados v3

Os cinco PNGs desta pasta são os retratos canônicos dos Selos de Fragmento:

| Afinidade | Asset de origem | Asset no jogo |
|---|---|---|
| Dragão/Fogo | `personagem_novo/red.png` | `ally_dragon_v1.png` |
| Cavaleiro | `personagem_novo/blue.png` | `ally_knight_v1.png` |
| Natureza | `personagem_novo/nature.png` | `ally_nature_v1.png` |
| Luz | `personagem_novo/light.png` | `ally_light_v1.png` |
| Trevas | `personagem_novo/dark.png` | `ally_dark_v1.png` |

Todos possuem canvas RGBA de 1254×1254 e fundo transparente. Os limites de
conteúdo e o aumento individual de escala ficam declarados em
`scripts/battle/Unidades.gd`. Isso permite calibrar um personagem sem alterar a
moldura ou os outros quatro.

O enquadramento definitivo é feito pelo componente reutilizável
`scripts/battle/FragmentPortrait.gd`. Batalha e futuro menu de personagens devem
usar esse componente para manter exatamente a mesma abertura em arco.

Para personagens futuros, exportar PNG RGBA transparente e manter margem ao
redor de chifres, orelhas, asas e efeitos. Nunca embutir cenário, xadrez de
transparência ou fundo preto no arquivo.
