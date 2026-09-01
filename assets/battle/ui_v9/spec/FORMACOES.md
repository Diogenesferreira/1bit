# Formações de inimigo

Coordenadas dentro do palco (**888 × 558**). `cx` é o **centro horizontal da placa**, `y` o topo dela.
O sprite do inimigo fica 7 px abaixo da placa, centralizado nela.

| fase | inimigos | k | placa | sprite | posições (cx, y) |
|---|---|---|---|---|---|
| Boss | 1 | 6 | 192×72 | 330 | (444, 34) |
| Dupla | 2 | 6 | 192×72 | 236 | (256, 44) · (632, 44) |
| Trio | 3 | 4 | 128×48 | 190 | (154, 26) · (444, 214) · (734, 26) |
| Especial | 5 | 4 | 128×48 | 150 | (124, 18) · (444, 18) · (764, 18) · (278, 272) · (610, 272) |

Regras:
- Fases normais alternam **3 → 2 → boss** (a plaquinha STAGE mostra 3 nós; o último é o boss).
- Fases especiais chegam a **5** e usam a mesma placa do trio — a placa **nunca** passa de k=6.
- O trio é escalonado em profundidade: dois atrás, um à frente no centro.
- Na formação de 5, a fileira da frente fica 272 px abaixo do topo, deixando a plaquinha STAGE livre.
- Clamp de segurança: `x = clamp(cx - placa/2, 8, 888 - placa - 8)`.
