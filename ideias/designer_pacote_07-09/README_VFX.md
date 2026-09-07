# VFX — fusão das cartas, balão de dano e impacto por elemento (v1)

Tudo abaixo é **procedural** (desenhado em código, sem sprite sheet), em pixel inteiro.
A referência jogável está em `html/Selos de Fragmento.dc.html` — seções "Fusão das 3 cartas"
e "Impacto no inimigo". O canvas de referência é **300 × 180 lógicos**, exibido em 3×.
Escale por múltiplos inteiros; nunca por fator fracionário.

---

## 1. Fusão das 3 cartas → selo do personagem

Pontos-chave (coordenadas no canvas 300×180):
- cartas na mão: x 34 / 132 / 230, y 132, tamanho 26×36
- alinhamento: x 118, 150, 182 (mesma y)
- ponto de fusão / estouro: (150, 150)
- alvo: centro do selo em (150, 52) — o selo é desenhado a 92×92

| fase | ms | curva | o que acontece |
|---|---|---|---|
| alinhar | 0–420 | ease-out cúbica | as 3 cartas escolhidas deslizam para o centro, lado a lado |
| convergir | 420–820 | ease-out cúbica | as 3 se sobrepõem num único ponto |
| clarão | 820–1020 | linear (fade out) | quadrado bone 32×32 sobre o ponto de fusão |
| estouro | 820–1360 | ease-out | anel de 26 quadrados, raio 6 → 60, tamanho 3 → 1 px, alpha 1 → 0 |
| viagem | 1020–1980 | bézier quadrática | **48 quadradinhos** de 2–3 px sobem até o selo |
| carga | conforme chegada | — | **1 encaixe aceso a cada 6 partículas** que chegam (0–8) |
| pronto | após 8/8 | loop 1300 ms | halo pulsando (blend aditivo do quadro 8/8) |
| ciclo | 3600 | — | reinicia |

Partículas: cada uma tem `delay` 0–420 ms, `duração` 520–780 ms, ponto de controle
`C = meio do caminho + (spread × 46, −0..26)` e um **rastro de 3** amostras
(offsets −0.07 e −0.14 de progresso, alpha 0.5, cor bone).
Cor da partícula = cor do elemento fundido; o rastro é bone.

## 2. Balão de dano (estilo manga)

- Aparece na primeira partícula que chega, ao lado do selo (referência: 232, 40).
- Contorno **irregular desenhado pixel a pixel**: elipse com raio modulado
  `r(θ) = 1 + 0.20 · cos(13θ)` — 13 pontas. Miolo `#e8e3d4`, contorno `#201f1d`,
  rabicho de 6 px apontando para baixo.
- Número em fonte bitmap 5×7 escala 2, tinta `#201f1d` com sombra na cor do elemento.
- **Acumula 7 de dano por partícula** que chega (48 partículas = 336). O total é o dano
  aplicado ao inimigo no fim das junções.
- Pop a cada incremento: escala 1.28 → 1.00 em **130 ms**.

## 3. Impacto no inimigo — um VFX por elemento

Comum a todos (duração total **900 ms**):

| efeito | ms | detalhe |
|---|---|---|
| clarão | 0–90 | retângulo bone sobre o inimigo, alpha 1 → 0 |
| tremor | 0–260 | ±2 px, seno de período 26 ms |
| dreno do HP | 0–420 | ease-out |
| numeral do dano | 0–520 | sobe 16 px e mantém; fonte 5×7 escala 2, cor do elemento + sombra `#201f1d` |

Específico por elemento (k = 0..1 ao longo dos 900 ms):

- **Dragão / Fogo** — 10 labaredas verticais (colunas de blocos 1–3 px de largura,
  altura senoidal, pico em k≈0.35, ponta `#f0d7a0`, corpo `#a8443a`/`#8f3229`)
  + 18 brasas subindo 46 px com oscilação lateral de 2 px.
- **Cavaleiro / Aço** — impacto: clarão forte nos primeiros 12%, **3 ondas em diamante**
  (34 quadrados por onda, raio 6 → 46, achatamento 0.6, defasagem de 12%) e
  **14 estilhaços** radiais com rastro de 3 (cor `#5f7d94` no rastro).
- **Natureza** — **7 espinhos brotando do chão** (colunas afinando no topo, ponta bone,
  crescimento defasado de 5% por espinho, ease-out em 45% do tempo)
  + 16 folhas caindo/derivando com oscilação senoidal.
- **Luz** — **8 raios radiais** (passo de 2 px, ponta `#f5ecd0`) + **2 anéis** defasados
  (raio 6 → 40, achatamento 0.7) + 10 faíscas piscando.
- **Trevas** — duas fases: **implosão** (0–42%: 24 quadrados vindo de fora para o centro)
  e **floração escura** (42–100%: 80 quadrados em espiral de ângulo dourado, com 1/3 dos
  índices vazados por dithering, mais 3 gotas descendo).

## 4. Notas de implementação no Godot 4

- Cartas: `Sprite2D` + `Tween` de `position` (TRANS_CUBIC, EASE_OUT) para alinhar e convergir.
- Estouro e partículas: um **pool de `Sprite2D` de 1 px** (ou `MultiMeshInstance2D`) e um
  `Curve2D`/bézier manual — evite `GPUParticles2D` se quiser as posições travadas em px inteiro.
- Balão: desenhe uma vez num `ImageTexture` gerado em runtime (mesmo laço pixel a pixel) e
  só troque o número; anime a escala com `Tween` em 130 ms.
- Numerais: as folhas `enemy_digits_sheet_v1.png` (42×48 por dígito) já servem para o dano;
  para o balão use a mesma fonte 5×7 numa escala menor.
- **Sempre** `Filter = Nearest`, e arredonde posições com `round()` antes de aplicar.
