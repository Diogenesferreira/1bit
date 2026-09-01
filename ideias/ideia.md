# DIGIMON HEROES - GAME DESIGN DOCUMENT

## 1. VISÃO GERAL

**Gênero:** Card-battler / Puzzle RPG  
**Plataforma:** Mobile (viewport 1080×1920)  
**Loop Principal:** Selecionar cartas → fechar trios → aliados atacam → inimigo contra-ataca → progressão de saúde  
**Objetivo:** Reduzir HP do inimigo a 0 antes que o HP do time chegue a 0

---

## 2. SISTEMA DE CARTAS

### 2.1 Tipos de Carta

7 tipos, mapeados diretamente a Digimon. Cada tipo é uma **cor** e um **aliado**:

| Tipo | Cor (Hex) | Aliado (Exemplos) | Função |
|---|---|---|---|
| Dragão | `#FF4444` (Vermelho) | Agumon, Gabumon | Ataque |
| Cavaleiro | `#4488FF` (Azul) | Gabumon, Agumon | Ataque |
| Natureza | `#44FF44` (Verde) | Palmon, Bulbasaur-like | Ataque |
| Sagrado | `#FFFF44` (Amarelo) | Patamon, Angemon | Ataque |
| Sombrio | `#AA44FF` (Roxo) | Impmon, Guilmon | Ataque |
| Recuperação | `#CCAA88` (Marrom) | — | Cura / Suporte |
| Wild (Coringa) | `#FFFFFF` (Branco) | — | Coringa (casa com qualquer cor) |

### 2.2 Valores das Cartas

Cada carta tem um **valor de 1 a 9** (combinatória com valor influencia crítico).

---

## 3. A MÃO E O TABULEIRO

**Visível:** 10 cartas em **2 fileiras de 5** (BOTTOM e TOP na tela).  
**Não visível:** Fila de 5 próximas cartas do topo do deck (o "QTD_PROXIMAS"), renderizada como um leque visual descendo.

### 3.1 Estados Visuais da Carta

- **Repouso:** Posição natural na fileira.
- **Marcada (selected):** Levanta ligeiramente, borda brilha.
- **Selecionada para trio:** Sobe ao centro (animação 0.2s ease-out).
- **Descendo do deck:** Cai suavemente até preencher buraco.

---

## 4. CLOSURE (FECHAR TRIO)

### 4.1 Regra de Encaixe

Um **trio válido** é:
- **3 cartas da mesma cor** OU
- **2 cartas da mão da mesma cor + 1 do topo do deck da mesma cor** OU
- **1 da mão + 2 do deck** OU
- **Qualquer combinação contendo coringa**, se os não-coringas forem da mesma cor

**Coringa trata como qualquer cor**, mas se o trio tiver 2 coringas + 1 cor, a cor da "maioria" é a cor do trio.

### 4.2 Fluxo de Closure

1. Jogador toca 3 cartas.
2. Sistema valida se é trio.
3. Se válido: as 3 cartas **sobem ao centro**, viram amarelas (destaque), 0.3s.
4. **Aliado dessa cor ataca o inimigo** (ver §6 Combate).
5. As 3 cartas **desaparecem** (fade-out 0.2s).
6. Buracos aparecem na fileira.
7. Cartas acima **caem** (animação 0.3s ease-out).
8. **Novas cartas descem do deck** para preencher (ver §5 Bag).
9. **Sistema testa cascata** (ver §4.3).

### 4.3 Cascata (Chain)

Após closure + refill, o sistema **testa automaticamente** se há novo trio possível:

**Se SIM → Cascata:**
- Áudio de "chain" (aumento de tom).
- Contador visual sobe (1x → 2x → ... → até 13x no original).
- Dano do próximo ataque × multiplicador de cascata.
- Volta ao passo 1 (testa closure automático do novo trio).

**Se NÃO → Fim da Cascata:**
- Contador zera.
- Turno passa para o inimigo.

### 4.4 Critério de Cascata (Problema Resolvido)

A cascata **NÃO** simplesmente pega o primeiro trio que acha. Segue **priorização em cascata**:

1. **Procura o trio que consome a cor com MENOR quantidade na mão.**
   - Exemplo: Mão tem 2 Vermelho, 3 Roxo, 5 Verde. Preferencialmente fecha trio de Vermelho (destock).
   
