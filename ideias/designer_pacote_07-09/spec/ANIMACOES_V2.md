# Animacoes — contrato completo (07/09/2026)

Substitui `ANIMACOES.md` (06/09) inteiro. Toda duracao aqui e a que esta
rodando no canvas `html/UI Batalha 1bit.dc.html`.

## 1. Tabela mestra

| # | animacao | gatilho | duracao | curva |
| --- | --- | --- | --- | --- |
| 1 | selecao de carta (subir) | toque na casa | 120 ms | cubic-bezier(.2,.8,.2,1) |
| 2 | pulso de selecao (anel) | toque na casa | 340 ms | ease-out |
| 3 | fila do BAG avanca | carta desce | 220 ms | ease-out cubic |
| 4 | carta caindo do BAG (ghost) | carta desce | 380 ms | ease-out cubic |
| 5 | fusao — subida/lado a lado | 3a marcada | 70 -> 560 ms | cubic-bezier(.4,.1,.2,1) |
| 6 | fusao — aquecimento (clarao) | fase 3 | 400 ms (560->980) | linear sobre brightness |
| 7 | fusao — estouro | 980 ms | 600 ms | cubic-bezier(.15,.8,.3,1) |
| 8 | ondas de choque (2x) | estouro | 550 ms (+80 ms atraso na 2a) | ease-out |
| 9 | estilhacos (12) | estouro | 500 ms | ease-out |
| 10 | feixe vertical | 1280 ms | 500 ms | ease-out |
| 11 | energia viaja ate o aliado | 1280 ms | 500 ms | ease-in-out cubic |
| 12 | carga entra no aliado (flash) | 1780 ms | 400 ms | ease-out |
| 13 | tremor do inimigo | dano | 300 ms | decaimento linear |
| 14 | tremor de tela | estouro / skill | 380 ms | decaimento linear |
| 15 | popup de dano | dano aplicado | 950 ms | ease-out |
| 16 | cascata de popups | fim da corrente | 90 ms de passo | — |
| 17 | barra de HP / energia | mudanca de valor | 420 ms | cubic-bezier(.2,.7,.3,1) |
| 18 | flash de tela | estouro / troca de stage | 450 ms | ease-out |
| 19 | troca de stage (swap) | ultimo inimigo cai | 480 ms | — |
| 20 | crossfade do backdrop | troca de stage | 600 ms | linear |
| 21 | embaralhar a mao (pop) | fim da corrente | 260 ms + 20 ms/casa | ease-out |
| 22 | skill pronta (faixa) | carga = 8 | 900 ms em loop | ease-out |
| 23 | skill pronta (barra pulsa) | carga = 8 | 1400 ms em loop | ease-in-out |
| 24 | botao de skill pulsa | carga = 8 | 1100 ms em loop | ease-in-out |
| 25 | botao pronto (leader/energia) | pronto | 1600 ms em loop | ease-in-out |
| 26 | banner do leader entra | modo de mira | 220 ms | ease-out |

## 2. Tremor — por interpolacao, nunca por animacao disparada

Um golpe novo no mesmo inimigo antes do anterior acabar **nao reinicia** uma
animacao CSS/AnimationPlayer. E exatamente o caso da cascata. Faca por relogio:

```
t = agora - hit_at
se t > 300ms: offset = (0,0)
decay = 1 - t/300
p = t / 34
offset = ( sin(p*3.1) * A * decay , cos(p*4.7) * A*0.45 * decay )
A = 6 (inimigo vivo) | 2 (morto) | 5 (tela inteira, 380 ms)
```

## 3. Popup de dano

- Um popup **por elo da cadeia**, na cor do elemento daquele elo.
- Espalhados por 8 posicoes no corpo do inimigo (tabela `scatter` no JSON),
  x em % do centro, y em px acima da base — **nao** empilhados em coluna.
- Placa: `linear-gradient(180deg, <base>33, rgba(8,9,8,.82))`, borda 2 px `<lit>`,
  glow `0 0 14px <base>`, contorno preto em 4 direcoes, 26 px (32 px se `big`).
- `b1Rise`: nasce em scale .7, estica a 1.12 em 18%, assenta em 32%, sobe 32 px.

## 4. Fusao — ver `FUSAO.md`

## 5. Regras de comportamento

- **A energia nunca dispara sozinha**; o botao fica liberado esperando o clique.
- **Leader entra em modo de MIRA**; o jogador escolhe o alvo. Cooldown 4 turnos,
  contado pra cima na UI (`ACTIVE SKILL LEADER n/4`).
- **Dano da corrente aplica de uma vez** no fim (apos ENTRADA entrar na mao, a
  BAG chover e a mao redistribuir), com os popups em cascata de 90 ms.
- **Cinza de morte** (`grayscale(1) brightness(.45)`) vai na placa e no corpo,
  **nunca** no wrapper — senao o popup do golpe final perde a cor do elemento.
