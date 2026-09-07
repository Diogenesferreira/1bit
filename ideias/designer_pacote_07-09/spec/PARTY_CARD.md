# Card de personagem (party) — contrato

Espaco: **PARTY_CARD** (152 x 188). Substitui `PARTY_HERO.md` e a secao de
geometria de `PARTY_LEADER.md`.

## 1. Arvore de nos (normativa)

```
PartyCard          Control 152x188  PRESET_TOP_LEFT
├── bg             ColorRect (0,0,152,188)  #0d0e0c
├── border_out     4x ColorRect w=2         #14140f
├── FRAME          Control (2,2) 148x184   clip_contents = TRUE
│   ├── field      TextureRect (0,0,148,184) STRETCH_TILE  field_<el>.png (24x24)
│   ├── scene      TextureRect (-1,0,150,138) STRETCH_SCALE scene_<el>.png
│   ├── hero       TextureRect (cx, 136-h, w, h)            char_<el>.png
│   └── border_in  4x ColorRect w=2  = cor base do elemento
├── seal_bg        ColorRect (-3,-3,30,30) #0d0e0c      <- sangra, filho do CARD
├── seal_border    4x ColorRect w=2  = cor base
├── seal_sym       TextureRect (-1,-1,26,26) sym_<el>.png
├── skill_bar      ColorRect (9,147,134,10) + borda 1 + 8 pips (14x6, passo 16)
├── charge_strip   ColorRect (2,145,148,2)   so quando carga = 8
├── skill_button   Control (125,122,22,22)   so quando carga = 8   <- CLICAVEL
├── name_plate     ColorRect (2,162,148,24) + filete 1 px no topo
│   ├── lv_chip    (8,165) min-w 30, h 18, fundo = cor base
│   └── name       BitmapFontLabel (45,166) glyph 16
└── leader_mark    ColorRect (-4,-4,14,14) rotate 45  #c9a842  <- so no lider
```

**Se sangra pra fora ou precisa ficar por cima da moldura, e filho do CARD.
Todo o resto e filho do FRAME.**

## 2. Tabela de desenho do heroi (espaco FRAME, baseline = 136)

`x = round((148 - w)/2)`, `y = 136 - h`.

| elemento | png nativo | desenho w x h | x | y | escalas inteiras legais |
| --- | --- | --- | --- | --- | --- |
| dragon | 228 x 216 | 114 x 108 | 17 | 28 | x1 (228x216), x2 (456x432) — desenho atual = 1/2 |
| knight | 176 x 232 | 88 x 116 | 30 | 20 | x1, x2 — desenho atual = 1/2 |
| nature | 240 x 232 | 112 x 108 | 18 | 28 | **nao inteiro** (240/112 = 2.14) |
| light | 216 x 224 | 108 x 112 | 20 | 24 | x1, x2 — desenho atual = 1/2 |
| dark | 208 x 216 | 104 x 108 | 22 | 28 | x1, x2 — desenho atual = 1/2 |

> **Contradicao apontada (§10):** `char_nature.png` e 240x232 mas desenha
> 112x108 — nao e divisao inteira. Reexportar a arte em 224x216 resolve
> (= exatamente 2x de 112x108). Ver `CONTRADICOES.md`.

## 3. Estados

| estado | o que muda |
| --- | --- |
| normal | anel interno na cor **base** do elemento |
| lider | + `leader_mark` (losango 14 px dourado no canto sup-dir) + halo `drop-shadow(0 0 8px <lit> 45%)`. **Sem placa "LEADER", sem coroa.** |
| carga < 8 | borda da barra `rgba(201,192,168,.45)`, pips acesos = carga |
| carga = 8 | borda da barra na cor **lit**, barra pulsa (1400 ms), faixa de carga acima (900 ms), botao de skill aparece |
| recebeu carga | flash branco `rgba(244,236,216,.5)` por 400 ms dentro do FRAME |

## 4. Regra de cor

O anel segue **sempre o elemento**, lider incluido. Dourado no card existe
somente no `leader_mark`. (Antes o lider tinha anel dourado — fazia o nature
ler como light.)

## 5. Checklist

- [ ] `FRAME.clip_contents == true`
- [ ] Heroi por `y = 136 - h`, com `h` da tabela (nunca multiplicador)
- [ ] Card do lider com **o mesmo** 152x188 dos outros
- [ ] Anel na cor do elemento nos cinco cards
- [ ] Botao de skill so existe com carga = 8 e consome a carga ao clicar
