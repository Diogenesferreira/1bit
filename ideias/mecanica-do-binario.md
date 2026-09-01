# A mecânica lida do binário original

O que foi recuperado da lógica de batalha do Digimon Heroes! original, lendo
o código nativo do jogo — e o que **não** foi.

Documento de referência: quando houver dúvida sobre uma regra, o que está
marcado como **confirmado** aqui vence os docs de design e vence o que o
`BattleLogic.gd` faz hoje.

## Onde está a lógica

`lib/armeabi-v7a/libDigimonJNI.so` (4,66 MB) dentro do APK. É código **nativo
ARM compilado** — os `.dex` são só a casca Android. Não existe fonte C++ para
abrir; um `.so` em editor de texto é lixo binário.

**O que torna isso viável: a biblioteca não está stripped.** Os símbolos C++
estão intactos. A classe `CBattlePart` expõe **170 métodos nomeados**.

Para ler: Ghidra (grátis, precisa JDK 21) → importar o `.so` → auto-analisar →
buscar `CBattlePart` no filtro do Symbol Tree → painel *Decompile* mostra
pseudo-C com os nomes certos.

O `.so` fica em `assetsemodelosideias/libDigimonJNI.so` (fora do repositório,
ver `.gitignore`). Reproduzível com:

```
python -c "import zipfile; zipfile.ZipFile('<apk>').extract('lib/armeabi-v7a/libDigimonJNI.so', '.')"
```

---

## CONFIRMADO — o nosso código já estava certo

| Regra | Onde no original | Onde no nosso |
|---|---|---|
| Mão de **12 casas** | `CheckCardChain` itera `0xc` | `TAMANHO_MAO` + 2 entradas |
| Coringa casa com qualquer cor | `CheckCardChain`, cor `6` = wild | `CardData.combina` |
| **5 cores** de aliado (+ coringa) | array de contagem tem 5 posições | `CORES_DE_ATAQUE` |
| Precisa de **2 outras** além da tocada | `CheckCardChain` exige `>= 2` | `qtd + ajuda >= 3` (equivalente) |
| **Crítico** = 3 valores iguais **ou** sequência | `ChkChainCritical` conta por valor | `BattleLogic.gd:628` |
| Mão ordenada por **cor, depois valor**, crescente | chave `cor*10 + valor`, `SortComp` = `a-b` | `_antes_de()` |
| **HP é pool único do time**, com teto | `AddHP`: `hp = min(hp+v, hp_max)` | `hp_jogador` / `hp_jogador_max` |
| Mão exibe **10 cartas**, entradas escondidas | `SortCard` limita a 10 e esconde o resto | modelo 10 + 2 |

**Encerrada uma divergência antiga dos docs:** não existe HP por aliado no
original. É um pool só. (Ver decisão de design no fim deste documento.)

---

## CORRIGIDO — o nosso código está errado

### 1. Defesa é multiplicativa, não subtrativa 🔴

O achado de maior impacto. `MasterTable_BattleDamageReduction`:

```
CalculateDamageReduction(degrau_inf, degrau_sup, defesa_real):
    red_inf = tabela[degrau_inf].reducao
    red_sup = tabela[degrau_sup].reducao
    t = (defesa_real - degrau_inf) / (degrau_sup - degrau_inf)   # clamp em 1
    reducao = red_inf + t * (red_sup - red_inf)                  # interpolação linear
    return clamp(reducao / 100, 0, 1)                            # fração 0..1
```

`GetDamageReductionForDefense(defesa)` percorre a lista de degraus, acha entre
quais a defesa cai, e chama a interpolação acima.

Logo:

```
dano_final = dano × (1 − reducao)
```

Nosso código faz `dano_bruto = dano_base − inimigo.defesa`. **Estruturalmente
errado.** A diferença muda o balanceamento inteiro: subtração faz ataque fraco
zerar contra defesa alta; porcentagem faz todo ataque sempre passar alguma
coisa, com retorno decrescente.

**Limite:** temos a fórmula, **não a tabela**. Os `DAMAGE_REDUCTION_STEP_RECORD`
vinham de JSON do servidor, que está desligado. A curva terá que ser estimada
por nós — e marcada como estimativa no código.

### 2. A escolha do trio na cascata não é "menor quantidade"

`CheckCardChain` faz **três passadas** sobre as cores, filtrando pela contagem
daquela cor na mão:

| Passada | Contagens | Equivale a |
|---|---|---|
| 1ª | 2, 5, 8 | `contagem % 3 == 2` |
| 2ª | 4, 7 | `contagem % 3 == 1` |
| 3ª | 3, 6, 9 | `contagem % 3 == 0` |

É **resto da divisão por 3**, não menor quantidade. A lógica é mais fina: uma
cor com 5 cartas deixaria 2 órfãs após fechar um trio — mesma urgência de uma
cor com 2. Nosso `_melhor_trio()` mandaria a de 2 primeiro sempre.

### 3. O desempate é a nota do crítico

Dentro de cada passada, o original chama `ChkChainCritical` para cada cor
candidata, usa o retorno como chave e faz `qsort`. Nosso desempate é
`cor < melhor_cor` — arbitrário, escolhido só para ser estável.

### 4. Cores com aliado indisponível são puladas

Antes das passadas, `CheckCardChain` monta uma tabela de 6 posições varrendo os
aliados e checando um flag no **offset 400**. Cores reprovadas são puladas em
todas as passadas. Nosso `_melhor_trio()` não olha estado de aliado.

### 5. "Coringa = crítico garantido" — REFUTADO

