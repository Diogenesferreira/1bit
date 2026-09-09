# Ilha Digital

Projeto Godot 4 com a composição visual aprovada em **1024 × 1536** e combate de cartas jogável. A imagem original está em `assets/reference/ilha_digital_approved.png`, sem nenhuma edição.

## Abrir e jogar

- **Windows:** abra `build/IlhaDigital.exe`. Mantenha `IlhaDigital.pck` na mesma pasta. Não precisa instalar Godot para usar essa cópia local.
- **Editor:** importe `project.godot` no Godot 4 e pressione **F5**. Validado no Godot 4.7.1 instalado neste computador.
- A composição escala proporcionalmente. Em telas com outra proporção aparecem margens, preservando o enquadramento completo.

## Continuar em outro computador

Repositório: https://github.com/Diogenesferreira/1bit — branch `main`.

```powershell
git clone https://github.com/Diogenesferreira/1bit.git
cd 1bit
```

Instale Godot 4 (versão validada: 4.7.1), importe `project.godot` e pressione F5. Todo o código, as cenas, os Resources e a imagem aprovada estão versionados; não há dependência de arquivos na pasta pessoal do computador original. Python só é necessário para as ferramentas opcionais.

`build/`, `output/` e `.godot/` são gerados localmente e não acompanham o clone. Para gerar um executável Windows pelo editor, instale os templates de exportação correspondentes à sua versão do Godot, crie a pasta `build` e use o preset **Windows Desktop** em **Projeto → Exportar**. No computador original, a cópia local em `build/` já está pronta.

## Controles

- Clique/toque em três cartas do mesmo elemento. A terceira seleção resolve o combo automaticamente.
- Toque novamente em uma carta selecionada para desmarcar. Não é necessário que as cartas sejam adjacentes.
- O infinito substitui qualquer um dos cinco elementos. Três infinitos usam o elemento do líder. Três Capsules curam; coringas não substituem Capsule nesta implementação.
- Os números fazem parte da potência da carta. Dano de combo = soma dos três números × 20; cura = soma × 35, limitada ao HP máximo.
- Clique em um inimigo para selecionar o alvo. Dano excedente passa para o próximo inimigo vivo.
- Combine cartas para encher a skill daquele aliado. Clique no aliado para ativar a skill quando estiver em 100.
- Clique na coroa para ativar a liderança. Ela fica indisponível por três turnos após o uso.
- Após vitória ou derrota, **Fases** inicia uma partida com três rounds.

A abertura reproduz deliberadamente o momento do mockup: **round 3/3, 2840/3200 HP e chefe com 1850/4000 HP**. O primeiro trio possível é Dragon da primeira linha + Dragon da segunda linha + qualquer infinito.

## O que está implementado

- Seis cenas de interface independentes: conta, campo, HP/round, BAG, tabuleiro e navegação.
- Cinco slots aliados, quatro slots inimigos (três ocupados na composição aprovada).
- Doze botões de cartas e seis previews; sete Resources de cartas usam recortes `AtlasTexture` da arte original.
- Resources de personagens, bioma e configuração da fase.
- Fila BAG real, seleção, validação, reposição, dano, cura, contra-ataque, skills, liderança, rounds, vitória e derrota.
- Persistência local das recompensas da conta em `user://ilha_digital_profile.json`.
- Equipe, Invocação e Loja permanecem reservados, conforme o escopo inicial. Não foram criadas telas extras.

## Fidelidade e limites da arte

A tela inicial foi capturada no renderizador OpenGL do Godot e comparada em RGB com o PNG aprovado: **zero pixels diferentes** na resolução nativa, com a conta padrão. O resultado verificável está em `output/verification/pixel_report.json`.

O mockup é uma pintura única. Para não recriar nem alterar os personagens, a ilha e as criaturas continuam integradas ao painel fixo do campo. Os slots têm interação e estado de combate, mas não são sprites recortados com transparência. Inimigos derrotados continuam desenhados no cenário, com HP zerado e alvo desativado. Separação real, remoção visual de inimigos e troca de formações exigiriam arte do chão oculto atrás deles. Nenhuma dessas partes foi inventada nesta entrega.

Cartas são recortes independentes da mesma pintura. Abertura idêntica não significa congelar o jogo: depois de uma ação, as cartas, números de HP, preenchimentos das barras e mensagem de combate mudam. Textos numéricos novos usam a fonte de interface do Godot, pois a fonte original do desenho não foi fornecida. Os valores impressos nas sete faces são fixos (4, 7, 6, 9, 8, 5 e 10).

O runtime Windows local usa o binário Godot já instalado e um pacote `.pck` exportado. As licenças do runtime estão junto dele. Não é um APK, e não foi validado em aparelho Android/iOS.

## Estrutura

```text
app/main.tscn
  BattleScreen
    BattleController
    AccountHUD
    Battlefield
      Allies/AllySlot01…05
      Enemies/EnemySlot01…04
      Leader
    CombatHUD
    BagPreview/Cards/Next01…06
    AttackBoard/Slots/CardSlot01…12
    BottomNavigation/Buttons
```

`battle/model` guarda o estado; `battle/rules` valida combos e resolve dano; `battle/battle_controller.gd` sequencia os turnos. As cenas visuais recebem sinais do controlador. `data` contém definições editáveis e `autoload` mantém conta/salvamento.

`tools/build_scenes.py` regenera cenas e retângulos de atlas sem processar pixels. As cenas e Resources gerados já estão no projeto; Python não é necessário para jogar.

## Verificação

Troque `godot` pelo executável Godot disponível no seu PATH:

```powershell
godot --headless --editor --path . --import
godot --headless --path . --script res://tests/test_battle.gd -- --test
godot --path . --script res://tests/capture_layout.gd -- --test
python tools/verify_pixels.py
```

A captura exige renderizador gráfico; não use `--headless` nesse comando. A comparação exige Pillow. `--test` evita carregar ou salvar a conta pessoal. Os testes cobrem regras, fila, hitbox real, bloqueio de entrada, skills, cura, rounds, vitória, derrota e cancelamento de resolução ao reiniciar.

Os arquivos já removidos da versão anterior no Git não foram restaurados. Esta implementação não depende deles.
