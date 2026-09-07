# Animações e regras de combate — contrato

Companheiro de `POSICIONAMENTO.md`. Aqui o que é normativo são **tempos, ordem
e gatilhos**, não geometria. Testado ao vivo em `Laboratorio de Animacoes.dc.html`
(canvas de teste separado; a tela de produção `UI Batalha 1bit` segue intacta).

## 1. Ciclo de stage

Três stages: `1/3`, `2/3`, `3/3` (boss). Trios de inimigos nos dois primeiros,
um único boss no terceiro.

| medida | trio | boss |
| --- | --- | --- |
| escala da placa | 4× (128 × 48) | 6× (192 × 72) |
| HP por inimigo | 520 / 760 | 2600 |

Avanço: quando o último inimigo vivo chega a 0, dispara `flash` de 450 ms
(overlay `#f4ecd8`, pico de opacidade .85 em 12% da curva); em **520 ms** troca
o conjunto de inimigos, zera os acumuladores e o nó da trilha avança.

O nó da trilha segue a precedência de `TOP_BAR.md` §4: **boss vence na forma**.

## 2. Dano de múltiplas cartas — cascata rápida

A regra que o modelo antigo errava: **uma animação só e nenhuma soma**. O
correto:

```
para cada carta selecionada, em ordem, com passo de 95 ms:
    aplica dano no primeiro inimigo vivo
    empilha um popup PRÓPRIO, na cor do elemento DAQUELA carta
    soma no acumulador TOTAL do inimigo
    carrega +1 pip na skill do aliado do mesmo elemento
    +4 de energia
turno termina em (n * 95 + 520) ms
```

Passo de **95 ms** ("rápido em cascata"): os números se sobrepõem no ar e leem
como uma rajada, não como golpes separados. Ajustável em `cascadeStepMs`.

Quatro cartas ⇒ **quatro números simultâneos visíveis**, cada um na sua cor.
Empilhamento: `bottom = 44 + indice * 26` — faixas, não um número em cima do
outro. Popup: 22px (30px em skill), `labRise` de 950 ms — nasce em scale .7,
estica a 1.12 em 18%, assenta em 32%, sobe 34px e desaparece.

Acumulador `TOTAL` do inimigo: chip com borda na cor do elemento do stage, some
com `opacity` quando o total é zero, aparece em 200 ms.

## 3. Tremor ao levar dano

**Não use animação CSS/`AnimationPlayer` por golpe.** Um golpe novo no mesmo
inimigo, antes do anterior terminar, não reinicia a animação — o segundo tapa
sai sem tremor, e é exatamente o caso da cascata.

Faça por interpolação, lendo o relógio:

```
t = agora - hit_at
se t > 300ms: offset = (0,0)
decay = 1 - t/300
p = t / 34
offset = ( sin(p*3.1) * 7 * decay , cos(p*4.7) * 7*0.45 * decay )
```

Amplitude 7 px vivo, 2 px morto. O tremor de tela inteira (estouro de fusão e
skills) usa a mesma função com amplitude 5 e duração 380 ms.

Em Godot: `_process` aplicando `position` no nó do inimigo enquanto
`now - hit_at < 0.3`, e nada de tween.

## 4. Morte

`grayscale(1) brightness(.45)` aplicado **na placa e no corpo**, nunca no
wrapper — o wrapper carrega o popup do golpe final, que precisa manter a cor do
elemento. Esse é o bug que aparece primeiro se você aplicar no lugar errado.

## 5. Seleção de carta

O risquinho de 1 px foi descartado. Estado selecionado:

| camada | valor |
| --- | --- |
| deslocamento | `translateY(-14px)`, 120 ms `cubic-bezier(.2,.8,.2,1)` |
| brilho | `brightness(1.14)` |
| halo | `drop-shadow(0 0 12px <elem-light>)` |
| rim | borda 2px `<elem-light>` em `inset:-3px` + `inset 0 0 10px <elem-base>` |
| pulso (uma vez) | anel 2px que vai de scale 1 → 1.22 e opacidade .95 → 0 em 340 ms |