Estava nos docs como decisão pendente. **O original não faz isso.** O coringa
entra como *substituto* para completar uma trinca de valores iguais:

```
if (cor == wild) contador_coringa++;
...
if (contagem_do_melhor_valor + contador_coringa < limite) nota = 0;
```

Ele ajuda a **formar** um 5-5-5 quando só há dois 5. Não concede crítico
sozinho. **Pendência encerrada: a resposta é não.**

---

## DESCOBERTO — informação nova

### O crítico devolve uma NOTA, não sim/não

`ChkChainCritical(cor, bool)` conta as cartas daquela cor **por valor**
(`contagem[1..9]`) e devolve:

| Situação | Nota |
|---|---|
| Três valores iguais | `valor × 10` (999 → 90, 555 → 50) |
| Sequência consecutiva | ~`valor × 3` (24, 21, 18…) |
| Par mínimo (1 e 2 presentes) | 6 |
| Nada | 0 |

Retorna o **maior** dos casos. É essa nota que ordena as cores candidatas no
`CheckCardChain`.

### Estrutura de dados do original

| Campo | Offset | Observação |
|---|---|---|
| Carta: cor | `+4` | codificada, precisa de `GetGlobalOffset` |
| Carta: valor | `+8` | idem |
| Carta: ativa | `+0x30` | flag |
| `CBattlePart`: HP atual | `+0xc8` | ofuscado |
| `CBattlePart`: HP máximo | `+0xa0` | ofuscado |
| `CBattlePart`: array da mão | `+0x2c0` (e `+700`) | 12 entradas |
| `CBattlePart`: array de aliados | `+0x388` | 6 entradas |
| Aliado: flag de indisponível | `+400` | significado exato desconhecido |

**6 aliados, 5 slots de buff cada** (`CheckBuffsActive`).

### Os floats são ofuscados na memória

Todo valor numérico é guardado com bytes embaralhados + rotação de bits — é
anti-cheat. É a origem de todo aquele ruído de `1 << uVar & ...` nas funções
decompiladas. **Não precisamos copiar isso.**

---

## NÃO CONSEGUIDO — continua em aberto

### A fórmula de ataque 🔴

O que combina `ataque do aliado + valores das cartas + multiplicador de
cascata` **não foi localizada**. Continuam sem confirmação, portanto, três
invenções nossas em `BattleLogic.gd`:

```gdscript
var dano_f := (digimon.ataque + soma * 10) * (1.0 + 0.3 * cadeia)   # o 10 e o 0.3 são chute
if critico: dano_f *= 1.5                                            # o 1.5 é chute
```

E mais uma:

```gdscript
var cura := soma * 12   # o 12 é chute
```

O `AddHP` do original só recebe o número já pronto — quem o calcula está
noutro lugar.

Candidatos ainda não lidos: `updateGameLogic(float,float,float)` (deve ser
enorme — é o laço principal), `SetAtkPriTbl`, `ChkSpSupport(int,int,int)`,
`DIGIMON_INFO::CalcAttk`.

### Detalhes menores em aberto

- **O que o `offset 400` significa.** Sei que bloqueia a cor; não sei a
  condição que liga o flag (morto? paralisado? bloqueado por skill inimiga?).
- **`local_78` em `CheckCardChain`** — parece guardar a cor da cadeia corrente,
  usada para evitar repetir a mesma cor. Não confirmado.
- **A trava do topo de `CheckCardChain`**: `campo(0x230) < 0x1f` (31) e
  `campo(0x238) == -1`. Pode ser limite de corrente. Desconhecido.
- **Pontuação fina da sequência** — li a estrutura e a faixa de notas, mas não
  tenho certeza de qual combinação exata gera 24 vs 21. Irrelevante para
  crítico sim/não; importaria só na ordenação fina.
- **Direção do comparador `qsort` (`0x1d170d`)** — a semântica ficou clara
  (ordena por nota de crítico), a direção não foi verificada.

### Os números, em geral

As Master Tables (`MasterTable_Card`, `_Skill`, `_SkillParams`, `_EnemyParam`,
`_EnemySkills`, `_EnemyPosition`, `_ConstsGeneric`…) são carregadas via
`LoadFromJSON` **do servidor, que está desligado**. O APK só traz
`texts_EN.bin` e configs. Então: **as regras são recuperáveis do binário; os
valores numéricos de cada Digimon, não.**

---

## BECOS SEM SAÍDA — não repetir

| O quê | Por quê |
|---|---|
| `UpdateEnemyDamageBy` | Código de tutorial + flag de animação (`0x13c`, valores 0-3). Nenhuma matemática. |
| `ProcessSkill` | Só dispara evento de UI para destacar a skill selecionada. |
| `UpdateBeforeSortCardAnim` | Só animação: distância, velocidade `dist*150/500000`, som `0x2f`. |
| APK 1.0.52 | Assets de batalha **byte-idênticos** ao 1.0.48; `CBattlePart` com os mesmos 170 métodos. A diferença é só popup de liga PVP. |

---

## Decisão de design do projeto

O usuário confirmou, e isso **não** é divergência a corrigir:

- **HP é único, formado pela soma de todos os aliados.** É como está hoje e
  bate com o original.
- **Cada personagem tem ataque, defesa e skills individuais** — isso entra
  numa fase futura, no desenvolvimento individual de cada personagem. As
  estruturas do original (6 aliados × 5 buffs, `DIGIMON_SKILL_PARAMS`,
  `ENEMY_SKILL_RECORD`) mostram o formato que isso terá lá na frente.
