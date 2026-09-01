# MECÂNICA DE CARTAS - EXPLICAÇÃO COMPLETA

## ÍNDICE
1. [Visão Geral](#visão-geral)
2. [Anatomy da Tela](#anatomy-da-tela)
3. [O Combo Explicado](#o-combo-explicado)
4. [O Bag Explicado](#o-bag-explicado)
5. [O Fluxo de Uma Partida](#o-fluxo-de-uma-partida)
6. [Regras Especiais](#regras-especiais)

---

## VISÃO GERAL

O sistema de cartas é o **coração** do Digimon Heroes. Não é um RPG tradicional onde você aprota um menu e escolhe um ataque. Aqui:

- **O jogador toca 3 cartas** em um grid 2×5 (10 cartas visíveis).
- **Essas 3 cartas devem ser do mesmo tipo** (mesma cor) ou conter um coringa.
- **Ao fechar um trio**, o aliado daquela cor **ataca automaticamente**.
- **As cartas desaparecem**, e novas cartas **descem de um saco infinito** (o Bag).
- **Se virar outro trio automaticamente**, acontece uma **cascata** (chain).
- **O objetivo é criar cascatas** — quanto mais combos em fileira, maior o dano total.

**Por que isso é bom?** Combina skill + sorte. O jogador não tem controle absoluto (não sabe qual carta vem), mas tem que planejar o que faz com o que tem. É puzzle + ação.

---

## ANATOMY DA TELA

```
┌─────────────────────────────────────────────────────────────────────┐
│                      INIMIGO (TOPO - bg_ue)                         │
│                 [Retrato] | HP: 3200 ♥ | ATK: 88 | DEF: 30         │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│          FILEIRA TOPO (5 cartas)                    FILA DO BAG →   │
│     ┌──────┬──────┬──────┬──────┬──────┐            ┌──────┐       │
│     │ 🟥 5 │ 🟦 3 │ 🟩 7 │ 🟨 4 │ 🟪 9 │            │ 🟩 6 │       │
│     ├──────┼──────┼──────┼──────┼──────┤            ├──────┤       │
│     │      │ ·   │      │      │      │     ◀─     │ 🟪 2 │       │
│     └──────┴──────┴──────┴──────┴──────┘            ├──────┤       │
│                                                      │ 🟥 8 │       │
│          FILEIRA BAIXO (5 cartas)                   ├──────┤       │
│     ┌──────┬──────┬──────┬──────┬──────┐            │ 🟦 1 │       │
│     │ 🟥 6 │ 🟪 3 │ 🟩 2 │ 🟨 8 │ 🟦 5 │            ├──────┤       │
│     ├──────┼──────┼──────┼──────┼──────┤            │ 🟨 9 │       │
│     │      │      │      │      │      │     ◀─     │ (seg)│       │
│     └──────┴──────┴──────┴──────┴──────┘            └──────┘       │
│                                                                      │
├─────────────────────────────────────────────────────────────────────┤
│  ALIADOS (MEDALHÕES)                                                │
│  🔴Agumon (HP:70)  🔵Gabumon (HP:68)  🟢Palmon (HP:72)             │
│  🟡Patamon (HP:60) 🟣Impmon (HP:65)                                │
│                                                                      │
│  [↩ Desfazer] [✕ Sair]                 CASCATA: 1x                 │
└─────────────────────────────────────────────────────────────────────┘
```

### As 3 Regiões Principais:

#### 1. **A MÃO (Centro-Esquerda)**
- **10 cartas em 2×5 grid**.
- É o **tabuleiro do jogador** onde ele toca para selecionar trios.
- Cartas têm:
  - **Cor de fundo** (identifica o tipo).
  - **Número grande** (valor 1–9).
  - **Brilho/Destaque** quando selecionada.

#### 2. **A FILA DO BAG (Direita)**
- **5 cartas visíveis** que vão descer para preencher a mão.
- Renderizadas como um **leque visual** inclinado/rotacionado.
- **Ordem fixa**: a primeira sai quando a mão pede refill, a segunda sobe, etc.
- **Propósito:** O jogador consegue **planejar futuros trios** vendo o que vem.
- Exemplo: "Vejo que vai vir um Vermelho em breve, vou guardar 2 Vermelhos na mão."

#### 3. **OS ALIADOS (Rodapé)**
- **5 medalhões** (um por cor).
- Cada um mostra:
  - Retrato do Digimon.
  - HP restante (alguns têm barra visual).
  - **Acúmulo de dano da cor** (para calcular o próximo ataque).
- **Não é interativo** — o jogador não escolhe qual aliado ataca, a cor determina.

---

## O COMBO EXPLICADO

### O Que É Um Combo?

Um **combo** (ou **trio**) é o ato de tocar **3 cartas válidas** para fazer um aliado atacar.

### Passo a Passo de Um Combo

#### **Passo 1: O Jogador Toca 3 Cartas**

```
Mão atual:
┌──────┬──────┬──────┬──────┬──────┐
│ 🟥 5 │ 🟦 3 │ 🟩 7 │ 🟨 4 │ 🟪 9 │  (Fileira TOPO)
└──────┴──────┴──────┴──────┴──────┘
┌──────┬──────┬──────┬──────┬──────┐
│ 🟥 6 │ 🟪 3 │ 🟩 2 │ 🟨 8 │ 🟦 5 │  (Fileira BAIXO)
└──────┴──────┴──────┴──────┴──────┘

Jogador toca: [🟥 5 (topo)]  →  [🟥 6 (baixo)]  →  [🟦 3 (topo)]

❌ Inválido! (2 Vermelho, 1 Azul — cores diferentes)

Tenta novamente: [🟥 5]  →  [🟥 6]  →  [🟦 5]... ainda inválido.

Tenta: [🟥 5]  →  [🟥 6]  →  [Fila do Bag: 🟥 8]

✅ VÁLIDO! (3 Vermelho)
```

#### **Passo 2: Validação**

O sistema verifica:
- São 3 cartas?
- Mesma cor (ou contém coringa)?
- Podem ser 2 da mão + 1 do topo do Bag?

#### **Passo 3: Animação do Trio**

```
As 3 cartas se LEVANTAM e vão ao CENTRO da tela (animação 0.3s):

    ┌──────┐
    │ 🟥 5 │
    │ 🟥 6 │  ◀─  AMARELAS (destaque)
    │ 🟥 8 │
    └──────┘

Som: "POP!" (efeito de sucesso)
```

#### **Passo 4: O Aliado Ataca**

```
Fórmula de dano:
  dano_base = Agumon.ATK (38) + (5 + 6 + 8) / 3 = 38 + 6.3 ≈ 44
  
  dano_final = 44 - inimigo.defesa (30) = 14

Verificar crítico:
  - Valores iguais? NÃO (5, 6, 8 são diferentes)
  - Tem coringa? NÃO
  → SEM CRÍTICO
  
Aplicar dano:
  inimigo.hp -= 14  (3200 → 3186)
  
Medalhão Vermelho acumula: +14 (para mostrar visualmente)
Som: "CRASH!" (ataque)
```

#### **Passo 5: As Cartas Desaparecem**

```
Fade-out das 3 cartas (0.2s):

┌──────┬──────┬──────┬──────┬──────┐
│      │ 🟦 3 │ 🟩 7 │ 🟨 4 │ 🟪 9 │  ◀─ Ficaram 2 cartas na TOPO
└──────┴──────┴──────┴──────┴──────┘
┌──────┬──────┬──────┬──────┬──────┐
│ 🟪 3 │ 🟩 2 │ 🟨 8 │ 🟦 5 │      │  ◀─ Ficaram 4 cartas na BAIXO
└──────┴──────┴──────┴──────┴──────┘
```

#### **Passo 6: Buracos e Queda**

```
Cartas acima dos buracos CAEM (animação 0.3s ease-out):

Antes:                          Depois:
┌──────┬──────┬──────┬─────┬────── ┌──────┬──────┬──────┬──────┬──────┐
│      │ 🟦 3 │ 🟩 7 │🟨 4 │🟪 9    │🟦 3  │🟩 7  │🟨 4  │🟪 9  │      │
└──────┴──────┴──────┴─────┴────── └──────┴──────┴──────┴──────┴──────┘
┌──────┬──────┬──────┬──────┬──────┐ (espaço para nova carta)
│🟪 3  │🟩 2  │🟨 8  │🟦 5  │      │ (nada muda na fileira BAIXO)
└──────┴──────┴──────┴──────┴──────┘
```

#### **Passo 7: Refill do Bag (CRÍTICO!)**

Aqui é onde a **fila à direita da tela** entra em ação:

```
FILA DO BAG (estado anterior):          MÃO (precisa de 3 novas cartas)
┌──────┐
│ 🟩 6 │  ◀─ Próxima a descer          ┌──────┬──────┬──────┬──────┬──────┐
├──────┤                               │🟦 3  │🟩 7  │🟨 4  │🟪 9  │ ?    │
│ 🟪 2 │                               ├──────┼──────┼──────┼──────┼──────┤
├──────┤                               │🟪 3  │🟩 2  │🟨 8  │🟦 5  │ ?    │
│ 🟥 8 │                               └──────┴──────┴──────┴──────┴──────┘
├──────┤
│ 🟦 1 │                               (As 2 posições livres precisam de:
├──────┤                                1 carta da TOPO  +  1 carta da BAIXO)
│ 🟨 9 │
├──────┤
│ ? ?  │  ◀─ Será calculada de novo pelo Bag
└──────┘
        (as outras 4 já vêm de cima)

PROCESSO:
1. As 3 cartas da fila descem:
   🟩 6 → preenche a TOPO (posição 4)
   🟪 2 → preenche a BAIXO (posição 4)
   🟥 8 → preenche a ??? (qual fileira?)
   
   ⚠️  AGUARDE! Só 3 cartas chegaram, mas havia 3 buracos. Uma foi do Bag?
   
   NÃO, espera. O Bag fornece:
   - 1 carta quando a TOPO pede refill (1 buraco)
   - 1 carta quando a BAIXO pede refill (1 buraco)
   
   Total: 2 novas cartas de fora por combo.
   
2. Simulação real:
   
   Antes do combo:          Depois do combo:        Depois do refill:
   
   TOPO:                    TOPO:                   TOPO:
   🟥 5 🟦 3 🟩 7 🟨 4 🟪 9   ✖  🟦 3 🟩 7 🟨 4 🟪 9   🟦 3 🟩 7 🟨 4 🟪 9 🟩 6
   
   BAIXO:                   BAIXO:                  BAIXO:
   🟥 6 🟪 3 🟩 2 🟨 8 🟦 5   ✖ ✖  🟪 3 🟩 2 🟨 8 🟦 5  🟪 3 🟩 2 🟨 8 🟦 5 🟪 2
   
   Buracos: 3               Refill: 2 do Bag
   
3. A fila original {🟩 6, 🟪 2, 🟥 8, 🟦 1, 🟨 9} perde os 2 primeiros:
   {🟥 8, 🟦 1, 🟨 9, ???, ???}
   
   Bag gera 2 novas cartas pseudo-aleatoriamente (respeitando garantias):
   Ex: 🟥 3, 🟨 5
   
   Nova fila: {🟥 8, 🟦 1, 🟨 9, 🟥 3, 🟨 5}
```

#### **Passo 8: Testar Cascata**

Após refill, sistema **testa automaticamente**:

```
Há novo trio na mão (sem o jogador tocar)?

Mão atual:
┌──────┬──────┬──────┬──────┬──────┐
│ 🟦 3 │ 🟩 7 │ 🟨 4 │ 🟪 9 │ 🟩 6 │
└──────┴──────┴──────┴──────┴──────┘
┌──────┬──────┬──────┬──────┬──────┐
│ 🟪 3 │ 🟩 2 │ 🟨 8 │ 🟦 5 │ 🟪 2 │
└──────┴──────┴──────┴──────┴──────┘

Trios possíveis:
- 3 Verde? 🟩 7 (topo) + 🟩 2 (baixo) + 🟩 6 (topo) = ✅ SIM
- 3 Roxo? 🟪 9 (topo) + 🟪 3 (baixo) + 🟪 2 (baixo) = ✅ SIM

Qual escolher? ➜ VER SEÇÃO "REGRAS DE CASCATA"
   
   A regra diz: escolha a cor com MENOS quantidade na mão (destock).
   - Verde: 3 cartas totais (7, 2, 6)
   - Roxo: 3 cartas totais (9, 3, 2)
   
   Empate! Vai para o próximo critério...
   
   ➜ Escolhe a cor que sobra MENOS órfã após o combo.
   ➜ Ou segue ordem de preferência: VERM > AZUL > VERDE > AMAR > ROXO.
   
Resultado: Escolhe VERDE (ou ROXO, depende da lógica de desempate).

Cascata se ativa! Contador vai: 1x → 2x
Dano do próximo ataque × 2
Volta ao Passo 1 automaticamente com o novo trio.
```

---

## O BAG EXPLICADO

### Por Que Existe um Bag?

**Sem sistema de Bag (sorteio puro):**
- Cada carta vinha 100% aleatória.
- Resultado: às vezes a mão nunca tinha um trio (travava o jogo).
- Outras vezes vinha 10 cartas Vermelhas em fileira (ninguém queria jogar).

**Com Bag (composição garantida):**
- Sabemos exatamente quantas cartas de cada tipo virão.
- Nenhuma sequência > 3 cartas iguais.
- Nenhuma "seca" (demora > 24 cartas para aparecer 1 cor).
- **Resultado:** Jogo fluido, justo, sem travamentos.

### Estrutura do Bag

```
Um Bag = 100 cartas sempre.

Composição:
  Vermelho (Dragão): 16
  Azul (Cavaleiro):   16
  Verde (Natureza):   16
  Amarelo (Sagrado):  16
  Roxo (Sombrio):     16
  ─────────────────────
  Subtotal (Ataque): 80
  
  Cura:              12
  Coringa:            8
  ─────────────────────
  Total:            100

Visualizado:
┌─────────────────────────────────────────┐
│ Bag (100 cartas, misturadas mas não ao │
│ acaso — respeitam estratificação)      │
│                                         │
│ [ordem de compra] ◄─ Topo (sai primeiro)
│ 1º, 2º, 3º, ... 100º
│                                         │
│ Remonta automaticamente ao ficar vazio │
└─────────────────────────────────────────┘
```

### Algoritmo de Geração (Estratificação)

O Bag não é sorteio puro. É gerado em **5 faixas** de 20 cartas cada:

```
Faixa 1 (cartas 1–20):   4 Verm, 4 Azul, 4 Verde, 4 Amar, 4 Roxo
Faixa 2 (cartas 21–40):  4 Verm, 4 Azul, 4 Verde, 4 Amar, 4 Roxo
Faixa 3 (cartas 41–60):  4 Verm, 4 Azul, 4 Verde, 4 Amar, 4 Roxo
Faixa 4 (cartas 61–80):  4 Verm, 4 Azul, 4 Verde, 4 Amar, 4 Roxo
Faixa 5 (cartas 81–100): 12 Cura + 8 Coringa (ou distribuído nas 4 faixas acima)

Resultado: Cada grupo de ~20 cartas tem exatamente 4 de cada tipo.
Nada de 8 Vermelhas em fileira.
```

### O Processo de Compra (Desenho da Mão)

```
Inicialmente (novo jogo):
1. Bag gera sua composição (100 cartas, ordem aleatória mas estratificada).
2. Sistema "compra" 10 cartas do Bag para montar a mão inicial.
3. Sistema "compra" 5 cartas para a fila (QTD_PROXIMAS = 5).

Durante o jogo (cada combo):
1. Jogador faz combo.
2. 2 cartas saem da fila e descem para a mão.
3. Sistema "compra" 2 novas cartas do Bag para repor a fila.
4. Cascata? Volta ao passo 1. Sem cascata? Vez do inimigo.

Quando Bag fica vazio:
1. Sistema detecta: "Tentei comprar, mas Bag está vazio."
2. Antes de remontar, verifica: "A mão tem algum trio?"
3. Se NÃO tem trio: "Recoloro 1 card orfão para garantir saída."
4. Remonta novo Bag com mesma composição.
5. Continua normalmente.
```

### A Fila Visual (Direita da Tela)

```
┌──────┐
│ 🟩 6 │  ◀─  Próxima a descer (vai ser comprada PRIMEIRO)
├──────┤
│ 🟪 2 │  ◀─  Segunda (vai ser comprada depois)
├──────┤
│ 🟥 8 │  ◀─  Terceira
├──────┤
│ 🟦 1 │  ◀─  Quarta
├──────┤
│ 🟨 9 │  ◀─  Quinta (última da fila visível)
├──────┤
│ ?? ?? │  ◀─  Sexta em diante (INVISÍVEL, mas existe no Bag)
└──────┘

Quando 1 combo acontece:
- As 2 primeiras (🟩 6, 🟪 2) descem para a mão.
- As 3 restantes (🟥 8, 🟦 1, 🟨 9) sobem 1 posição.
- 2 novas cartas são sorteadas do Bag e entram no fim.

Nova fila:
🟥 8, 🟦 1, 🟨 9, [nova1], [nova2]
```

**Por que mostrar a fila?**
- **Estratégia:** Jogador vê o que vem e pode planejar ("Vou guardar 2 Vermelhos porque vou receber 1 em breve").
- **Transparência:** Não é sorteio invisível; jogador conhece as próximas 5.
- **Tensão:** "Preciso de um Azul, a fila não tem nenhum… conseguirei?".

---

## O FLUXO DE UMA PARTIDA

### Turn-by-Turn

```
┌─────────────────────────────────────────────────────────────┐
│                        INÍCIO DA PARTIDA                    │
│ Mão: 10 cartas (sorteadas do Bag)                          │
│ Fila: 5 cartas (sorteadas do Bag)                          │
│ Inimigo: 3200 HP, ATK 88, DEF 30, Turno: 5                │
│ Time: 335 HP total, 5 aliados                              │
│ Cascata: 1x (começa em 1, multiplica dano)                │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                    TURNO DO JOGADOR                         │
│                                                              │
│ 1. Jogador toca 3 cartas (tentativa de combo)              │
│ 2. Se válido:                                               │
│    ├─ Aliado ataca                                         │
│    ├─ Cartas desaparecem                                   │
│    ├─ Refill do Bag (2 cartas descem)                     │
│    ├─ Testa cascata                                        │
│    ├─ Se cascata: Cascata++ e volta ao passo 1            │
│    ├─ Se sem cascata: Turno passa pro inimigo              │
│                                                              │
│ 3. Se inválido: Toca novamente (sem perder cartas)        │
│                                                              │
│ 4. Botão "Desfazer": Volta o último combo (1× por turno)  │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                   TURNO DO INIMIGO                          │
│                                                              │
│ 1. Contador do inimigo decrementa por cada combo do jogo  │
│ 2. Se contador atinge 0:                                   │
│    ├─ Inimigo ataca                                        │
│    ├─ HP do time -= dano_inimigo                          │
│    ├─ Reseta contador (volta a 5–7)                       │
│    ├─ Cascata volta a 1x                                   │
│                                                              │
│ 3. Se contador ainda > 0: Apenas passa turno                │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                    VERIFICAR VITÓRIA/DERROTA                │
│                                                              │
│ Se inimigo.hp <= 0:  ✅ VITÓRIA (vai para Resultado)       │
│ Se time.hp <= 0:     ❌ DERROTA (vai para Resultado)       │
│ Senão: Volta ao TURNO DO JOGADOR                           │
└─────────────────────────────────────────────────────────────┘
```

### Exemplo Prático de Uma Sequência (3 Combos + Cascata)

```
ESTADO INICIAL:
┌──────┬──────┬──────┬──────┬──────┐
│ 🟥 5 │ 🟦 3 │ 🟩 7 │ 🟨 4 │ 🟪 9 │  Mão TOPO
└──────┴──────┴──────┴──────┴──────┘
┌──────┬──────┬──────┬──────┬──────┐
│ 🟥 6 │ 🟪 3 │ 🟩 2 │ 🟨 8 │ 🟦 5 │  Mão BAIXO
└──────┴──────┴──────┴──────┴──────┘

Fila: {🟩 6, 🟪 2, 🟥 8, 🟦 1, 🟨 9}
Inimigo HP: 3200 | Contador: 5 | Cascata: 1x
───────────────────────────────────────────────────────────────

COMBO 1: Jogador toca [🟥 5 (TOPO)], [🟥 6 (BAIXO)], [Fila: 🟥 8]
  ✅ 3 Vermelho válido!
  
  Dano:
    Agumon.ATK = 38
    Média de valores = (5 + 6 + 8) / 3 ≈ 6
    dano_base = 38 + 6 = 44
    dano_final = 44 - 30 (DEF) = 14 (sem crítico)
  
  Inimigo HP: 3200 → 3186
  Cascata: 1x
  
  Refill:
    Fila perde 2 primeiras: {🟩 6, 🟪 2}
    Nova fila: {🟥 8, 🟦 1, 🟨 9, [nova1], [nova2]}
    (Ex: [nova1] = 🟩 3, [nova2] = 🟦 4)
    Fila: {🟥 8, 🟦 1, 🟨 9, 🟩 3, 🟦 4}
  
  Mão atualizada:
  ┌──────┬──────┬──────┬──────┬──────┐
  │ 🟦 3 │ 🟩 7 │ 🟨 4 │ 🟪 9 │ 🟩 6 │  (🟩 6 desce aqui)
  └──────┴──────┴──────┴──────┴──────┘
  ┌──────┬──────┬──────┬──────┬──────┐
  │ 🟪 3 │ 🟩 2 │ 🟨 8 │ 🟦 5 │ 🟪 2 │  (🟪 2 desce aqui)
  └──────┴──────┴──────┴──────┴──────┘

Testar cascata:
  Há trio de 🟩? [🟩 7, 🟩 2, 🟩 6] = ✅ SIM
  Há trio de 🟪? [🟪 9, 🟪 3, 🟪 2] = ✅ SIM
  
  Qual prioridade? Verde tem 3, Roxo tem 3. Ordem fixa: VERM > AZUL > VERDE.
  ➜ Escolhe VERDE.
  ➜ Cascata ATIVA!

───────────────────────────────────────────────────────────────

COMBO 2 (CASCATA AUTO): [🟩 7], [🟩 2], [🟩 6]
  ✅ 3 Verde (gerado automaticamente)
  
  Dano:
    Palmon.ATK = 72
    Média = (7 + 2 + 6) / 3 ≈ 5
    dano_base = 72 + 5 = 77
    dano_final = 77 - 30 = 47 (sem crítico)
  
  MAS ESPERA! Cascata 2x, então:
    dano_final = 47 × 2 = 94 💥
  
  Inimigo HP: 3186 → 3092
  Cascata: 2x
  
  Refill:
    Fila anterior: {🟥 8, 🟦 1, 🟨 9, 🟩 3, 🟦 4}
    Perde 2: {🟥 8, 🟦 1}
    Nova fila: {🟨 9, 🟩 3, 🟦 4, [nova3], [nova4]}
    (Ex: [nova3] = 🟨 2, [nova4] = 🟥 9)
  
  Mão atualizada (removeu 3 Verdes, desceu 2 novas):
  ┌──────┬──────┬──────┬──────┬──────┐
  │ 🟦 3 │ 🟨 4 │ 🟪 9 │ ? ? │ 🟥 8 │  (2 novas cartas desceram aqui)
  └──────┴──────┴──────┴──────┴──────┘
  ┌──────┬──────┬──────┬──────┬──────┐
  │ 🟪 3 │ 🟨 8 │ 🟦 5 │ 🟪 2 │ 🟦 1 │  (1 nova carta desceu aqui)
  └──────┴──────┴──────┴──────┴──────┘

Testar cascata novamente:
  Há trio de 🟦? [🟦 3, 🟦 5, 🟦 1] = ✅ SIM
  
  Cascata CONTINUA!

───────────────────────────────────────────────────────────────

COMBO 3 (CASCATA AUTO): [🟦 3], [🟦 5], [🟦 1]
  ✅ 3 Azul
  
  Dano:
    Gabumon.ATK = 68
    Média = (3 + 5 + 1) / 3 ≈ 3
    dano_base = 68 + 3 = 71
    dano_final = 71 - 30 = 41
  
  COM Cascata 3x:
    dano_final = 41 × 3 = 123 💥💥💥
  
  Inimigo HP: 3092 → 2969
  Cascata: 3x
  
  Refill e testar cascata...
  (Digamos que NÃO há mais trios)
  
  Cascata TERMINA. Cascata volta a 1x.

───────────────────────────────────────────────────────────────

FIM DO TURNO DO JOGADOR:
  Dano total deste turno: 14 + 94 + 123 = 231
  Cascata máxima alcançada: 3x
  Inimigo HP: 2969

Inimigo contador -= 3 combos = 5 - 3 = 2 (ainda não ataca)
Volta ao turno do jogador...
```

---

## REGRAS ESPECIAIS

### Wild Card (Coringa)

```
O que é?
  Carta branca (cor neutra).
  Combina com QUALQUER cor.

Como funciona?

Exemplo 1: Trio com 2 iguais + 1 Wild
  [🟥 5] + [🟥 8] + [⚪ 3] = Trio VERMELHO válido
  ➜ Aliado Vermelho ataca.

Exemplo 2: Trio misto com Wild
  [🟥 5] + [🟦 3] + [⚪ 7] = Inválido!
  ➜ Diferentes cores (Verm ≠ Azul), Wild não salva.

Regra: Wild = Any, MAS os não-wilds devem ser da mesma cor.

Crítico com Wild:
  [🟥 5] + [🟥 8] + [⚪ 3] → Valores diferentes (5, 8, 3)
  ➜ SEM crítico por igualdade, MAS tem Wild!
  ➜ CRÍTICO GARANTIDO × 1.5 (no futuro do jogo)
  
  (Atualmente: Wild ativa crítico se os valores forem iguais OU sempre?
   → Verificar regra real do original. Por hora: crítico se 5/5/5 OU 8/8/8.)
```

### Desfazer (Undo)

```
Botão "↩ Desfazer" permite refazer o ÚLTIMO combo de uma vez.

Regra:
  - Pode usar 1× por turno do jogador.
  - Refaz: cartas voltam ao lugar, refill reverte, cascata zera.
  - Não refaz: contador do inimigo (mantém o descréscimo).
  - Útil se o jogador errou de trio.
```

### Garantia de Saída (Fail-Safe)

```
Quando o Bag remonta (fica vazio):

1. Sistema testa: Há trio na mão?
2. Se NÃO:
   ├─ Identifica cor orfã (menor quantidade).
   ├─ Recolore 1 carta dessa cor para a cor maioria.
   ├─ Agora há trio garantido.
   └─ Log interno: saidas_forcadas++
3. Se SIM: Continua normalmente.

Frequência: ~10.98% (9 recolorações a cada 82 remontagens)

Design: Evita jogo travado. Skills futuras (Replace, Reshuffle)
        virão como alternativa paga (jogador escolhe arriscar).
```

### Cascata - Priorização

```
Quando há múltiplos trios possíveis, qual escolher?

Algoritmo:

1. SCORE CADA TRIO:
   qtd_dessa_cor_na_mao = count(mão, cor_do_trio)
   
   Trio A (Vermelho): qtd_verm = 2
   Trio B (Roxo):     qtd_roxo = 3
   Trio C (Verde):    qtd_verde = 2
   
2. ORDENA por qtd (MENOR PRIMEIRO — destock):
   [Trio A (2), Trio C (2), Trio B (3)]
   
3. EMPATE? Testa qual trio deixa a mão MENOS desbalanceada:
   Trio A: Remove 3 Verm (2 → 0), "deixa 0 órfãs"
   Trio C: Remove 3 Verde (2 → 0), "deixa 0 órfãs"
   
4. AINDA EMPATE? Ordem fixa:
   VERMELHO > AZUL > VERDE > AMARELO > ROXO > CURA
   
   ➜ Escolhe Trio A (Vermelho).

Resultado: Sempre destock orphans (cartas solitárias) primeiro.
           Evita fichas "2 Verm, 2 Azul, 2 Verde..." (paralisia).
```

---

## RESUMO: POR QUE TUDO FUNCIONA ASSIM?

| Mecânica | Por Quê |
|---|---|
| **Bag com Composição Fixa** | Evita sorteio caótico; garante variedade. |
| **Fila Visível à Direita** | Permite planejamento; reduz frustração de "sorte pura". |
| **Cascata Automática** | Recompensa planejamento; cria tensão ("Vai cascatear?"). |
| **Priorização de Destock** | Evita paralisia tática; força o jogo a fluir. |
| **Wild com Dupla Regra** | Torna coringa procurado MAS com restrição (não é "solve all"). |
| **Garantia de Saída (~11%)** | Impossível ficar travado; mantém jogabilidade. |
| **Refill em 2 Cartas/Combo** | Ritmo rápido; sem espera longa. |
| **Dano × Cascata** | Recompensa dança/planejamento exponencialmente. |

**Game Feel:**
O jogo parece caótico (sorteio), mas é **profundamente estratégico** (Bag é determinístico, fila é visível). Combina **skill** (saber escolher trios) + **luck** (qual carta vem) = **satisfatório**.

---

## REFERÊNCIA VISUAL: TELA DURANTE COMBO

```
┌──────────────────────────────────────────────────────────────┐
│                                                               │
│              HP: 2969 / 3200  ♥    ATK: 88 | DEF: 30         │
│                                                               │
│   [Retrato do Inimigo]  [Ícones de buff/debuff]              │
│                                                               │
├──────────────────────────────────────────────────────────────┤
│                                                               │
│  Cartas levitando no centro (durante trio):                  │ Fila à direita
│                                                               │ (descendo):
│              ┌──────┐                          ┌──────┐      │
│              │ 🟥 5 │     ◀───────────────      │ 🟥 8 │      │
│              │      │                          ├──────┤      │
│              │ 🟥 6 │     (animação 0.3s)      │ 🟦 1 │      │
│              │      │     (amarelo)            ├──────┤      │
│              │ 🟥 8 │                          │ 🟨 9 │      │
│              └──────┘                          ├──────┤      │
│                                                │ 🟩 3 │      │
│  Título: "3 VERMELHO!"                        ├──────┤      │
│  Som: POP!                                    │ 🟦 4 │      │
│                                                └──────┘      │
│                 ↓                               ↓             │
│                                               (Descendo)     │
├──────────────────────────────────────────────────────────────┤
│                                                               │
│  Agumon ataca!  Dano: 14  (38 ATK + 6 valor médio - 30 DEF)  │
│  Som: CRASH!                                                  │
│                                                               │
│  Inimigo HP: 3200 → 3186                                      │
│                                                               │
├──────────────────────────────────────────────────────────────┤
│  [↩ Undo]      [✕ Sair]           CASCATA: 1x               │
└──────────────────────────────────────────────────────────────┘
```

---

**Fim da explicação. O sistema é complexo mas elegante: aparenta sorte, é estratégia pura.**
