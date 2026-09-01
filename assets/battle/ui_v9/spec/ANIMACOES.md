# Animações — contrato de movimento (v2)

Todas as durações em ms. Curvas Godot: `TRANS_CUBIC/EASE_OUT` para o que desacelera,
`TRANS_BACK/EASE_OUT` para o "pop", `TRANS_SINE` para loops. **Sempre** `round()` na posição final
e filtro Nearest. Detalhe procedural completo do VFX de fusão/impacto: `../README_VFX.md`.

| # | animação | duração | curva | alvo |
|---|---|---|---|---|
| 1 | toque em qualquer botão/carta | 120 | ease-snap | escala 0,94 + brilho +8% |
| 2 | seleção de carta na mão | 120 | cubic-out | sobe 9 px + contorno 2 px na cor do elemento |
| 3 | carta sai da BAG → mão | 180 | cubic-out | translada; a fila desliza 1 posição; NEXT recarrega |
| 4 | **fusão das 3 cartas** | 0–1360 | ver tabela abaixo | cartas → ponto de fusão → estouro |
| 5 | **energia viajando até o elemento (selo)** | 1020–1980 | bézier quadrática | 48 partículas de 2–3 px |
| 6 | **encher a barra de kill (arco do selo)** | 200 por encaixe | cubic-out | 1 encaixe a cada 6 partículas (0→8) |
| 7 | selo cheio (8/8) | loop 900–1300 | sine | halo pulsante na cor do elemento |
| 8 | **balão da soma de dano** | pop 130 por incremento | back-out | escala 1,28 → 1,00; +7 de dano por partícula |
| 9 | **dano no inimigo** | 900 total | ver abaixo | clarão + tremor + dreno + numeral |
| 10 | **numeral de dano subindo** | 520 | cubic-out | sobe 16 px, escala 1,12 → 1,0, fade nos últimos 30% |
| 11 | dreno da barra de HP (inimigo e herói) | 420 | cubic-out | largura do fill |
| 12 | barra de XP / energia | 200 | cubic-out | largura do fill |
| 13 | avanço de turno / nó do STAGE | 420 | cubic-out | dígito troca com pop 1,15; nó anterior vira "feito" |
| 14 | inimigo derrotado | 300 | linear | greyscale 45% + fade 0 |

## 4. Fusão das 3 cartas (canvas de referência 300×180, 3×)

| fase | ms | o que acontece |
|---|---|---|
| alinhar | 0–420 | as 3 cartas escolhidas deslizam para o centro, lado a lado (x 118/150/182, y 132) |
| convergir | 420–820 | as 3 se sobrepõem no ponto (150, 150) |
| clarão | 820–1020 | quadrado bone 32×32 sobre o ponto, alpha 1 → 0 |
| estouro | 820–1360 | anel de 26 quadrados, raio 6 → 60, tamanho 3 → 1 px, alpha 1 → 0 |
| viagem | 1020–1980 | 48 partículas sobem até o centro do selo alvo |
| carga | conforme chegada | 1 encaixe do arco a cada 6 partículas |

Partícula: `delay` 0–420, `duração` 520–780, controle da bézier = meio do caminho + (spread×46, −0..26),
rastro de 3 amostras (offsets −0,07 e −0,14; alpha 0,5; cor bone). Cor = cor do elemento fundido.

## 9. Impacto no inimigo (900 ms)

| efeito | ms | detalhe |
|---|---|---|
| clarão | 0–90 | retângulo bone sobre o sprite, alpha 1 → 0 |
| tremor | 0–260 | ±2 px, seno de período 26 ms |
| dreno do HP | 0–420 | ease-out na largura do `enemy_hp_fill` |
| numeral | 0–520 | sobe 16 px; dígitos do `enemy_digits_sheet`; sombra `#201f1d` |

VFX por elemento (fogo/aço/natureza/luz/trevas): descrição procedural em `../README_VFX.md` §3.

## Snippets Godot 4

```gdscript
# 10 — numeral de dano subindo
func pop_damage(parent: Node2D, at: Vector2, amount: int, color: Color) -> void:
    var n := preload("res://ui/DamagePopup.tscn").instantiate()
    n.position = at.round()
    n.set_value(amount, color)
    parent.add_child(n)
    var t := n.create_tween().set_parallel()
    t.tween_property(n, "position:y", n.position.y - 16.0, 0.52)\
        .set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
    t.tween_property(n, "scale", Vector2.ONE, 0.12).from(Vector2(1.12, 1.12))
    t.chain().tween_property(n, "modulate:a", 0.0, 0.16)
    t.chain().tween_callback(n.queue_free)

# 11 — dreno de HP (o fill é recortado por um Control com clip_contents)
func drain_hp(clip: Control, plate_w: float, ratio: float) -> void:
    clip.create_tween().tween_property(clip, "custom_minimum_size:x", round(plate_w * ratio), 0.42)\
        .set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

# 6 — encher o arco do selo (1 encaixe por vez)
func charge_seal(seal: TextureRect, from_step: int, to_step: int) -> void:
    var t := seal.create_tween()
    for step in range(from_step + 1, to_step + 1):
        t.tween_callback(seal.set_charge.bind(step))   # troca a região do AtlasTexture
        t.tween_interval(0.20)
```
