# Fusão de cartas — atualização (troca de local: mão, não palco)

Substitui a seção 6 de `ANIMACOES.md`. A fusão não acontece mais no palco
sobre o inimigo — acontece **na mão**, nas próprias cartas. Referência:
fusão de cartas do Digimon Crusader/Heroes.

## Por que mudou

Antes: 3 cartas voavam da mão até o centro do palco, energia se acumulava lá,
estourava sobre o inimigo, um projétil ia até o aliado. Larga demais — o palco
é do combate, não da economia de skill; e a leitura ficava "ataque", quando é
"carregamento de skill".

Agora: as cartas nunca saem da faixa da mão. A energia nasce ali, sobe até o
aliado. O inimigo não participa dessa animação.

## As cinco fases (tudo em `fusionHand`, ancorado na faixa da mão)

| fase | em | o que muda |
| --- | --- | --- |
| 1 | 0 ms | estado inicial — 3 cartas nas posições normais da mão |
| 2 | 70 ms | as 3 sobem juntas 128px e convergem para o centro, leque de -6°/0°/+6° |
| 3 | 560 ms | fecham o leque, empilham quase sobrepostas (±10px), brilho radial cresce por trás delas — "energia acumulando" |
| 4 | 980 ms | **estouro**: flash de tela, tremor de 380ms, burst circular atrás do maço, glow do fundo intensifica |
| 5 | 1280 ms | cartas desaparecem (opacity→0); um feixe vertical de 20×340px sobe da mão até a área do aliado |
| — | 1780 ms | aliado pisca e ganha **+3 pips**; cartas são substituídas; turno termina |

Tempos totais iguais aos de antes (turno fecha em ~1780ms), só o palco fica de
fora.

## Geometria (espaço: FAIXA DA MÃO)

```
glow radial     bottom 132, largura 60→130px conforme empilha, altura 150
anel pulsante   bottom 118, 96x96, so na fase 3 (antes do estouro)
3 cartas        bottom 0, largura 78x108, deslocamento X = offset*60 (leque)
                                          -> offset*10 (empilhado), leque -6/0/+6°
burst           bottom 186, circulo 150x150, blur 2px, .5s
feixe           bottom 186, 20x340, gradiente para transparente no topo, .5s
```

Todas as cores vêm do elemento fundido (`EL[el].base/lit`), igual ao resto do
sistema — nada de cor nova.

## O que NÃO existe mais

`fusion.coreStyle`, `fusion.rings`, `fusion.movers`, `fusion.sparks`, `proj.*` —
eram o núcleo/anéis/projétil no palco. Removidos. Se o Godot já tinha uma cena
`FusionFX` ancorada no palco, ela deve ser reancorada na faixa da mão
(`HandRow` ou equivalente) e reconstruída com a geometria acima.

## Checklist

- [ ] Fusão renderiza dentro do container da mão, nunca sobre o palco/inimigo
- [ ] As 3 cartas da mão ficam invisíveis (`opacity:0`) enquanto a fusão roda
- [ ] O feixe sobe da mão até a área do card do aliado, não do centro do palco
- [ ] O inimigo não recebe nenhum efeito visual desta animação
