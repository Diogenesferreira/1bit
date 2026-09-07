# Selo de Fragmento QUADRADO (modelo 1A · barra na base)

Escolhido para o jogo. Mesma regra do selo redondo — trocar é só apontar as texturas.

## Regra de pixel
- Canvas **330×330 RGBA**, grade lógica **55×55**, **1 px lógico = 6 px** de textura.
- Escalas seguras no Godot: `1.0`, `0.5`, `2.0`. **Nunca fracionária** (serrilha).
- Import de textura: **Filter = Nearest**, Mipmaps **off**, Fix Alpha Border **on**.

## Anatomia (px de textura, origem no topo-esquerdo)
| peça | posição | tamanho |
| --- | --- | --- |
| abertura do personagem (transparente) | x 36, y 30 | **258 × 198** |
| calha da barra de skill | x 30, y 240 | 270 × 54 |
| socket do elemento (gema) | x 42, y 246 | 30 × 30 |
| encaixe 1 (dos 8) | x 84, y 252 | 18 × 24 |
| passo entre encaixes | +24 px em x | — |
| rebites dos cantos | 18,18 · 294,18 · 18,294 · 294,294 | 12 × 12 |

Ordem de leitura da carga: **esquerda → direita**, 8 encaixes = skill pronta.

## Arquivos
```
frames_square/
  seal_sq_<el>_empty_v1.png    330×330  moldura com encaixes apagados
  seal_sq_<el>_full_v1.png     330×330  referência 8/8 (só para arte/preview)
charge_sheets_square/
  seal_sq_<el>_charge_sheet_v1.png  330×2970  9 quadros verticais (0…8 encaixes)
godot/FragmentSealSquare.gd
html/Selos Quadrados.dc.html   página interativa (as duas leituras + área útil)
```
`<el>` = `dragon | knight | nature | light | dark`
Cores dos sockets: dragon `#a8443a`, knight `#5a86a8`, nature `#7d9455`, light `#c9a842`, dark `#7a5f9a`.

## Montagem das camadas (de baixo para cima)
1. `Portrait` — Sprite2D do personagem, **recortado pela abertura** (use um `Control` com `clip_contents` ou uma máscara 258×198 em x36/y30).
2. `FrameEmpty` — Sprite2D de `seal_sq_<el>_empty_v1.png`.
3. `Charge` — Sprite2D da folha com `region_enabled = true` e `region_rect = Rect2(0, carga*330, 330, 330)`.
4. `Glow` (opcional) — cópia do quadro 8 em `CanvasItem.blend_mode = Add`, alpha pulsando.

## Animações
| estado | duração | o que acontece |
| --- | --- | --- |
| ganhar encaixe | 120 ms | `region_rect.position.y` salta um quadro (sem tween — é sprite) + flash de 60 ms no encaixe |
| pronta (8/8) | 1300 ms em loop | quadro 8 em `Add` variando alpha 0 → .8 → 0 + halo (`modulate` ou `Light2D`) na cor do elemento |
| gastar skill | 180 ms | volta ao quadro 0 com 2 flashes de 60 ms |
| dano recebido | 260 ms | tremor de ±2 px lógicos (±12 px) em seno de 26 ms |

Halo = a cor do elemento; nada de branco puro (quebra a paleta 1-bit).

## Uso
```gdscript
var seal := FragmentSealSquare.new()  # ou instancie a cena
seal.element = "nature"
seal.set_portrait(load("res://char/char_0003_nature_battle_v1.png"))
seal.add_charge()      # +1 encaixe
seal.charge = 8        # pronta -> dispara o pulso
seal.spend()           # volta a 0
```
