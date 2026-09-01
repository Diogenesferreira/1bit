# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

O projeto é escrito em português (identificadores, comentários e documentação).
Mantenha esse idioma ao escrever código e docs novos.

## Comandos

Godot 4.7.1 **não está no PATH**. O executável está em
`C:\Users\Jinsa\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64.exe`
(a versão `_console.exe` no mesmo diretório é a que imprime no terminal do Windows).

```sh
godot --path .                                                   # jogar
godot --headless --path . --script res://tests/test_batalha.gd   # testar (CI)
godot --path . --script res://tests/test_batalha.gd              # testar + prints em user://
godot --path . --script res://tests/capture_card_ui.gd           # capturar a UI das cartas
godot --path . --script res://tests/capture_card_palette.gd      # prancha dos 7 tipos
godot --path . --script res://tests/capture_skill_ui.gd          # estados do medidor
godot --headless --path . --export-debug Android build/1-bit-heroes-ui-final-debug.apk
```

`tests/test_batalha.gd` é um `SceneTree` único, sem framework de teste, e sai com
código 1 se houver falhas. Ele roda em duas partes:

1. **regra pura** — 30 partidas simuladas (sementes `2000+n`, determinísticas) mais
   `_testar_regras_canonicas()`, que trava as regras de `REGRAS_CANONICAS_ALPHA.md`;
2. **tela** — instancia `BattleScreen.tscn` de verdade, toca nas casas e confere se o
   desenho bate com o estado.

Não existe "rodar um teste só": para isolar um caso, edite `PARTIDAS`/`TURNOS_NA_TELA`
no topo do arquivo ou comente `_parte_tela()` em `_initialize()`.

Não é um repositório git.

## Arquitetura

### A regra não mora na tela

A separação central do projeto:

- [`scripts/battle/EstadoBatalha.gd`](scripts/battle/EstadoBatalha.gd) é um `RefCounted`
  puro — sem nó, sem asset, sem `await`. Rodando só isso dá para jogar partidas inteiras
  headless.
- [`scripts/battle/BattleScreen.gd`](scripts/battle/BattleScreen.gd) monta o layout e
  **reproduz** o que a regra decidiu; nunca decide nada.

O contrato entre os dois é uma **lista de eventos já resolvida**. `estado.tocar(idx)` /
`estado.desmarcar(idx)` devolvem `{"tipo": "jogada"|"ignorado", "eventos": [...], ...}`
com a corrente **inteira** já calculada; `_reproduzir()` faz `match` no `ev.tipo` e anima
em ordem. A tela **nunca consulta o estado no meio da animação** — enquanto anima, toques
são ignorados por `_animando`.

Tipos de evento: `selecao`, `deselecao`, `carta_desce`, `carta_volta`, `abandono`,
`puxa_do_deck`, `trio_sobe`, `combo`, `renovacao`, `nova_carta`, `entra_na_mao`,
`redistribuicao`, `ataque_final` (+ a chave opcional `ataque_inimigo` no resultado).

Ao mexer na mecânica, mexa em `EstadoBatalha.gd` e adicione o evento correspondente;
só depois ensine a tela a animá-lo. Lógica nova em `BattleScreen.gd` quebra os testes
headless da parte 1.

### O campo tem 12 casas, não 10

`TAMANHO_MAO` = 10 (2 fileiras de 5) + `ENTRADA_0`/`ENTRADA_1` (a coluna 6 de cada
fileira) = `TOTAL_SLOTS` = 12. As ENTRADAS começam vazias e recebem a carta que desce do
saco quando o jogador marca a 1ª e a 2ª carta do trio. `mao` é `Array[Carta]` de 12 com
`null` para casa vazia; índices ≥ `TAMANHO_MAO` são ENTRADA.

O handoff original desenhava 2×5; a coluna 6 é exigência da mecânica, então as casas
encolheram para caber no mesmo vão horizontal do design.

### Demais peças

