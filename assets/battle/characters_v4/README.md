# Personagens v4 — conjunto integrado

Este diretório é o conjunto visual atualmente consumido pela batalha. Todos os
arquivos são PNG RGBA de 1254×1254, com fundo realmente transparente e filtro
`nearest` no Godot.

## Party

| Elemento | Asset |
|---|---|
| Dragão/Fogo | `ally_dragon_v1.png` |
| Cavaleiro | `ally_knight_v1.png` |
| Natureza | `ally_nature_v1.png` |
| Luz | `ally_light_v1.png` |
| Trevas | `ally_dark_v1.png` |

Os cinco retratos usam a mesma máscara, zoom 1,25 e deslocamento vertical de
8 px no espaço-base da arte. Esses valores são o padrão para futuras imagens:
o rosto e o tronco devem dominar a janela sem atravessar a moldura.

## Campo inimigo

| Afinidade | Asset |
|---|---|
| Trevas / espadachim da fase | `enemy_stage_sword_v1.png` |
| Dragão/Fogo / arqueiro da fase | `enemy_stage_bow_v1.png` |
| Luz / lanceiro da fase | `enemy_stage_spear_v1.png` |
| Cavaleiro | `enemy_knight_v1.png` |
| Natureza | `enemy_nature_v1.png` |

A formação normal exibida pela beta usa os três primeiros. As formações de 2,
5 e boss continuam suportadas pelos presets e podem trocar o elenco por fase.

Os inimigos são ajustados por contenção dentro do preset da formação. A arte
nunca é esticada, e o HUD é ancorado no retângulo final do sprite.

## Regra para novos personagens

- canvas quadrado e transparente;
- personagem centralizado e com margem segura para armas, capa e partículas;
- sem fundo pintado ou preto semitransparente;
- preservar pixel art e importar sem filtragem linear;
- aliados usam recorte de retrato; inimigos usam a composição inteira.
