# Lore e padrão de personagens

> Documento de direção inicial. Nomes próprios e acontecimentos ainda são provisórios; as regras visuais e de construção abaixo formam o padrão a ser seguido nos próximos testes.

## Premissa do mundo

O mundo é atravessado por **Fragmentos**, pequenas unidades de memória e energia que sustentam matéria, magia e lembranças. Quando uma região perde estabilidade, seus Fragmentos se embaralham: biomas se deformam, criaturas sofrem corrupção e ruínas de épocas diferentes passam a coexistir.

Humanos, povos-fera, espíritos e construtos vivem nesse mesmo mundo. Nenhuma espécie é automaticamente heroica ou vilã. O grupo do jogador é formado por viajantes capazes de sincronizar Fragmentos e restaurar — ou alterar — regiões instáveis.

Na batalha, as cartas representam Fragmentos capturados no ambiente. Combinar três não cria um objeto físico no campo: funde energia na própria mão e a envia ao aliado compatível, que a acumula e transforma em ataque, defesa ou cura.

Os aliados sincronizados permanecem ancorados em **Selos de Fragmento** na base
da arena. O retrato no selo representa o vínculo ativo; quando recebe energia
suficiente ou executa uma ação, o aliado manifesta temporariamente seu corpo no
campo. Os inimigos não usam selos porque já habitam fisicamente aquele lugar.

## Famílias de personagens

- **Humanos:** guerreiros, magos, estudiosos, curandeiros e exploradores. Ajudam o jogador a se reconhecer no mundo e ampliam as possibilidades de roupa, cultura e profissão.
- **Criaturas heroicas:** dragões, feras e espécies originais inteligentes. São a assinatura fantástica do jogo, não simples mascotes.
- **Espíritos:** seres ligados a memórias, fenômenos e biomas. Podem ter silhuetas menos anatômicas.
- **Construtos:** máquinas, armaduras vivas e guardiões antigos. Explicam tecnologia e civilizações perdidas.
- **Corrompidos:** qualquer uma das famílias acima afetada pela instabilidade. Corrupção é uma condição, não uma espécie.

O elenco deve permanecer misto. Como referência, uma equipe de cinco pode ter dois ou três humanos e o restante dividido entre criaturas, espíritos ou construtos.

## Afinidades

Afinidade define a maneira de manipular Fragmentos; não define caráter.

| Afinidade | Ideia central | Formas e motivos recorrentes |
|---|---|---|
| Dragão | impulso, coragem, transformação | garras, chifres, diagonais fortes |
| Cavaleiro | disciplina, proteção, técnica | placas, escudos, formas retas |
| Natureza | adaptação, crescimento, ciclo | folhas, galhos, curvas orgânicas |
| Luz | revelação, cura, orientação | estrelas simples, lanternas, simetria |
| Trevas | segredo, memória, passagem | máscaras, luas, runas quadradas |

O marcador de afinidade fica na UI como um pequeno quadrado de cor fosca, sem
glifo interno. A arte-base do personagem deve continuar compreensível em preto,
cinza e branco, sem depender de cor.

## Padrão visual universal

1. Pixel art monocromática com grafite `#27272F`, cinzas intermediários e branco suave.
2. Silhueta reconhecível antes dos detalhes internos.
3. Um motivo principal e, no máximo, um objeto marcante por personagem.
4. Corpo inteiro, leitura em visão elevada de três quartos e base dos pés bem definida.
5. Contorno exterior firme; hachuras e pontilhado apenas para volume.
6. Humanos e criaturas compartilham densidade, escala aparente e espessura de contorno.
7. Evitar aura permanente, partículas soltas e apêndices gigantes; esses recursos ficam para animações ou raridades especiais.
8. O sprite mestre deve ter fundo transparente e margem de segurança para armas, orelhas, caudas e capas.

### Escala de complexidade

- **Comum:** silhueta simples, um acessório, poucos materiais.
- **Raro:** segundo motivo discreto, roupa/armadura mais elaborada.
- **Épico:** pose e ornamentos especiais, ainda legíveis no tamanho de batalha.
- **Chefe:** pode ultrapassar seu espaço visual e usar assimetria, mas precisa preservar áreas livres para HP, afinidade e seleção.

## Elenco inicial de teste

| ID provisório | Família | Afinidade | Papel visual |
|---|---|---|---|
| Draco de Brasa | criatura heroica | Dragão | atacante compacto e impulsivo |
| Guardião de Ferro | humano | Cavaleiro | defensor de espada e escudo |
| Maga do Bosque | humana | Natureza | suporte com cajado de folha |
| Clériga Astral | humana | Luz | curandeira com lanterna-estelar |
| Oráculo Chacal | criatura heroica | Trevas | conjurador ágil de runas |

Esses nomes descrevem função e podem mudar quando culturas, regiões e idiomas do mundo forem definidos.

## Ficha para novos personagens

Ao criar alguém novo, registrar:

- nome e ID interno;
- espécie/família e origem;
- afinidade e função em combate;
- silhueta em uma frase;
- motivo principal e objeto marcante;
- desejo, medo e conflito pessoal;
- relação com um bioma ou facção;
- habilidade ativa, passiva e comportamento de animação;
- versão comum e possíveis evoluções sem perder a silhueta.

## Decisões futuras de lore

- Nome definitivo do mundo e dos Fragmentos.
- Por que apenas alguns viajantes conseguem sincronizá-los.
- Origem da instabilidade e custo de restaurar um bioma.
- Culturas humanas e não humanas de cada região.
- Relação entre evolução de personagem, raridade e monetização sem quebrar a coerência narrativa.
