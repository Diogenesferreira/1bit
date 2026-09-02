# Área superior e plate de STAGE — contrato de layout

## Regra dos contadores

Todo número variável vive em uma caixa de largura reservada e fica ancorado à
direita. O layout não se desloca quando um contador ganha dígitos.

| contador | máximo | largura reservada |
| --- | ---: | ---: |
| moeda | 9.999.999 | 90 |
| gema | 99.999 | 64 |
| energia | 999/999 | 90 |
| level | 999 | 38 |
| XP | 9.999 | 51 |

## TopBar

Na batalha, `TopBar` fica em `(27,19)`, mede `886×72` e usa coordenadas locais:

```text
TopBar 886x72
├── emblema 68x68, centralizado verticalmente, borda 2px
├── nome + chip LV
├── XP + calha 214x13 + valor reservado
├── carteira: moeda | gema, em um único rack de 30px
├── energia: plate próprio de 30px, borda reforçada
└── menu: três traços 34x5, ancorados à direita
```

- Emblema tem janela interna 62×62 e pips de canto 9×9.
- Ícones de moeda, gema e energia são PNG de 20×20, nunca polígonos runtime.
- A carteira usa borda alpha `.32`; energia usa `.55`.
- Valores usam `BitmapFontLabel.align_right_in`.
- O menu, a energia e a carteira são calculados a partir da margem direita.

## StagePlate

O plate fica em `(22,504)` dentro da arena: 22 px da esquerda e 20 px da base
do palco de 558 px. A altura é 34 px e a largura acompanha o conteúdo.

```text
StagePlate
├── fundo opaco #0b0d0a + borda 1px
├── STAGE, glyph 16, tracking 2
├── valor 2/3, glyph 16, tracking 1
├── divisor 1x18
└── trilha: concluído — atual — boss + rótulo BOSS
```

Os textos são formados pela folha bitmap 1:1. Os losangos giram ao redor do
próprio centro. O fundo permanece opaco para impedir que o cenário prejudique a
leitura.
