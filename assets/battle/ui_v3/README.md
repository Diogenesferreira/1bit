# Selos de Fragmento v3 — estudo descartado

> Estes frames vazios foram uma tentativa de reconstrução e não são mais
> consumidos pela batalha. O padrão canônico está em `assets/battle/ui_v9/`.

Esta pasta contém as cinco e únicas molduras elementais de personagem:

| Elemento | Cor | Asset |
|---|---|---|
| Dragão/Fogo | vermelho fosco | `fragment_seal_dragon_v1.png` |
| Cavaleiro | azul aço | `fragment_seal_knight_v1.png` |
| Natureza | verde musgo | `fragment_seal_nature_v1.png` |
| Luz | amarelo/dourado | `fragment_seal_light_v1.png` |
| Trevas | roxo crepuscular | `fragment_seal_dark_v1.png` |

`Wild` e `Cura/Cápsula` são mecânicas de carta. Não possuem personagem,
moldura ou posição na formação.

## Geometria

- Cada PNG possui canvas RGBA transparente de 330×330.
- As cinco variantes usam a mesma geometria.
- O centro é transparente para receber a arte do personagem por trás.
- A moldura fica na frente do personagem.
- O quadrado lateral representa a afinidade pela própria cor, sem glifo.
- Os oito encaixes do arco representam carga de skill, não elementos.
- Não redimensionar ou reposicionar partes internas para personagens isolados.

`fragment_seals_sheet_v1.png` reúne as cinco variantes para inspeção.

## Camadas na cena

1. fundo escuro da janela;
2. sprite do personagem;
3. PNG da moldura elemental;
4. preenchimento dinâmico dos segmentos;
5. halo e interação quando a skill está pronta.

## Prompt-base do asset

> Create five empty Fragment Seal portrait frames in one horizontal row, with
> exactly identical clipped-square pixel geometry, transparent portrait
> openings, a matte charcoal body, warm bone-gray outlines, a small colored
> elemental socket on the left and an upper segmented skill arc. Produce only
> five variants: muted ember red, steel blue, moss green, warm gold and dusk
> purple. No characters, text, symbols, background, hexagons, coins, gloss or
> neon. Preserve genuine RGBA transparency.

Modo utilizado: ferramenta integrada `image_gen`, seguida de recorte mecânico
sem reamostragem e validação no Godot.
