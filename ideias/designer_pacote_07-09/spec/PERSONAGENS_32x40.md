# Template de personagem — 32 × 40 px

Personagem novo = **toucado + arma + paleta**. O chassi nunca muda.

## Faixas do chassi (linhas lógicas)
| faixa | conteúdo |
|---|---|
| y0–2 | penacho / ponta de capuz / espinhos |
| y3–18 | cabeça, 16 px de largura (x8–23); olhos 2×4 em y11–14, x11–12 e x19–20 |
| y19 | pescoço, gola, ombreiras |
| y20–27 | tronco (x12–19) e braços (x9–11 / x20–22); mãos em y26–28 |
| y28–33 | pernas, separadas por 1 px de tinta em x16 |
| y34–35 | botas, na cor da tinta do personagem |
| y36–37 | sombra de contato (2 linhas, preto 19%) |

Zonas de arma: **x1–8** (esquerda) e **x24–31** (direita) — nunca invadem a cabeça.
A arma é desenhada **depois** do corpo e a mão vem por cima do cabo (y25–27), então parece empunhada.

## Bibliotecas
**Toucados:** spike · helm · hood_leaf · hood_round · hood_horn
**Armas:** flame_sword · sword_shield · bow_quiver · staff_orb · spear_cape

## Paleta — 8 slots por personagem
hair · hairHi · hairDk · cloth · clothHi · clothDk · acc · out

| id | hair | hairHi | hairDk | cloth | clothHi | clothDk | acc | out |
|---|---|---|---|---|---|---|---|---|
| dragon | #e0654f | #f79878 | #a83b30 | #8f3a31 | #b95a4a | #5b2320 | #e8a55c | #33201d |
| knight | #5f8cb8 | #9cc4e0 | #3a5d7e | #3a597a | #5b81a5 | #22364c | #c9d6de | #1a2432 |
| nature | #7fa055 | #a8c47a | #547040 | #425e36 | #5d7d4a | #283a22 | #ab8550 | #1e2b1b |
| light | #f5efdc | #ffffff | #cec4a8 | #e9e2cb | #faf6e9 | #bcb195 | #cfa93f | #3b3323 |
| dark | #48375c | #6d5484 | #2a2039 | #31233d | #493459 | #1b1327 | #a37fd0 | #181322 |

Pele comum: `#f2cfa4` / `#d3a377` / `#ab7c56`. Olho `#1b1a1f` com brilho `#4d4750`.
`out` é sempre a cor do personagem escurecida — **nunca preto puro**.

## Escalas e arquivos
Só escalas inteiras: 1× (ícone), 2× (aliado no party), 3× (líder / lista), 4× (palco), 6× (chefe).
Arquivo: `hero_<id>.png` (grid 32×40; asset gravado a 6× = 192×240).

## Frames previstos
idle 2 quadros (respiração 1 px) · attack 2 (arma avança 2 px, tronco inclina 1 px) ·
hurt 1 (recua 1 px e clareia) · down 1 (silhueta em tinta). Folha final: 6 quadros = 192×40 lógico.

## Inimigos
Mesmo template, **espelhado** (scaleX −1) e com a paleta um tom mais fria/escura.
A placa de turno/HP não muda (k=4 → 128×48, 7 px acima do sprite).
Chefe = mesmo sprite a 6× com losango do elemento no canto.
**Hexágono nunca em inimigo** — hexágono é linguagem de aliado.
