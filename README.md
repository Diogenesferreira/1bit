# Ilha Digital — Terminal

Projeto Godot 4 reconstruído com o kit oficial em `design/ilha-digital-godot-kit`, na resolução **1024 × 1600**. A cena inicial atual é a etapa de homologação visual: cenário, personagens, inimigos, anéis, chips, cartas, valores e botões existem como nós separados. O módulo de regras continua no projeto, mas será conectado a esta interface depois da aprovação visual.

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

## Homologação visual

- Clique em qualquer carta para conferir o estado selecionado.
- Clique nos inimigos para abrir ou fechar a mira e o painel do alvo.
- **F1:** tela padrão; **F2:** duas cartas e liderança ativa; **F3:** skill pronta; **F4:** alerta; **F5:** deserto; **F6:** chefe sozinho.
- As capturas reais do Godot ficam em `output/verification/terminal_*.png`. A tela padrão, já composta por controles separados, obteve similaridade RGB global de **98,45%** contra a referência oficial do kit.

## O que está implementado

- Seis cenas de interface independentes: conta, campo, HP/round, BAG, tabuleiro e navegação.
- Cinco slots aliados, quatro slots inimigos (três ocupados na composição aprovada).
- Doze botões de cartas e seis previews; sete Resources de cartas usam recortes `AtlasTexture` da arte original.
- Resources de personagens, bioma e configuração da fase.
- Fila BAG real, seleção, validação, reposição, dano, cura, contra-ataque, skills, liderança, rounds, vitória e derrota.
- Persistência local das recompensas da conta em `user://ilha_digital_profile.json`.
- Equipe, Invocação e Loja permanecem reservados, conforme o escopo inicial. Não foram criadas telas extras.

O layout anterior foi restaurado após a revisão rejeitada do topo. A UI agora tem componentes independentes: `AtlasValue` mantém um Label para cada texto/valor, `AtlasGauge` é um ProgressBar, e cada carta tem filhos `Face`, `Number` e `Selection`. A BAG usa as mesmas cartas em modo de preview; os botões inferiores possuem sua própria arte. Valores da conta, HP, round, skills e números das cartas são ligados aos dados do jogo.

As molduras usam o atlas original com as áreas dos componentes removidas durante a renderização. Assim, esconder ou mover um componente não deixa uma cópia pintada no fundo. Os valores iguais aos da referência usam sua grafia original, preservando o visual; quando o valor muda, o Label mostra o novo texto no mesmo lugar. As barras sempre têm `value` e `max_value` reais, com a aparência original preservada no estado inicial.

## Fidelidade e limites da arte

A tela inicial foi capturada no renderizador OpenGL do Godot e comparada em RGB com o PNG aprovado: **zero pixels diferentes** na resolução nativa, com a conta padrão. O resultado verificável está em `output/verification/pixel_report.json`.

O mockup é uma pintura única. Para não recriar nem alterar os personagens, a ilha e as criaturas continuam integradas ao painel fixo do campo. Os slots têm interação e estado de combate, mas não são sprites recortados com transparência. Inimigos derrotados continuam desenhados no cenário, com HP zerado e alvo desativado. Separação real, remoção visual de inimigos e troca de formações exigiriam arte do chão oculto atrás deles. Nenhuma dessas partes foi inventada nesta entrega.

Cartas usam a arte original, com o número separado em um componente de texto. `CardDefinition.power` é a força usada na gameplay e exibida na UI; `printed_power` registra o número que existia no atlas, para preservar sua grafia quando os valores coincidem. Alterar `power` atualiza o número na carta e na BAG, inclusive sem trocar de elemento. Textos novos usam a fonte padrão do Godot, pois a fonte original do desenho não foi fornecida.

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
godot --headless --path . --script res://tests/test_ui_components.gd -- --test
godot --path . --script res://tests/capture_layout.gd -- --test
godot --path . --script res://tests/capture_ui_layers.gd -- --test
python tools/verify_pixels.py
```

A captura exige renderizador gráfico; não use `--headless` nesse comando. A comparação exige Pillow. `--test` evita carregar ou salvar a conta pessoal. Os testes cobrem regras, fila, hitbox real, bloqueio de entrada, skills, cura, rounds, vitória, derrota e cancelamento de resolução ao reiniciar.

`capture_ui_layers.gd` esconde valores, uma barra, uma carta, um preview e um botão, e verifica no framebuffer que a imagem de fundo não mantém esses elementos. A captura `ui_layers_hidden.png` é apenas uma verificação técnica; não é o visual da partida.

Os arquivos já removidos da versão anterior no Git não foram restaurados. Esta implementação não depende deles.