O rim é permanente enquanto selecionada; o pulso toca **uma vez** no clique.

## 6. Fusão de três cartas

Cinco fases. Só libera com 3 cartas do **mesmo** elemento.

| fase | em | o que acontece |
| --- | --- | --- |
| 1 | 0 ms | núcleo nasce com 14 px |
| 2 | 80 ms | as 3 cartas partem de ±150/±110 px rumo ao centro (620 ms, `cubic-bezier(.4,.1,.2,1)`); anéis começam a pulsar (`labRing`, 1.1 s, defasados 360 ms); núcleo → 46 px |
| 3 | 720 ms | cartas chegam a ±12 px do centro e caem para opacidade .35; núcleo → 92 px |
| 4 | 1080 ms | **estouro**: flash de tela, tremor de 380 ms, glow do núcleo 34 → 90 px, 8 estilhaços radiais (210 × 150 px, `labSpark` 620 ms) |
| 5 | 1420 ms | núcleo desaparece; projétil sai do centro até o aliado do elemento (520 ms, `cubic-bezier(.5,0,.6,1)`) |
| — | 1980 ms | aliado pisca (flash branco .5 por 400 ms) e ganha **+3 pips**; turno termina |

O crescimento do núcleo é `transition` de largura/altura, não `scale`: em pixel
art, `scale` interpola e suja o dither.

Quem recebe a carga: **o aliado do elemento fundido**.

## 7. Skill de energia

- Enche **+4 por carta** jogada, teto 20.
- Cheia: a barra ganha `box-shadow 0 0 10px #f0d478` e o botão pulsa
  (`labReady`, 1.6 s).
- **Nunca dispara sozinha.** Fica liberada esperando o clique — decisão de
  design, não omissão.
- Ao disparar: flash + tremor imediatos; a barra esvazia em 120 ms (animada em
  420 ms, `cubic-bezier(.2,.7,.3,1)`); os inimigos são atingidos em cadeia de
  130 ms, 620 de dano cada, popup em tamanho grande (30px); turno termina em
  1200 ms.

## 8. Skill de leader

- Pronta a cada **4 turnos**, contados independentemente de energia; não
  consome energia.
- **O jogador escolhe o alvo.** O clique no botão não dispara: entra em modo de
  mira. Nesse modo cada inimigo vivo ganha `cursor:crosshair`, borda 2px
  `#c9a842` e glow pulsante; um aviso "MIRANDO" aparece no painel de regras.
  Clicar no botão de novo cancela.
- Ao clicar no inimigo: dano de 980 nele, tremor, popup, e o cooldown volta
  para 4.

Estado a modelar no Godot: `aiming: bool`. Enquanto verdadeiro, os inimigos
capturam clique; fora dele, `mouse_filter = IGNORE`.

## 9. Tabela de tempos (resumo)

| animação | duração | curva |
| --- | --- | --- |
| passo da cascata | 95 ms | — |
| popup de dano | 950 ms | ease-out |
| tremor do inimigo | 300 ms | decaimento linear |
| tremor de tela | 380 ms | decaimento linear |
| barra de HP / energia | 420 ms | `cubic-bezier(.2,.7,.3,1)` |
| flash de tela | 450 ms | ease-out |
| seleção de carta | 120 ms | `cubic-bezier(.2,.8,.2,1)` |
| pulso de seleção | 340 ms | ease-out |
| convergência da fusão | 620 ms | `cubic-bezier(.4,.1,.2,1)` |
| projétil da fusão | 520 ms | `cubic-bezier(.5,0,.6,1)` |
| troca de stage | 520 ms | — |

## 10. Checklist

- [ ] Um popup por carta, na cor da carta, em faixas de 26 px
- [ ] Acumulador `TOTAL` somando por inimigo, zerado na troca de stage
- [ ] Tremor por interpolação de relógio, não por animação disparada
- [ ] Cinza de morte na placa e no corpo, não no wrapper
- [ ] Energia só dispara por clique
- [ ] Leader entra em modo de mira antes de resolver
- [ ] Fusão cresce por largura/altura, não por `scale`
- [ ] Cooldown do leader independente da energia
