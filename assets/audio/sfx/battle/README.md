# SFX de cartas da batalha

Arquivos convertidos dos `.m4a` fornecidos em:

`heroes/forum_achado/Crusader- 17-12-13 (1)/sound/effects/`

Conversao: AAC mono 22.050 Hz para WAV PCM 16-bit mono 22.050 Hz. O WAV evita
uma segunda compressao com perdas e e adequado aos efeitos curtos e
potencialmente sobrepostos da batalha.

Mapeamento em `BattleSfx.gd`:

- `se_touch`: selecionar e desmarcar carta;
- `se_card_shuffle`: deslocamento BAG/NEXT;
- `se_gousei_hit`: fechamento/fusao do trio;
- `se_wildattack1`: ataque de trio somente de coringas;
- `se_countup`: atualizacao da contagem do combo;
- `se_card_shuffle`, `2` e `3`: variantes alternadas na redistribuicao.

`se_gousei_hit.wav` contem somente os primeiros 0,90 s do `se_gousei.m4a`,
com fade-out de 0,28 s a partir de 0,62 s. O original tem 8,87 s e produziria
sobreposicoes longas durante cascatas. Nenhum arquivo-fonte foi modificado.
