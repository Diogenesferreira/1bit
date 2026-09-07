# Layout geral da tela de batalha — contrato

Espaco de coordenadas declarado em voz alta. Numeros legiveis por maquina em
`spec/layout_batalha.json`.

## 1. Canvas de design

```
largura total .............. 940 px  (fixa; a tela NAO reflui)
  borda externa ............ 2 px  #2b2b28
  padding externo .......... 10 px
  borda interna ............ 1 px  rgba(201,192,168,.30)
  padding interno .......... 14 px
COLUNA DE CONTEUDO ......... 888 px  <- toda medida de secao vive aqui
altura ..................... soma da pilha vertical (nao fixa)
```

## 2. Espacos de coordenadas (R1: um espaco por no, declarado)

| espaco | origem | tamanho | quem vive nele |
| --- | --- | --- | --- |
| CONTENT | canto sup-esq da coluna de conteudo | 888 x auto | todas as secoes, empilhadas, gap 14 |
| STAGE | canto sup-esq do palco | 888 x 560 | inimigos, plate de STAGE, flash |
| PARTY_CARD | canto sup-esq do card | 152 x 188 | moldura, heroi, selo, barra, placa |
| HAND_GRID | canto sup-esq da grade | 888 x 394 | 12 casas, fusao, ghost do BAG |
| ENEMY_PLATE | canto sup-esq da placa | 32k x 12k | digito de TURN, label, barra de HP |

**Nunca** misture: `(9, 147, 134, 10) em PARTY_CARD` e `(0,0,888,560) em STAGE`
sao coisas diferentes.

## 3. Pilha vertical (espaco CONTENT, gap 14 entre secoes)

| # | secao | altura | notas |
| --- | --- | --- | --- |
| 1 | barra da conta | 72 | ver `TOP_BAR.md` |
| 2 | palco | 560 (+1 borda) | ver `ENEMY_HUD.md`, `FORMACOES.md` |
| 3 | rotulo PARTY | 18 | `lbl_party.png` + filete + 3 pips |
| 4 | faixa do party | 226 | pad 22 topo / card 188 / pad 16 base |
| 5 | caixa BAG | 138 | pad 16 / carta 108 / pad 14 |
| 6 | rotulo HAND + botao leader | 34 | botao de leader ancorado a direita |
| 7 | grade da mao | 394 | 2 linhas de 191, gap 12 |
| 8 | barra de LIFE | 38 | pad-top 14 + barra 24 |

## 4. Regras de ancoragem

- **R2 — a hierarquia e normativa.** Quem clipa, clipa explicitamente: no card
  do party, so o `FRAME` clipa (`clip_contents = true`).
- **R3 — heroi ancorado pelos PES.** `y = 136 - altura_de_desenho`, nunca pelo topo.
- **R4 — tamanhos de desenho sao TABELADOS**, nunca derivados de multiplicador.
- **R5 — todo numero que muda vive em caixa de largura reservada, ancorado a
  direita** (`BitmapFontLabel.align_right_in`), para o layout nao deslocar.
- **R6 — o palco e ancorado no CENTRO da coluna**; o backdrop e desenhado em
  888x560 exatos (fonte 222x140 em x4), sem `cover` (que cortaria fora do grid).

## 5. Checklist

- [ ] Coluna de conteudo = 888; nada assume a largura da janela
- [ ] Gap de 14 entre TODAS as secoes da pilha
- [ ] Backdrop em escala inteira x4, `TEXTURE_FILTER_NEAREST`
- [ ] Cada bloco de medida acompanhado do espaco (CONTENT/STAGE/PARTY_CARD/...)
- [ ] Nenhuma medida em % ou vw/vh
