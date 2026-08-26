# ADR 0015 — Pedido roteado por WhatsApp, sem pagamento, sem chat, sem automação

**Data:** 2026-08-26 · **Estado:** aceita

## Contexto

`CLAUDE.md` §3.1: a plataforma não intermedia pagamento em reais — nenhum gateway, split ou
custódia; a liquidação acontece fora. Motivo: intermediar pagamento aciona o regime de
instituição de pagamento (BCB) e inviabiliza um piloto de extensão. Epic 3: o pedido é
roteado por mensagem estruturada de WhatsApp via `wa.me`, sem API oficial, sem chat
interno, com transições manuais. A revisão de agosto (2.3) apontou o elo frágil: `wa.me`
abre o WhatsApp no aparelho **do comprador**; se ele fechar a janela, a loja não sabe.

## Decisão

- **Pedido pertence a um empreendimento.** Cesta com itens de várias lojas vira vários
  pedidos, e a interface diz isso antes de enviar.
- **Nada de dinheiro.** Sem gateway, sem carteira, sem Pix integrado, sem coluna de
  pagamento. Teste de tese varre `Gemfile.lock` e `app/`. "Integrar Pix para facilitar"
  é recusado por este ADR; se insistirem, novo ADR de recusa.
- **Roteamento honesto.** O pedido é criado ao confirmar; a página do pedido tem o botão
  "Abrir no WhatsApp" e o **toque** registra `order.routed`. Roteado = o comprador abriu
  o WhatsApp; **não** = a loja leu. O painel mostra todo pedido, marcando os que o
  comprador não abriu. Fallback: mensagem copiável na página.
- **Mensagem** (`Order::WhatsappMessage`): código curto, itens, quantidades, valores,
  total, nome, observação e link do pedido; ≤ 1.500 caracteres, ≤ ~10 linhas para dois
  itens — lida no celular sem rolar.
- **Sem chat interno.** A conversa é no WhatsApp, onde as pessoas já estão.
- **Transições manuais** pelo empreendimento: recebido → confirmado → concluído; recusado;
  cancelado. Nada por decurso de prazo. Ao concluir, registra-se o desfecho (pago e
  entregue: sim / parcial / não) — sem cobrança, sem verificação, sem consequência.
- **Capacidade é aviso, nunca bloqueio** (`Order::CapacityWarning`): só o empreendimento
  vê; o produto não some; o comprador não é avisado.
- **Painel sem métrica**: abertos, confirmados, encerrados. Sem funil, gráfico ou meta.

## Alternativas consideradas

- **API oficial do WhatsApp (Cloud API).** Entregaria a mensagem à loja sem depender do
  comprador. Exige conta comercial Meta, número dedicado, custo por conversa e um terceiro
  no caminho de cada pedido. Recusada para a v1; "se houver volume, é outra conversa".
- **Aviso por e-mail à loja.** Este público não usa e-mail (ADR 0007).
- **Marcar `routed` ao criar.** Mais simples, menos verdadeiro.
- **Notificação push / PWA.** Depende de permissão e de navegador; fica como possibilidade.

## Consequências

- Sucesso do roteamento depende de o comprador apertar um botão; o painel torna o
  problema visível em vez de escondê-lo.
- O Epic 4 (pedido coletivo) herda a regra: rateio propõe, pessoa confirma, dinheiro fora.

## Rastro teórico

`CLAUDE.md` §3.1 e §3.6; Epic 3.4–3.6. A recusa do painel de metas responde a
Scholz (2016) sobre intensificação do trabalho por métricas de plataforma.
