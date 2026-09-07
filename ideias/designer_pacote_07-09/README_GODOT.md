# Selos de Fragmento — pacote de entrega para o Godot (beta)

Data: **2026-08-31**. Este pacote é a **arte final da beta** da tela de batalha.
Tudo que está no mock HTML está mapeado aqui: medidas, assets, formações e animações.

## Por onde começar (ordem certa)

1. Abra `html/UI Batalha 1bit.dc.html` num navegador — **é a tela de verdade**, com o seletor de
   formação (Boss / 2 / 3 / 5) no rodapé. Compare qualquer dúvida contra ela.
2. Leia `spec/LAYOUT_BATALHA.md` (§0 é a configuração do projeto Godot).
3. Dê ao Codex o arquivo `spec/layout_batalha.json` — ele tem **todos os números** em formato
   legível por máquina, e é a única fonte de posições.
4. Copie os assets (ver mapa de pastas abaixo) e importe com **Filter = Nearest**.
5. Cole os scripts de `godot/` em `res://scripts/` e rode `BattleScreen.gd` numa cena Control vazia.
   Depois use *Scene → Save Branch as Scene* para congelar `BattleScreen.tscn` e seguir editando no editor.
6. Ligue as animações usando `spec/ANIMACOES.md` + `README_VFX.md`.

## Configuração do projeto (Project Settings)

```
Display > Window > Size > Viewport Width      940
Display > Window > Size > Viewport Height     1685
Display > Window > Stretch > Mode             canvas_items
Display > Window > Stretch > Aspect           expand
Display > Window > Handheld > Orientation     portrait
Rendering > Textures > Canvas Textures >
    Default Texture Filter                    Nearest
Rendering > 2D > Snap > Snap 2D Transforms    On
Rendering > 2D > Snap > Snap 2D Vertices      On
```

940×1685 é **exatamente** o design; 1 px do mock = 1 px do viewport. Num 1080×1920 o Godot escala
por 1,139 e o `expand` cobre a sobra com `#080908`. Nada é cortado, nada precisa ser recalculado.

## Mapa de pastas (copie para `res://art/`)

| aqui | vai para | conteúdo |
|---|---|---|
| `ui/` | `res://art/ui/` | cartas, rótulos, fonte bitmap, coração e calha do HP |
| `hex/` | `res://art/hex/` | molduras hexagonais do party (aliado 2×, líder 3×), placas e coroa |
| `char32/` | `res://art/char32/` | sprites `hero_<id>.png` no template 32×40 |
| `seals_1a/` | `res://art/seals_1a/` | moldura 1A dos 5 elementos + charge sheets |
| `enemy/` | `res://art/enemy/` | placa de turno/HP, dígitos, label |
| `char/` | `res://art/char/` | personagens (battle / idle / icon) |
| `godot/` | `res://scripts/` | `battle_layout.gd` e os componentes |
| `html/` | — | referência viva (não vai para o jogo) |
| `reference/` | — | screenshots do mock, para comparar pixel a pixel |

## Documentos

| arquivo | o que resolve |
|---|---|
| `spec/LAYOUT_BATALHA.md` | posições e tamanhos de **toda** a tela, seção por seção (a §5 do party está SUPERSEDIDA por `PARTY_HEX.md`) |
| `spec/PARTY_HEX.md` | **faixa do party hexagonal** (modelo atual) — 182 px, ordem 2-1-2, líder no centro |
| `spec/PERSONAGENS_32x40.md` | template de personagem 32×40: chassi, toucados, armas, paleta, frames |
| `spec/layout_batalha.json` | os mesmos dados, para o Codex ler |
| `spec/FORMACOES.md` | as 4 formações de inimigo com coordenadas |
| `spec/ANIMACOES.md` | as 14 animações com duração, curva e snippet Godot |
| `spec/ASSETS.md` | manifesto: tamanho de origem e escalas legais de cada PNG |
| `README_VFX.md` | VFX procedural: fusão, partículas, balão de dano, impacto por elemento |
| `README_INIMIGO.md` | anatomia da placa de life/turno |
| `README_SELO_QUADRADO.md` | anatomia do selo 1A |
| `README_UI.md` | versão anterior da spec (histórico — onde divergir, **vale o `spec/`**) |

## Regras que não se negociam

1. **Escala inteira.** Todo asset só aparece em múltiplo ou divisor inteiro do tamanho de origem
   (tabela em `spec/ASSETS.md`). Nada de 62×86.
2. **Paleta fechada.** As cores estão em `battle_layout.gd`. Não invente tom novo.
3. **Nada de glow no asset** — glow é runtime (`CanvasModulate`/shader), nunca pintado no PNG.
4. **Sem hover** (é mobile). Press = escala 0,94 + brilho.
5. **A carta do NEXT é a próxima carta real do baralho** e tem exatamente o mesmo desenho das
   outras cartas da BAG.
6. **Números em runtime** saem da fonte bitmap (`BitmapFontLabel.gd`), não de PNGs fixos.

## Mudanças de 01/09/2026

1. **Party hexagonal** substitui os 5 selos quadrados na batalha (faixa 222 → 182 px; o palco herda 40 px).
   Ordem 2-1-2 com o **líder no centro**: hex maior (3×), moldura dourada, coroa e medidor com borda de ouro.
   Detalhes em `spec/PARTY_HEX.md`.
2. **Personagens chibi 32×40** (`char32/`) — template documentado em `spec/PERSONAGENS_32x40.md`.
   O inimigo usa o mesmo sprite espelhado com paleta mais fria; hexágono nunca em inimigo.
3. **Mão** passou a ter 2 fileiras de 6 slots (5 cartas + o 6º vago, que recebe a carta descendo do NEXT).
4. **Life** redesenhado na técnica das cartas: coração pixel com contorno em tinta, campo pontilhado
   `hp_tile_field.png` e preenchimento `hp_tile_fill.png` (unidade de 3 px, paleta das cartas).
5. Cartas **light / dark / wild** na versão v3 (sol radiante, eclipse sem caveira, anel dos 5 elementos).

## O que ainda falta (não está no pacote)

- Arte de cenário do palco (888×558) — hoje é um slot vazio no mock.
- Sprites dos inimigos por formação.
- Telas fora da batalha (menu, montagem de time, resultado, loja).