2. **Se houver empate** (ex., 2 Vermelho e 2 Azul livres):
   - Testa qual trio devolve mais cartas daquela cor para a mão.
   - Exemplo: Trio de 2 Vermelho + Deck devolve 1 Vermelho; Trio de 2 Azul + Deck devolve 0 Azul.
   - Escolhe Vermelho.

3. **Se ainda empate:**
   - Ordem de preferência fixa: Vermelho > Azul > Verde > Amarelo > Roxo > Cura.

**Resultado:** Garante que **órfãos (cartas solitárias)** sejam consumidas antes de fechar trios que já têm 3+ da cor na mão.

---

## 5. O BAG (SACO DE CARTAS)

Sistema de geração **determinístico com composição garantida**, não sorteio puro.

### 5.1 Composição Exata por Saco

```
Tamanho do saco: 100 cartas

Por cor de ataque (5 cores):  16 cartas cada = 80 total
Recuperação:                 12 cartas
Coringa:                      8 cartas
───────────────────────────────
Total:                       100 cartas
```

### 5.2 Algoritmo de Geração (Estratificação)

1. **Divide o saco em 5 faixas** de 20 cartas cada.
2. **Em cada faixa:**
   - Coloca 4 de cada cor de ataque (4×5 = 20, preenchido).
   - OU, se a faixa terminou cedo, coloca 2–3 Cura + 1–2 Coringa.

**Resultado:** Nenhuma cor fica > 3 cartas consecutivas; Cura/Coringa distribuídos uniformemente.

### 5.3 Remontagem

Quando o saco fica vazio (último `comprar()`), **remonta automaticamente** um novo saco com a mesma composição.

**Garantia:** `_tem_saida()` verifica antes de remontagem se a mão tem trio. Se não tem, `_garantir_saida()` **recolore 1 card orfão** (acontece ~11% das vezes).

---

## 6. COMBATE

### 6.1 Ataque do Aliado

```
dano_base = aliado.ataque × valor_medio_cartas_do_trio

dano_final = dano_base - inimigo.defesa

Se dano_final < 0:
    dano_final = 0

Se é CRÍTICO:
    dano_final × 1.5
```

**Crítico:** Acontece se as 3 cartas do trio têm o **mesmo valor** (ex., 3×5 = 555) OU contém **wild** (coringa).

### 6.2 Defesa do Inimigo

```
dano_reduzido = max(1, dano_final - defesa_inimigo)
hp_inimigo -= dano_reduzido
```

### 6.3 Turno do Inimigo

Após a cascata terminar (ou imediatamente, se nenhum trio):
- Inimigo tem um **contador_turno** (começa em 5–7 turnos, parametrizável).
- Cada turno do jogador decrementa contador.
- Quando contador atinge 0: inimigo ataca.

```
dano_do_inimigo = inimigo.ataque (reduzido por buffs do jogador no futuro)
hp_time -= dano_do_inimigo
```

Se `hp_time <= 0` → Derrota.  
Se `hp_inimigo <= 0` → Vitória.

---

## 7. GARANTIA DE JOGABILIDADE

### 7.1 O Problema

~11% das mãos iniciais (e mid-jogo) não têm **nenhum** trio possível.

### 7.2 A Solução: `_garantir_saida()`

Se `_tem_saida(mao)` retorna False:
1. Identifica a **cor órfã** (a que tem MENOS cartas na mão).
2. Toma 1 carta dessa cor.
3. **Recolore para a cor maioria** (a que tem MAIS cartas).
4. Agora há trio garantido.
5. Log: `saidas_forcadas++` (rastreamento de custo).

**Custo Medido:** 9 recolorações em 82 remontagens = **10,98%** de intervenção automática.

**Design Rationale:** Sem isso, o jogo travaria periodicamente. Skills futuras (Replace, Reshuffle) virão como solução *paga* alternativa (o jogador escolhe o risco).

---

## 8. FLUXO DO JOGO

### 8.1 Telas

```
[Título] ─→ [Home] ─→ [Mapa] ─→ [Batalha] ─→ [Resultado] ─→ [Mapa]
                ↑                              │
                └──────────────────────────────┘ (botão Voltar)
```

