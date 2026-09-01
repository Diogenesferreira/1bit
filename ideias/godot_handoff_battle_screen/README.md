# Handoff: Battle Screen (1-bit card-fusion game)

## Visão geral
Tela de batalha de um jogo mobile estilo 1-bit: 5 aliados vs até 4 inimigos, um "bag" de cartas que abastece 10 slots de campo, e uma "fusion lane" de 3 slots onde 3 cartas do mesmo elemento se fundem num ataque.

## Sobre os arquivos deste pacote
Os arquivos em `design_reference/` são **referências de design feitas em HTML** (protótipo), não código para copiar. Use-os (e o `scene_data.json`) como especificação para recriar a tela nativamente no Godot (Control nodes / TextureRect / AnimationPlayer / GDScript).

## Fidelidade
**Alta fidelidade**: cores, posições, tamanhos e animações abaixo são os valores finais aprovados. Recrie pixel a pixel.

## Resolução e escala
Canvas de design: **1152×2048** (retrato). No Godot:
- `Project Settings > Display > Window`: `stretch mode = canvas_items`, `aspect = keep`, viewport base size `1152x2048`.
- Todas as coordenadas em `scene_data.json` são em px desse canvas — use como `position`/`size` de `Control`/`TextureRect` nodes (ou converta para `anchor + offset`).

## Árvore de cena sugerida
```
BattleScreen (Control, 1152x2048)
├─ BackgroundArt (TextureRect: map_fullscreen.png, full rect)
├─ ArenaLayer (Control, pos 43,126 size 1065x1023, clip_contents = true)
│   ├─ Enemies (Node2D/Control)
│   │   └─ EnemyUnit.tscn ×4  (sprite + Lv label + heart icon + hp number)
│   └─ Allies (Node2D/Control)
│       └─ AllyUnit.tscn ×5  (sprite + Lv label + element badge + skill/hp bar)
├─ DarkOverlay (TextureRect: layout_dark_overlay.png, full rect)
├─ FrameArt (TextureRect ×7: screen_outer_frame, arena_frame, bag_frame, next_frame,
│            fusion_lane_frame, affinity_elemental_frame, affinity_light_dark_frame)
├─ Labels (TextureRect ×4: label_bag, label_next, label_fusion_lane, label_affinity)
├─ BagRow (Control)
│   ├─ BagSlot.tscn ×7 (frame + card icon, idle wiggle)
│   └─ NextSlot (frame + preview icon, no click)
├─ FieldGrid (Control, 2×5)
│   └─ FieldSlot.tscn ×10 (frame + card icon, clickable, idle wiggle)
├─ FusionLane (Control)
│   └─ LaneSlot.tscn ×3 (frame + card icon, success/fail animation)
├─ AffinityChart (Control) — static icons + arrows, no logic
├─ TopHud (Control) — floor/score/round pips/gems/coins/menu
└─ BottomHud (Control) — player heart/hp bar/energy
```

Each `EnemyUnit`/`AllyUnit`/`BagSlot`/`FieldSlot`/`LaneSlot` should be its own scene (`.tscn`) with a small script, matching the "component" boundaries above — this maps directly to how Unity would use prefabs instead.

## Cores (paleta 1-bit)
- Fundo escuro / bordas: `#1a1d24`
- Branco (UI, texto sobre escuro, traços de sprite): `#ffffff`
- Texto sobre a arena clara: `#1a1d24`
- **Sem gradientes, sem cinzas intermediários** — tudo é preto-azulado ou branco.

## Fonte
"Press Start 2P" (Google Fonts). Baixe o `.ttf` e importe como `DynamicFontData` no Godot; tamanhos usados: 17–20px neste canvas.

## Ícones brancos invertidos
Os ícones de elemento/carta são traços **brancos** sobre fundo transparente. Sobre o chão claro da arena, o protótipo aplica `filter: invert(1)` em CSS. No Godot, gere uma **segunda versão já invertida** de cada ícone (ou use um `CanvasItemMaterial`/shader simples que inverte RGB mantendo alpha) para não depender de filtro em runtime.

## Especificação completa
Todas as posições, tamanhos, regras de HUD por unidade, animações (nomes, duração, curva) e a lógica de gameplay (bag FIFO, fusão, dano, energia, rounds) estão detalhadas em **`scene_data.json`** — é a fonte da verdade numérica, escrita para ser parseada por script se quiser gerar a cena programaticamente.

## Interações e comportamento
- **Bag → Field**: início de batalha preenche os 10 slots de campo puxando do bag (FIFO); cada saque real oa bag remove o primeiro item e empurra um tipo aleatório no fim.
- **Field → Fusion Lane**: tocar num card do campo (só quando há espaço na lane e `energy > 0`) move o card para a lane e gasta 1 energia; o slot do campo vazio saca um novo card do bag após ~220ms.
- **Avaliação da fusão**: quando os 3 slots da lane enchem, compara os tipos:
  - Iguais → sucesso: flash de inversão de cor na tela, dano num inimigo vivo aleatório, +25 score, +25 gems, +1 energia (até o máx).
  - Diferentes → falha: shake horizontal, sem recompensa.
  - Lane limpa em seguida (~460ms depois).
- **Dano**: `fusionDamage` (padrão 2) subtrai do hp do inimigo alvo; sprite e barra do inimigo piscam invertido por 220ms.
- **Elementos**: dragon / knight / nature / light / dark — cada aliado e inimigo tem um elemento fixo (ver `scene_data.json`); é a base para a mecânica futura de vantagem elemental (ver `affinity_chain`).

## Assets
Todos os PNGs usados estão em `assets/` (sprites de personagens, molduras de slot, ícones de carta/elemento, labels, barras de vida, moedas). Nomes de arquivo mantidos idênticos aos do protótipo — reaproveite direto como `Texture2D` no Godot.

## Arquivos deste pacote
- `scene_data.json` — especificação numérica completa (posições, cores, animações, regras).
- `design_reference/Battle Screen.dc.html` + `support.js` — protótipo HTML de referência visual/interativo (abra num navegador).
- `assets/` — todos os sprites, ícones e molduras em PNG.
