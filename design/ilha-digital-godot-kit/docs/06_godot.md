# 06 · Montando no Godot 4

## Projeto
- `display/window/size/viewport_width = 1024`, `viewport_height = 1600`
- `display/window/stretch/mode = canvas_items`, `aspect = keep` (ou `expand` se quiser ocupar telas mais altas)
- Orientação retrato.

## Importação de texturas
- HUD, botões, ícones, película e máscara: **Filter Linear**, **Mipmaps desligado** (são usados em 1:1).
- Cartas @2x, personagens e inimigos (aparecem reduzidos): Filter Linear, **Mipmaps ligado**.
- Se preferir o visual pixel duro nos personagens: Filter Nearest (teste nos dois).

## Fontes
Importe `fonts/*.ttf`. Crie `FontVariation` para os pesos usados:
- InstrumentSans: 700 (nome do jogador, nome do alvo, LV dos chips)
- MartianMono: 400 (rótulos tick), 500, 600 (números)
Ajuste `spacing_glyph` conforme o espaçamento em 03_tema.md (px em 1024).

## Árvore sugerida (nomes = nomes das peças em data/layout)
```
BattleScreen (Control 1024x1600, fundo ColorRect #16130D)
├─ Header            (Control 0,0 1024x132)
│  ├─ Avatar         TextureRect avatar + avatar_frame.png
│  ├─ Player         Label nome / rank, TextureProgressBar xp (xp_bar_under/progress)
│  └─ Sync           sync_dot.png, Label SYNC, TextureButton icon_menu
├─ Strip             NinePatchRect strip_bg.png + 3 células (ícone, Label, Label) + strip_rule.png
├─ Visor             Control 24,232 976x736
│  ├─ Clip           (máscara arredondada, ver abaixo)
│  │  ├─ Background  TextureRect bg_*_visor_976x736.png
│  │  ├─ Stage       Node2D/Control: por slot → Ring (3x TextureProgressBar) + Sprite
│  │  ├─ Scanline    TextureRect visor_film_scanline
│  │  └─ Vignette    TextureRect visor_film_vignette
│  ├─ Frame          visor_frame.png
│  ├─ Corners        visor_corner_tl/tr/bl/br
│  ├─ Sector/Round   Labels
│  ├─ Aim            4 cantoneiras (ou aim_*.png)
│  ├─ Chips          por slot: NinePatchRect chip_*_box + badge + Labels (+ turno)
│  └─ PopupTarget    NinePatchRect popup_target_box + seta + Labels + TextureProgressBar
├─ Team              Label, TextureProgressBar team_hp, Label, TextureButton líder
├─ Bank              cabeçalho (Label, combo, bank_rule, fila) + GridContainer 6x2 de cartas
├─ Nav               4 TextureButton (button_nav_normal / primary) + ícone + Label
└─ Toast             NinePatchRect toast_box_* + Label
```

## Cantos arredondados do visor
Control só recorta em retângulo. Duas opções:
1. `CanvasGroup` no `Clip` com shader que multiplica o alpha por `visor_mask_976x736.png`.
2. Ou `clip_children = CLIP_CHILDREN_ONLY` num `TextureRect` com a própria máscara (Godot 4.1+).

## 9-slice
Use `NinePatchRect` (ou `StyleBoxTexture`) nas texturas de modo **caixa**. Margem = raio do canto + folga da sombra.
O `texture_rect` e o `node` de cada textura estão em `data/components.json`: a diferença entre eles é a folga da sombra de cada lado.

## Barras (TextureProgressBar)
- XP, HP da equipe, vida do pop-up: `fill_mode = LEFT_TO_RIGHT`, `texture_under` = `*_under.png`, `texture_progress` = `*_progress*.png`.
- HP da equipe: use `team_hp_progress.png` (branco) com `tint_progress` pela regra de limiar, ou as versões já coloridas.

## Anel de chão (TextureProgressBar)
- `texture_under` = `ring_<slot>_under.png`, `texture_progress` = `ring_<slot>_progress.png`, `texture_over` = `ring_<slot>_over.png`
- `fill_mode = CLOCKWISE`, `radial_initial_angle = 90`, `radial_fill_degrees = 360`
- `tint_progress` = cor do elemento (aliado) ou `#FF4A3A` (inimigo)
- Posição: use o `texture_rect` do `components.json` (as 3 camadas compartilham o mesmo retângulo).

## Animações que já existem no mockup (para a etapa de animação)

Resumo abaixo. O detalhamento completo — gatilhos, estados, linha do tempo do combo, textos dos avisos e referências quadro a quadro — está em **`07_interacoes_e_animacoes.md`**.

- Mira: opacidade 0.6 ↔ 1.0, 1.4s, ease-in-out, loop
- Ataque iminente (chip, caixa ATQ): opacidade 1 ↔ 0.5, 0.8s, loop
- Pop-up e aviso: entrada com opacidade 0→1 e deslocamento 10px→0 em 0.16–0.18s
- Carta selecionada: sobe 10px em 0.12s
- Barras e anéis: transição do valor em 0.3s
