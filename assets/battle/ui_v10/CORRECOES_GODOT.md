# Correções — build do Godot × mock (01/09/2026)

Comparação: `reference/tela_completa.png` (mock, fonte da verdade) × print do build enviado pelo Diógenes.
O que está no build hoje é **outro conjunto de assets** (`assets/battle/ui_v9`), não o pacote deste export.
Regra geral para o Codex: **use os PNGs de `export_godot/` e os números de `spec/layout_batalha.json`.
Nada de redesenhar em código o que já é asset.**

| # | o que está errado no build | como tem que ficar | onde |
|---|---|---|---|
| 1 | Escala geral: a tela do build não é 940×1685 e as seções não batem | viewport base **940×1685**, `canvas_items` + `expand`, Nearest | README_GODOT.md §Configuração |
| 2 | Alturas das seções fora do lugar (palco curto, faixas coladas) | y/altura exatos da tabela de 8 seções | spec/LAYOUT_BATALHA.md §1 |
| 3 | Placa de inimigo desenhada em código (quadradinho + "3 TURN" + barra vermelha solta) | usar `enemy_turn_plate_<el>` + dígito do atlas + `enemy_label_turn` + `enemy_hp_well` + `enemy_hp_fill`, tudo em k=6 (boss/dupla) ou k=4 (trio/5) | spec/LAYOUT_BATALHA.md §4 · godot/EnemyPlate.gd |
| 4 | Inimigos posicionados à mão | coordenadas das 4 formações (cx, y) | spec/FORMACOES.md |
| 5 | Selos do party com moldura e barra diferentes | `seals_1a/seal_1a_<el>_empty.png` a 165×165 + quadro do charge sheet; foto na janela 129×99 em (18,15) | spec/LAYOUT_BATALHA.md §5 · godot/PartySeal.gd |
| 6 | Cartas da BAG e da mão são molduras genéricas com ícone | usar `ui/card_face_<el>_v1.png` (light/dark/wild = **v3**); BAG 78×108, HAND revisada 138×191 | contrato revisado da HAND |
| 7 | Barra de conta: XP fino demais, LV e contadores sem largura reservada | XP 214×13; reservas moeda 82 / gema 68 / energia 86 | spec/LAYOUT_BATALHA.md §2 |
| 8 | Life do herói sem a calha e sem o rótulo na proporção certa | calha h22, borda 1px `rgba(201,192,168,.55)`, fundo `#121211`, padding 3, fill **`#c04a3e` sólido**, valor à direita | spec/LAYOUT_BATALHA.md §8 |
| 9 | Cores mais quentes/claras que a paleta | paleta fechada em `godot/battle_layout.gd` | — |
| 10 | Pixel borrado | `Default Texture Filter = Nearest` no projeto **e** `texture_filter` nos nós que escalam | README_GODOT.md |
| 11 | Animações ausentes | as 14 do contrato, com duração e curva | spec/ANIMACOES.md |

## Regra nova da mão e do NEXT (pedido de 01/09)

- A HAND tem **2 fileiras de 6 slots**: cinco cartas iniciais e uma ENTRADA vazia em cada fileira.
- Cada slot mede **138×191**, com gap de **10 px** e berço pontilhado permanente.
- Quando uma carta é consumida, a reposição **desce do NEXT**: BAG → NEXT → slot vago da fileira.
  O NEXT então puxa o próximo item real da BAG (a carta do NEXT é sempre o próximo do baralho).
- Animação: 180 ms, cubic-out, translada do NEXT até o slot; a fila da BAG desliza 1 posição.

> A confirmar: se as duas fileiras se reabastecem em paralelo (uma carta do NEXT por fileira)
> ou se é uma reposição de cada vez, na ordem em que os slots vagam.

## Ordem sugerida de correção
1. Project settings (item 1 e 10) — sem isso nada mais encaixa.
2. Pilha vertical das 8 seções (item 2).
3. Trocar os assets: cartas, selos, placas (itens 3, 5, 6).
4. Formações (item 4).
5. HUD: conta, XP, life (itens 7, 8, 9).
6. Animações (item 11) e a regra do NEXT.
