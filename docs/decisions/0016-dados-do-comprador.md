# ADR 0016 — Dados do comprador: só nome e WhatsApp, 90 dias, sem rastreio

**Data:** 2026-08-26 · **Estado:** aceita

## Contexto

Epic 3.2: dados do comprador são nome e WhatsApp, nada além — coletar o que não se usa é
violação de minimização (LGPD) e não serve a ninguém. Epic 3.9: prazo de retenção em ADR e
rotina de expurgo implementada. Epic 3.1: cesta sem login, sem cookie de rastreio, sem
identificação entre visitas. ADR 0006: nenhum dado pessoal no log de eventos.

## Decisão

- **Coleta:** `buyer_name` (2–80) e `buyer_phone` (E.164), mais observação livre
  opcional. Sem CPF, endereço, e-mail, nascimento. Teste de tese verifica o formulário e
  as colunas de `orders`.
- **Retenção:** nome, telefone e observação são apagados **90 dias** após o pedido
  fechar (concluído, recusado ou cancelado) ou **180 dias** após a criação, em qualquer
  estado. `PurgeBuyerDataJob`, diário. O pedido — itens, valores, estado, desfecho — fica:
  é dado do empreendimento. O estado **não** muda no expurgo (Epic 3.2).
- **Log de eventos:** `order.created` leva `item_count` e `total_cents`; nenhum evento leva
  nome, telefone ou observação. É o que torna o expurgo compatível com o append-only.
- **Telemetria:** o caminho `/pedidos/<token>` é normalizado para `/pedidos/:token` antes
  de contar; o token nunca entra em `page_views`.
- **Cesta em sessão:** cookie de sessão do Rails, criptografado, sem expiração persistente.
  Não identifica entre visitas nem entre aparelhos. É cookie estritamente necessário —
  sem banner.
- **Export:** o empreendimento recebe os dados do comprador enquanto retidos (ele já os tem
  no WhatsApp); depois, "dados expirados".
- **Página do pedido:** endereço por token de 20 caracteres (base58), não sequencial;
  quem tem o link vê o estado. Sem login.

## Alternativas consideradas

- **Reter indefinidamente** "porque pode ser útil". Recusado: minimização.
- **Apagar o pedido inteiro.** Recusado: itens e valores são o registro de venda do
  empreendimento, base da medição da v1.
- **Crypto-shredding** em vez de nulos. Desnecessário: os campos são poucos e apagáveis.
- **Conta para o comprador.** Recusado (Epic 3.1): pediria cadastro para comprar um bolo.

## Consequências

- Pendência que aparece depois de 90 dias não tem mais contato pela plataforma — a loja
  ainda tem a conversa no WhatsApp.
- O relatório `medicao:v1` usa só dados de pedido, nunca de comprador.