#### Título (Tela 00)
- Logo centralizado.
- Leque de 5 cartas (cores) giradas, pulsando.
- "TOQUE PARA COMEÇAR" piscando.
- Toque qualquer lugar → Home.

#### Home (Tela 01)
- **Topo:** Marca "DIGIMON HEROES" + HP total do time.
- **Meio:** Grade 5×1 com os 5 aliados, cada um um medalhão 128×128 com:
  - Retrato do Digimon.
  - Nome.
  - Tipo (cor).
  - ATK (ataque base).
- **Menu:**
  - Botão grande verde: "▶ PARTIR EM MISSÃO" → Mapa.
  - 3 botões desabilitados: EVOLUIR, REFORÇAR, INVOCAR (futuros).

#### Mapa (Tela 00_01)
- **Cabeçalho:** Seta voltar + "MISSÕES" centrado.
- **Conteúdo:** ScrollView com 6 áreas.
- **Por Área:**
  - Nome + Marcador colorido (a cor oficial da área).
  - Descrição (1 parágrafo).
  - Lista de estágios: cada um é um botão.
    - Desbloqueado: verde, mostra nome + HP/ATK/DEF do inimigo no tooltip.
    - Bloqueado: cinza escuro, mostra "🔒" + dica "Vença a área anterior".
    - Vencido: verde escuro com "✔" (checkmark).
    - Chefe: fundo vermelho escuro com "👑".

**Progressão:**
- Área 0 (Primeira Batalha) começa aberta com 1º estágio liberado.
- Vencer estágio N libera estágio N+1.
- Vencer o **último estágio** (chefe) abre a próxima área.

#### Batalha (Tela 02)
- **Topo (bg_ue):** Inimigo com nome, HP, retrato, ícones de buff/debuff.
- **Meio:** Mão do jogador (2×5 grid).
  - Cards renderizadas com cor de fundo.
  - Valor grande no centro.
  - Brilho quando selected.
- **Topo da mão:** Fila visual (5 proximas) descendo como um leque.
- **Rodapé:**
  - 5 medalhões (aliados): cada um mostra HP, acúmulo de dano da cor, ícone de tipo.
  - Botão "↩ Desfazer" (último trio).
  - Botão "✕ Sair" (volta ao Mapa).
- **Centro da tela:** Contador de cascata (1x, 2x, ...).
- **Aviso acima dos aliados:** "⚠ PERIGO! Ataca no próximo combo!" se inimigo com contador = 1.

#### Resultado (Tela Pós-Batalha)
- **Título grande:** "VITÓRIA!" (verde) ou "DERROTA..." (vermelho).
- **Subtítulo:** Nome do estágio + nome do inimigo.
- **Painel de estatísticas:**
  - Dano causado (total da partida).
  - Combos realizados (count de cascatas).
  - Recompensa (placeholder: "— (sem sistema de itens)").
- **Se vitória no chefe:** "Nova área liberada: [Nome]".
- **Botões:**
  - "MISSÕES" (volta Mapa).
  - "JOGAR DE NOVO" (refaz o mesmo estágio).
  - "VOLTAR PARA A BASE" (Home).

---

## 9. PARÂMETROS AJUSTÁVEIS

| Parâmetro | Valor Atual | Impacto | Notas |
|---|---|---|---|
| `QTD_PROXIMAS` | 5 | Visual do deck | Quantidade de cartas visíveis no topo |
| `MAX_SEQUENCIA` | 3 | Variedade | Máximo de cartas iguais consecutivas no Bag |
| `POR_COR_ATAQUE` | 16 | Frequência | Cartas de ataque por cor no Bag |
| `QTD_CURA` | 12 | Suporte | Cartas de recuperação por saco |
| `QTD_CORINGA` | 8 | Wild availability | Coringas por saco |
| `CONTADOR_TURNO_INIMIGO` | 5–7 | Dificuldade | Turnos antes do inimigo atacar |
| `MULTIPLICADOR_CRITICO` | 1.5× | Dano | Bônus de dano em crítico |

---

## 10. SISTEMA DE CASCATA - REGRA PRECISA

**Algoritmo `_melhor_trio(mao, deck_topo)`:**

