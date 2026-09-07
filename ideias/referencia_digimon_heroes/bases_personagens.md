# Bases para criar personagens de 1 Bit Heroes

Regra derivada da coleção do Digimon Heroes (`colecao_cartas.json`, 987 unidades).
Copiamos a **forma** (proporções, escada de geração, peso das skills), não os
números — a economia de HP da nossa alpha é ~10× menor de propósito.

---

## 1. Orçamento de stats por geração (referência)

Soma média `atk + def + hp + support` de cada geração:

| geração | orçamento total | atk | def | hp | sup | max_lv |
|---|---:|---:|---:|---:|---:|---:|
| Child | ~310 | 79 | 72 | 85 | 74 | 22 |
| Adult | ~432 | 120 | 105 | 114 | 93 | 36 |
| Perfect | ~535 | 145 | 134 | 139 | 117 | 51 |
| Ultimate | ~603 | 163 | 148 | 163 | 129 | 58 |

Cada degrau ≈ **× 1,25–1,4** sobre o anterior. Proporção estável em toda a base:
**atk ~27% · def ~25% · hp ~27% · sup ~21%** (varia ±3 pts por elemento; Holy
pende pra sup, Dragon/Dark pra atk).

## 2. Orçamento da nossa alpha (escala do jogo)

O nosso HP de inimigo é 8–16 e o de aliado 12–16. Mantendo isso, um **aliado
alpha** = "Child" na régua da referência, com orçamento **~26** em 3 stats
(dobramos `hp`, sem `support` por ora — ver §5):

```
orcamento_aliado_alpha = 26   (atk + def + hp_peso)
hp_real = hp_peso * 2          (o HP compartilhado soma os 5 -> 60~80)
```

Split por papel (mesma proporção da referência, arredondada):

| papel | atk | def | hp_peso | hp_real | exemplo no lineup |
|---|---:|---:|---:|---:|---|
| atacante | 8 | 3 | 7 | 14 | Draco de Brasa |
| tanque | 5 | 6 | 8 | 16 | Guardião de Ferro |
| equilibrado | 6 | 4 | 7 | 14 | Maga do Bosque / Cleriga |
| frágil-ofensivo | 7 | 3 | 6 | 12 | (2º dragão futuro) |

> O lineup atual (`Unidades.ALIADOS`: ataque 7/5/6/4/6, defesa 3/5/3/4/3,
> hp_max 14/14/12/14/16) já está **dentro** dessa régua. Só a Cleriga (ataque 4)
> está abaixo — de propósito, é a curandeira.

## 3. Inimigos

Na referência os inimigos comuns são Child/Adult com orçamento **igual ou até
maior** que os aliados (a dificuldade vem da quantidade e das skills, não de
stats inflados). Nossa alpha:

| tipo | orçamento (atk+def+hp) | HP | nota |
|---|---:|---:|---|
| comum (trio) | ~22 | 8–10 | um pouco abaixo do aliado |
| elite (dupla) | ~28 | 12–14 | acima; skill própria |
| boss | ~40 + HP×3 | 30+ | `BOSS_MULT` já faz isso |

`Unidades.INIMIGOS` hoje: ataque 12–15, defesa 8–16, hp 8–10. O **ataque** está
alto vs. o aliado (12–15 contra 4–7) — mas passa pela redução por defesa média e
pela cadência de 3 correntes, então o resultado bate (30/30 vitórias no teste).

## 4. Passo de nível / evolução

Régua da referência: cada geração ≈ **×1,3**. Para a alpha, um aliado que "sobe
de tier" multiplica o orçamento por ~1,3 e ganho de `max_lv`:

```
tier 1 (alpha)  orcamento 26   nivel max 20
tier 2          orcamento 34   nivel max 40
tier 3          orcamento 44   nivel max 60
```

Dentro de um tier, subir de nível dá ganho linear pequeno (a referência tem
`max_lv` 10–70; o stat mostrado é o do nível máximo).

## 5. O 4º stat (Support) — decidir

A referência tem `atk/def/hp/**support**` (sup ~21% do orçamento). É o
multiplicador de **cura e força de skill**. Duas opções:

- **(a) não adotar** (estado atual): cura/skill escala só pelo valor das cartas +
  constante. Mais simples.
- **(b) adotar `suporte`**: `Unidades.ALIADOS` ganha o campo; `Cleriga` e skills
  de cura/buff multiplicam por ele. Fica mais fiel e dá um eixo de build a mais.

## 6. Cooldown de skill por peso (da análise de `colecao_cartas`)

| peso | turnos ref. | famílias |
|---|---:|---|
| leve | 4–6 | +valor de carta (Evolution), cura pequena, absorção pequena |
| médio | 8–10 | cura média, escudo 25%, delay pequeno, All Nine, debuff |
| pesado | 14–16 | dano concentrado, AoE grande, escudo 75%, delay grande |
| muito pesado | 18–21 | AoE máximo, skill boost grande |

Na alpha tudo carrega em **8 pips**; o peso acima é a intenção pra canonização.

---

## Arquivos desta pasta

- `colecao_cartas.csv` / `.json` — os 987 Digimons, um por linha, todos os campos.
- `gameplay_digimon_heroes.md` — mecânicas + estatísticas agregadas.
- `bases_personagens.md` — este arquivo (a regra).
- `../skill_list.lua` / `../skill_list_plano.md` — as 150 skills + recorte da alpha.
