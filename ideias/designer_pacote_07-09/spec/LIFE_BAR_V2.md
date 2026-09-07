# Barra de LIFE do jogador — v2 (07/09/2026)

Substitui `LIFE_BAR.md`. Mudou o **modelo de preenchimento**: saiu o tile de
textura, entrou o dither procedural (o mesmo da barra de energia).

## 1. Linha (espaco CONTENT)

```
[coracao 27x24]  14  [HP]  14  [ ===== trilho elastico ===== ]  14  [1840/2400]
altura da linha ... 24    filete superior 1 px rgba(201,192,168,.22), pad-top 14
```

## 2. Trilho

| medida | valor |
| --- | --- |
| altura | 24 (era 24) |
| borda | **3 px** `#c9c0a8`, desenhada por dentro |
| fundo | `#14140f` |
| padding interno | 2 px |
| preenchimento | `repeating-linear-gradient(90deg, <base> 0 3px, <lit> 3px 6px)` |
| cor (HP) | base `#a8443a`, lit `#d9705f` |
| glow | `0 0 10px rgba(217,112,95,.5)` |
| transicao | 420 ms `cubic-bezier(.2,.7,.3,1)` |

Em Godot: em vez de `STRETCH_TILE` de PNG, um `ColorRect` com shader de faixas
de 3 px (ou um tile 6x1 gerado em runtime). **Nao** volte aos
`hp_tile_field/fill.png` — o dither procedural garante a faixa exata em
qualquer largura de trilho.

## 3. Texto

| bloco | folha | glyph | tracking | conteudo |
| --- | --- | --- | --- | --- |
| rotulo | `ui/font_1x_v1.png` | 12 | 1 | `HP`, alpha .65 |
| valor | `ui/font_1x_v1.png` | 16 | 1 | `%d/%d`, ancorado a direita |

## 4. Checklist

- [ ] Fill cresce por largura, da esquerda, nunca `scale`
- [ ] Faixas de 3 px mantidas em qualquer largura (dither, nao textura esticada)
- [ ] Valor ancorado a direita (nao empurra o trilho quando o numero cresce)