```gdscript
func _melhor_trio(mao: Array, deck_topo: Card) -> Dict:
    # Retorna {"slots": [idx1, idx2, idx3], "usa_deck": bool}
    
    # 1. Lista todos os trios possíveis (mão apenas OU 2 mão + 1 deck)
    candidatos = []
    
    for cada combinação de 3 cartas:
        if valida_trio(combinação, deck_topo):
            cor = get_cor_dominante(combinação)
            qtd_dessa_cor_na_mao = count(mao, cor)
            candidatos.append({
                "slots": indices,
                "cor": cor,
                "qtd_na_mao": qtd_dessa_cor_na_mao,
                "usa_deck": True if deck_topo in combinacao else False
            })
    
    # 2. Ordena por qtd_na_mao (menor primeiro — destock)
    sort candidatos por qtd_na_mao ASC
    
    # 3. Se empate em qtd, testa qual trio redevolve mais daquela cor
    # (após o closure, novas cartas caem; qual deixa menos órfãs?)
    
    # 4. Se ainda empate, ordem fixa: VERMELHO > AZUL > VERDE > AMARELO > ROXO > CURA
    
    return candidatos[0]
```

**Resultado Prático:**
- Mão: [2 Verm, 3 Roxo, 5 Verde]
- Trio possível: 2 Verm + Deck
- Trio possível: 3 Roxo
- Trio possível: 3 Verde
- **Escolhe:** 2 Verm (qtd=2, menor).

---

## 11. BALANCEAMENTO - FÓRMULA DE DANO

```
dano_base = max(1, aliado.ataque + (valor_carta_1 + valor_carta_2 + valor_carta_3) / 3)

dano_bruto = dano_base - defesa_inimigo

dano_com_critico = dano_bruto × 1.5 se (todos_iguais OR tem_coringa) else dano_bruto

dano_final = max(0, dano_com_critico)
```

**Exemplo:**
- Aliado Vermelho: ATK=38
- Trio: 5, 7, 9 (todos Vermelho, SEM coringa)
- Valor médio: (5+7+9)/3 = 7
- dano_base = 38 + 7 = 45
- Inimigo defesa = 20
- dano_bruto = 45 - 20 = 25
- **SEM crítico** (valores não iguais, sem coringa)
- dano_final = 25

---

## 12. OBJETIVOS FUTUROS (Roadmap)

### Fase 1: Profundidade Tática
- **Fraqueza Elemental — CORRIGIDO (2026-08-19), tinha suposição errada aqui.**
  `race_affinity_03.png`/`04.png`, achados no acervo do APK, mostram o
  diagrama oficial do jogo, limpo e colorido: **não é um ciclo único de 5**.
  São dois grupos independentes:
  - **Trio em pedra-papel-tesoura:** Dragão → Natureza → Cavaleiro → Dragão
    (cada um só vence o próximo, perde pro anterior).
  - **Par mútuo à parte:** Sagrado ↔ Sombrio — os dois se vencem um ao
    outro (não é hierarquia, os dois lados têm a seta).
  - Vantagem: dano × 1.2 (chute, valor real não confirmado)
  - Desvantagem: dano × 0.8 (chute, valor real não confirmado)
- **Wild = Crítico Garantido:** Simplifica avaliação, torna o coringa mais procurado.

### Fase 2: Extensão do Sistema
- **Skills:** 150+ no original.
  - 102 de dano (boosts, KO, sacrifice, etc.)
  - 48 de manipulação de cartas:
    - 28 na mão (Evolution, Drive/Support, Replace, Reshuffle)
    - 20 no saco (Seal, Release, All, Boost)
- **Leader Skill:** Efeito do aliado líder sobre todo o time.
- **Múltiplos Inimigos:** Até 6 adversários (seleção de alvo).

### Fase 3: Progressão de Longo Prazo
- **Itens:** Drop de ouro, cristais, ovos de Digimon.
- **Evolução:** Upgrade de aliado em forma/nível.
- **Reforço:** Aumento de stats (ATK, HP, DEF).

---

## 13. REFERÊNCIAS E FONTES

- **Original:** Digimon Heroes! v1.0.52 (APK final).
- **Skills:** Tabela Lua do Fandom (150+ skills documentadas).
- **Assets:** 1.054 retratos (128×128), 557 inimigos, UI em AGS/RHG.
- **QuestAreaMaster.txt:** 6 áreas + 14 estágios, nomes em japonês traduzidos.
