# Fusao das 3 cartas — contrato

Espaco: **HAND_GRID** (888 x 394). Ancora: **centro da grade** (444, 197).
Referencia de leitura: fusao de cartas do Digimon Crusader/Heroes.

## 1. Fases

| fase | em | o que acontece |
| --- | --- | --- |
| 1 | 0 ms | trio fechado; overlay entra, cartas ainda nas casas |
| 2 | 70 ms | as 3 sobem e vao pro centro, **lado a lado** (offset -88 / 0 / +88), leque -6/0/+6 graus |
| 3 | 560 ms | leque zera; comeca o **aquecimento**: 400 ms de `brightness` 1 -> 3.6 e `saturate` 1 -> .15, borda vira #fff, glow branco cresce ate 30 px |
| 4 | 980 ms | **estouro**: as 3 convergem pra offset 0 (fundem no lugar) com punch de escala 1.18; flash de tela; tremor 380 ms; nucleo radial 230 px (#fff -> lit -> base); 2 ondas de choque 120 -> 312 px; 12 estilhacos |
| 5 | 1280 ms | cartas somem; feixe vertical 28 x 300 px; **a energia sai daqui** |
| — | 1780 ms | a energia chega no aliado: +1 carga (+2 se elo >= 2), flash de 400 ms no card |

## 2. Geometria (espaco HAND_GRID, tudo relativo ao centro)

```
cartas ....... 138 x 191 (o MESMO tamanho da mao; nunca miniatura)
offset X ..... fase 2-3: off * 88   |  fase 4+: off * 0
glow ......... 190 x 220 (elipse radial), 70 x 90 antes de empilhar
nucleo ....... 230 x 230, radial #fff 0% / <lit> 38% / <base> 70%
choque ....... 120 x 120 -> scale 2.6, borda 3 px (1a <lit>, 2a #fff +80 ms)
estilhacos ... 12 unidades, angulo i*30 graus, raio 95 + (i%3)*25
feixe ........ 28 x 300, gradiente transparente -> lit -> #fff -> lit -> transparente
```

## 3. Energia ate o aliado

```
duracao ...... 500 ms, ease-in-out cubic (parte rapido, freia na chegada)
dx ........... ELS.indexOf(elemento) * 180.5 - 362   (ELS = dragon,knight,nature,light,dark)
dy ........... -560
orbe ......... 18 x 18, radial #fff -> lit -> base, glow 22 px + 44 px
cauda ........ 10 x 10, base, blur 2 px, atrasada 0.12 do progresso
```

A chegada coincide com o instante em que a carga entra (1780 ms) — os dois
tempos precisam continuar amarrados; se separar, a leitura quebra.

## 4. O que NAO existe mais

`fusion.coreStyle` no palco, `fusion.rings`, `fusion.movers`, `proj.*` — a
fusao **nao acontece mais sobre o inimigo**. Se houver cena `FusionFX`
ancorada no palco, ela deve ser reancorada no `HandGrid`.

## 5. Checklist

- [ ] Overlay dentro do container da MAO, nunca do party nem do palco
- [ ] Cartas no tamanho 138 x 191
- [ ] Lado a lado (offset 88) durante TODO o aquecimento
- [ ] Convergencia para offset 0 acontece no MESMO frame do estouro
- [ ] Crescimento por largura/altura, nunca `scale` (scale interpola e suja o dither)
- [ ] Chegada da energia = 1780 ms = instante da carga