| Arquivo | Papel |
|---|---|
| [`Carta.gd`](scripts/battle/Carta.gd) | tipo (5 elementos + `capsule`/cura + `wild`/coringa) e valor 1–9 |
| [`Saco.gd`](scripts/battle/Saco.gd) | o BAG: composição fixa de 100, estratificada e sem rajada — não é sorteio puro |
| [`Unidades.gd`](scripts/battle/Unidades.gd) | dados dos 5 inimigos e 5 aliados + toda a matemática de layout da arena |
| [`Arte.gd`](scripts/battle/Arte.gd) | **única** ponte com os assets: nomes de arquivo, paleta, fonte, tamanhos nativos |
| [`CardIcon.gd`](scripts/battle/CardIcon.gd) | a carta desenhada em código; só o glifo central vem de asset |
| `{Bag,Field}Slot.tscn` + `.gd` | as casas, uma cena por componente |
| [`shaders/inverter*.gdshader`](shaders/) | o `filter: invert(1)` do protótipo (crachá, hit flash, flash de tela) |
| [`shaders/card_element_tint.gdshader`](shaders/card_element_tint.gdshader) | cor fosca dos glifos e Wild multicolor |

Nenhum script além de `Arte.gd` deve citar caminho de asset.

### Layout

`BattleScreen.tscn` é um `Control` quase vazio: **toda a UI é construída em código** em
`_montar()`, com constantes em pixel no topo do arquivo sobre um canvas de 1152×2048
(`window/stretch/mode="canvas_items"`, retrato, Android). `Unidades.gd` converte o módulo
lógico 540×520 de `novos modelos refeitos/battle_layout_pixel_spec.md` para a arena atual,
sempre arredondando para coordenadas inteiras — pixel art com filtro nearest
(`default_texture_filter=0`). Preserve o arredondamento ao mexer em posição/escala.

## Documentos

Hierarquia ao mudar comportamento de batalha:

1. [`REGRAS_CANONICAS_ALPHA.md`](REGRAS_CANONICAS_ALPHA.md) — **fonte de verdade** da
   batalha alpha; `_testar_regras_canonicas()` trava parte dela em teste.
2. [`DESIGN_DO_JOGO.md`](DESIGN_DO_JOGO.md) — produto, modos, progressão, ordem de
   produção. A próxima tarefa recomendada é a Etapa 1 (clareza do combate).
3. [`LORE_E_PADRAO_DE_PERSONAGENS.md`](LORE_E_PADRAO_DE_PERSONAGENS.md) — padrão visual e
   ficha de personagem novo.
4. [`SKILLS_REFERENCIA_E_BALANCEAMENTO.md`](SKILLS_REFERENCIA_E_BALANCEAMENTO.md) —
   biblioteca adaptada de skills; inspiração e proposta, ainda não canônica.
5. [`ideias/`](ideias/) — pesquisa e histórico (`regra-de-campo.md`,
   `mecanica-do-binario.md`, o handoff HTML). Tem `.gdignore`: fica **fora** do projeto
   Godot, não importa e não compila. Não use isoladamente para alterar código.

[`LEIAME.md`](LEIAME.md) descreve o uso atual da tela. Decisões mecânicas
continuam pertencendo a `REGRAS_CANONICAS_ALPHA.md`; o adendo no início de
`battle_layout_pixel_spec.md` prevalece sobre as tabelas visuais históricas.

## Resíduos conhecidos

- `scripts/*.gd.uid` na raiz de `scripts/` são órfãos: os `.gd` correspondentes moraram
  ali e hoje estão em `ideias/scripts/`, fora do projeto.
- `LaneSlot.tscn`/`LaneSlot.gd` e `EstadoBatalha.LANE_CASAS` são legado da Fusion Lane
  removida — nada os instancia.
- Ainda não implementados: vantagem elemental no dano, intenção inimiga além do
  contador, efeitos/consumo das cinco skills e avanço dos pips de rodada. A
  carga radial das skills já funciona; o HP é deliberadamente compartilhado.
