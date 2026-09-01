# Moldura v5 — estudo substituído

> Esta versão foi substituída pelo pacote canônico com geometria final e nove
> estágios de carga em `assets/battle/ui_v9/`.

`fragment_seal_frame_master_v1.png` é a moldura original fornecida pelo autor
do jogo. O arquivo possui 1254×1254 pixels e transparência RGBA real.

## Regra permanente

- Existe uma única geometria de moldura para todos os personagens.
- A moldura não é redesenhada, recortada ou recolorida por IA.
- A arte do personagem fica atrás da janela central transparente.
- Os oito espaços superiores são preenchidos dinamicamente conforme a skill.
- Espaços vazios recebem carvão escuro; espaços carregados recebem a cor do
  elemento do personagem.
- O socket lateral usa a mesma cor elemental.
- Skill completa acende os oito espaços e pulsa; não cria moldura retangular.
- Wild e Cura continuam sem personagem e sem moldura.

## Cinco cores

- Dragão/Fogo: vermelho fosco.
- Cavaleiro: azul aço.
- Natureza: verde musgo.
- Luz: amarelo/dourado.
- Trevas: roxo.

## Ordem das camadas no Godot

1. fundo escuro da janela;
2. sprite recortado do personagem;
3. PNG da moldura original;
4. preenchimentos internos e socket;
5. interação da skill.

## Contrato de retrato

O selo não usa o corpo inteiro em miniatura. A janela interna aplica escala
`cover`, prioriza cabeça e tronco e corta o excesso na parte inferior, seguindo
o princípio observado nos retratos `ch_` usados como referência.

Cada personagem pode declarar:

- `retrato`: asset exclusivo de busto, recomendado para a arte final;
- `retrato_recorte`: região do atlas, quando necessário;
- `retrato_zoom`: ajuste fino de escala, padrão `1.0`;
- `retrato_offset`: deslocamento fino sem alterar a moldura.

Sem um asset `retrato`, a cena deriva automaticamente um busto da arte completa
com escala `cover`. Moldura, janela e posições dos elementos permanecem fixas.

Origem: cópia exata de `C:/Users/Jinsa/Downloads/moldura.png`. Nenhum prompt
de geração foi usado na imagem final.
