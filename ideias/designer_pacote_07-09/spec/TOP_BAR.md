# Área superior + plate de STAGE — contrato de layout

Mesmo formato de `POSICIONAMENTO.md` e `LIFE_BAR.md`. Implementado em
`godot/TopBar.gd` e `godot/StagePlate.gd`.

## 1. A regra que organiza tudo aqui

**Todo número que muda em runtime vive numa caixa de largura reservada,
ancorado à direita.** A caixa é dimensionada pelo maior valor possível, não pelo
valor atual. Consequência: nada se desloca quando a moeda passa de 999 para
1000, e os números de blocos vizinhos compartilham a mesma margem direita.

A folga que aparece entre o ícone e o número **é intencional** — é o que faz a
coluna existir. Não a remova "encostando" o número no ícone.

`BitmapFontLabel.align_right_in` implementa isso: define a largura do nó e
empurra os glifos para o fim.

| contador | máximo previsto | glifos | caixa |
| --- | --- | --- | --- |
| moeda | 9 999 999 | 7 | 90 |
| gema | 99 999 | 5 | 64 |
| energia | `999/999` | 7 | 90 |
| LV da conta | 999 | 3 | 38 |
| XP | 9 999 | 4 | 51 |

Fórmula: `caixa = digitos * 13 - 1` (glifo 12 + tracking 1, sem tracking no fim).
Para mudar um teto, mude só esse número.

## 2. Árvore de nós — TopBar (normativa)

Linha de **72** de altura, largura = `row_width` (468 no alvo de 500px).

```
TopBar               Control  row_width x 72   PRESET_TOP_LEFT
├── emblem_bg        ColorRect (0,2,68,68)  #141512 + borda 2px bone .6
│   └── slot         (3,5,62,62)  #0b0d0a  ← foto/emblema da conta entra aqui
├── pip_tl           ColorRect (-2,0,9,9)    bone      ← sangram, ficam no TopBar
├── pip_br           ColorRect (61,63,9,9)   bone
├── name             BitmapFontLabel (84,20)  glyph 17, tracking 2
├── lv_chip          ColorRect (nx,19,chip_w,22) #121211 + borda 1px .32
│   ├── "LV"         glyph 16, tracking 1, alpha .55
│   └── lv_value     glyph 16, align_right_in 38
├── "XP"             BitmapFontLabel (84,47)  glyph 16, alpha .55
├── xp_well          ColorRect (118,47,214,13) #121211 + borda 1px .5
│   └── xp_fill      ColorRect (120,49,210*ratio,9)  bone
├── xp_value         BitmapFontLabel  glyph 16, align_right_in 51, alpha .8
├── WALLET_RACK      ColorRect (rx,21,coin_w+1+gem_w,30) #121211 + borda 1px .32
│   ├── divider      ColorRect (rx+coin_w,21,1,30)  bone .25
│   ├── coin_icon    TextureRect (+10,+5,20,20)   icon_coin.png
│   ├── coin_value   glyph 16, align_right_in 90
│   ├── gem_icon     TextureRect (+10,+5,20,20)   icon_gem.png
│   └── gem_value    glyph 16, align_right_in 64
├── ENERGY_PLATE     ColorRect (ex,21,energy_w,30) #141512 + borda 1px **.55**
│   ├── energy_icon  TextureRect (+10,+5,20,20)   icon_energy.png
│   └── energy_value glyph 16, align_right_in 90
└── menu             3x ColorRect 34x5, passo 11, x = row_width-34
```

Espaços: tudo em espaço de **TopBar**. Nenhum nó clipa aqui — nada transborda.

Larguras dos blocos: `bloco = 10 + 20 + 7 + caixa + 10`.
Coin 127 · gem 101 · energy 127.

Ancoragem horizontal: o menu é ancorado à **direita**; a energia à esquerda do
menu; o rack à esquerda da energia. Tudo calculado a partir de `row_width`, para
a direita crescer com a tela e a coluna da conta ficar fixa na esquerda.

## 3. Hierarquia visual (por que está assim)

- **Rack único para moeda + gema**, separadas por filete de 1px: são recursos de
  conta, leem como uma carteira só. Antes eram dois pares soltos com gap 16 e
  pareciam bagunça.
