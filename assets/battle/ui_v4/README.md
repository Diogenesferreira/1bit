# Selos v4 — estudo substituído

> Estes recortes foram substituídos pelo pacote canônico com molduras e folhas
> de carga em `assets/battle/ui_v9/`.

Os cinco PNGs `canonical_seal_*_v1.png` são recortes sem reamostragem de
`mockup_ui_selos_fragmento_v1.png`. Eles preservam exatamente retrato, moldura,
arco de skill, socket elemental, proporção e acabamento aprovados.

Cada definição de personagem aponta para seu próprio campo `selo`. Portanto,
personagens futuros recebem um novo composite nessa mesma geometria; a cor é
determinada por uma das cinco afinidades: vermelho, azul, verde, amarelo ou
roxo. Wild e Cura não recebem selo.

`canonical_seals_preview_v1.png` reúne os cinco recortes lado a lado para
conferência visual.

O selo verde possui dois estados porque era o selecionado no conceito:
`canonical_seal_nature_base_v1.png` remove o halo permanente, enquanto
`canonical_seal_nature_v1.png` preserva intacto o recorte carregado e aparece
somente quando a skill chega ao máximo.

Não redesenhar essas molduras por código. A lógica pode apenas escurecer ou
revelar os blocos já existentes e acrescentar feedback temporário de clique.

Origem: recorte raster determinístico; nenhuma nova geração foi aplicada.
