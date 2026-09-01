# Mockup UI — Selos de Fragmento v1

## Direção canônica aprovada

- Tela mobile vertical de batalha para **1 Bit Heroes**.
- Arena ocupa aproximadamente 55% da tela, com cenário original em perspectiva e caminho que pode avançar entre encontros/turnos.
- Inimigos aparecem inteiros no mundo, com HUD compacto cinza, quadrado elemental, `X TURN` e barra de vida vermelha.
- Os cinco aliados ficam em posições fixas como **Selos de Fragmento**: placas quadradas com cantos recortados, retrato e medidor semicircular de oito segmentos.
- O aliado não ocupa permanentemente a arena. Ao agir, manifesta uma projeção de corpo inteiro ligada ao selo.
- A fusão de três cartas envia energia em pixels ao selo selecionado.
- Campo inferior mantém cartas em grade, fila `NEXT`, dois espaços tracejados, vida universal e energia.
- Estilo **1-bit-plus**: carvão e branco quente dominantes, com uma cor fosca por elemento. Sem neon, brilho plástico ou molduras sci-fi azuis.

## Prompt final usado

Create one polished, original portrait mobile battle UI concept image for the game "1 Bit Heroes", approximately 9:16. Preserve the current game's portrait division, matte card language, elemental card silhouettes, near-monochrome pixel-art identity and practical battle information. Use the old commercial game screenshots only as inspiration for the hierarchy in which enemies physically occupy the arena while player characters are represented by compact portraits; do not copy hexagons, sci-fi frames, cards, characters, layout, logos, numbers, icons or backgrounds.

The top 55% is a completely original dark ruined moonlit biome rendered as crisp retro pixel art, with a central path receding into the distance so the background can plausibly advance between enemy turns. Place three original full-body enemy creatures at different depths. Above each enemy use a compact neutral charcoal/gray pixel HUD with a small square elemental swatch, readable `3 TURN`, and a thin red health bar.

At the lower border of the arena, place five compact **Fragment Seals** for the player's allies. They are not coins and not hexagons: use original clipped-square stone-plaque silhouettes. Each seal contains a close-up 1-bit portrait of an original ally and an integrated eight-segment semicircular skill meter, with muted ember red, steel blue, moss green, warm gold and dusk purple accents. The seals stay on a fixed horizontal rail. Show one green seal fully charged and clickable. From it, a translucent green-white full-body echo briefly manifests into the arena to attack. Show three selected cards fusing above the hand and a detailed stream of square pixel energy travelling from the fusion into that charged seal.

The bottom 40–45% is the card puzzle: a clean `NEXT` strip and a 2-by-5 field with two dashed empty entry slots. Cards are matte charcoal and bone-white with restrained elemental tint mostly in the silhouette and a thin inner edge: fire red, armor blue, nature green, light gold and dark purple. Include one subtly multicolored Wild card and one muted-brown Heal card. At the bottom show universal life `70/70`, a subtle progress strip and energy `3/3`.

Use an evolved **1-bit-plus** identity: black/charcoal and warm bone remain dominant, with only one muted accent per element. Crisp nearest-neighbor pixel edges, selective dithering, limited palettes, retro handheld RPG, gothic but charming. Flat matte UI, no glossy neon, no photorealism, no modern blue sci-fi gradients. The result must look like a production-ready UX concept, not a loose illustration. Do not include copyrighted characters, franchise logos, exact original backgrounds, copied UI frames or five full player bodies permanently standing in the field.

## Referências e função de cada uma

- `10_paleta_elemental_cards_v1.png`: estrutura atual, linguagem das cartas e paleta.
- `mockup_medidor_skill_radial_v1.png`: personagens próprios e medidor segmentado.
- `01.png` e `04.png`: somente hierarquia entre retratos aliados e inimigos em campo.
- `02_bg_07_00.png`: somente profundidade/perspectiva de percurso; o cenário gerado é novo.

Modo de geração: ferramenta integrada `image_gen`, com referências locais.

## Estado da implementação

Em 30/08/2026, o pacote final `Selos de Fragmento Elementais` entrou na cena
jogável: cinco posições fixas, retratos transparentes encaixados, cinco molduras
elementais e folhas oficiais com os estados 0/8–8/8. O estado cheio pulsa e é
clicável. O HUD inimigo proporcional do conceito foi preservado. A manifestação
temporária de corpo inteiro será a próxima camada de animação.

Os cinco retratos finais de teste também entraram como PNGs RGBA individuais em
`assets/battle/characters_v3/`. Cada um possui recorte e escala próprios para
preencher a janela sem modificar a geometria fixa do selo.

O HUD inimigo foi substituído pelas camadas oficiais 384×144 do mesmo pacote:
socket elemental, dígito raster, rótulo `TURN`, calha e life vermelho recortado.
Ele suporta turnos 0–5, anima a perda de life em 420 ms e pulsa abaixo de 25%.

### Fechamento do primeiro beta

A arena agora termina visualmente em uma faixa carvão plana exclusiva dos cinco
aliados. Os selos passaram para 190×190, a fusão ocorre no centro do campo e a
fila permanece visível e independente. A faixa possui somente uma divisória
superior, evitando uma moldura fechada redundante. A especificação
procedural do pacote também foi implementada: alinhamento, convergência, anel,
48 partículas Bézier com rastro, popup manga e cinco impactos elementais.

O contrato de layout congelado para os backgrounds animados está em
`UI_BETA_FINAL_MAPA.md`.

## Contrato de assets dos personagens

Todos os personagens usam uma das cinco variantes de geometria idêntica em
`assets/battle/ui_v6/frames/`. O PNG permanece intacto na camada frontal; a arte
individual, obrigatoriamente RGBA transparente, é encaixada atrás da janela. A
carga usa as folhas em `assets/battle/ui_v6/charge_sheets/`, escolhendo um dos
nove quadros por `AtlasTexture`. Não gerar ou recortar uma moldura diferente
por personagem.

Essas são as únicas cinco afinidades de personagem. `Wild` e `Cura/Cápsula`
existem somente como tipos funcionais de carta e não podem receber moldura,
personagem ou posição própria na formação.