- **Energia em plate próprio**, borda `.55` contra `.32` do rack, separada por
  espaço em vez de filete: é recurso de **combate**, categoria diferente.
- **Ícones normalizados em célula de 20×20**, centralizados. As artes têm
  17×17, 15×18 e 13×20 — sem a célula, as linhas de base não alinham.
- **Chip de LV com a mesma borda e o mesmo fundo dos contadores**: mesma classe
  de informação, mesmo tratamento.

Ícones agora são PNG (`ui/icon_coin.png`, `icon_gem.png`, `icon_energy.png`,
20×20, 1-bit com alpha em limiar) — não recorte polígono em runtime.

## 4. Plate de STAGE

Posição: canto **inferior esquerdo** do palco, `left 22, bottom 20`.
Altura = `16 + 2*9 = 34`. Largura = conteúdo (a spec não fixa; o nó mede).

```
StagePlate           Control  auto x 34
├── bg               ColorRect (0,0,w,34)  #0b0d0a  ← OPACO
├── border           4x ColorRect w=1      bone .55
├── "STAGE"          glyph 16, tracking 2, alpha .6      x = 13
├── value "2/3"      glyph 16, tracking 1                x += lbl + 12
├── divider          ColorRect (x,8,1,18)  bone .28      x += valor + 12
└── trail            nós + conectores, centrados em y=17
    └── "BOSS"       glyph 16, tracking 2, alpha .8      x += 8
```

Trilha de nós (losangos = quadrado rotacionado 45°, conector 20×2):

| estado | lado | preenchimento | borda |
| --- | --- | --- | --- |
| concluído | 12 | bone | — |
| atual | 15 | `#7d9455` | 2px bone |
| futuro | 12 | `#1a1a16` | 2px bone .45 |
| boss (último) | 17 | `#2a1512` | 2px `#c04a3e` |

Conector antes do nó atual: alpha .5. Depois: alpha .28.

**Precedência:** o boss vence na forma. Quando o boss É o stage atual ele
continua 17px com borda `#c04a3e` e apenas **ganha o glow** de atual — não
vira o losango verde de 15px. Testar isso é o caso que quebra primeiro.

**Por que estava ilegível:** `lbl_stage.png` (fonte de 48px) exibido a 11px e
`val_stage.png` a 12px — reescala fracionária — sobre plate com alpha .72 em
cima de um fundo noturno ocupado. Corrigido com folha 1:1 e plate **opaco**.
Não devolva o alpha ao plate: o palco atrás dele é imagem, não cor plana.

Em Godot, o losango precisa de pivô centralizado antes do `rotation`, senão gira
em torno do canto e sai de lugar — `StagePlate._diamond()` faz isso.

## 5. Checklist de integração

- [ ] Todo contador usa `align_right_in` com o valor da tabela da seção 1
- [ ] Nenhum PNG de texto restante (`lbl_*`, `val_*` estão aposentados)
- [ ] Ícones de 20×20 vindos de PNG, `Filter = Nearest`
- [ ] Borda da energia `.55`, do rack `.32` — a diferença é semântica
- [ ] Emblema 68×68 com pips de 9px sangrando 2px para fora
- [ ] Menu ancorado à direita; rack e energia posicionados a partir dele
- [ ] Plate de STAGE **opaco** `#0b0d0a`
- [ ] Losangos com pivô centralizado
- [ ] `row_width` real medido do container, não chutado

## 6. Arquivos

```
export_godot/
  godot/TopBar.gd            barra da conta
  godot/StagePlate.gd        plate de STAGE + trilha de nós
  godot/BitmapFontLabel.gd   agora com `tracking` e `align_right_in`
  ui/icon_coin.png  icon_gem.png  icon_energy.png     20x20
  ui/font_1x_v1.png                                   480x16, célula 12x16
```

Aposentados: `lbl_lv`, `val_lv`, `lbl_xp`, `val_xp`, `val_coin`, `val_gem`,
`val_energy`, `lbl_stage`, `val_stage`, `lbl_boss`, `val_account`. Ficam no
pacote por histórico.
