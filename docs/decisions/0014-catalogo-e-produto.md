# ADR 0014 — Catálogo: a loja é a unidade; produto não tem página própria

**Data:** 2026-08-26 · **Estado:** aceita

## Contexto

Epic 2.4: catálogo agregado da rede, com a mesma ordenação rotativa do hub, busca por
nome, sem "mais vendidos", "em alta" ou recomendação; cada item leva à vitrine do
empreendimento — a pessoa deve saber de quem está comprando. Epic 2.3: categorias só com a
feira; 2.1: unidade de venda em texto livre controlado.

## Decisão

- **Produto não tem página própria.** O card do catálogo leva a `/<loja>#produto-<id>`.
  A vitrine ganha a seção "O que fazemos". Comprar é falar com a loja.
- **Ordem do catálogo** = mesma regra de governança do hub (`hub_ordering`, ADR 0011),
  aplicada sobre `products.id` com a semente do dia, publicada no rodapé. Teste de tese
  garante que o SQL não referencia `page_views`, `events`, `orders` nem contagens.
- **Categorias:** tabela existe, nasce vazia; produto tem `category_id` opcional; filtro e
  seleção só aparecem quando `Category.any?`. A lista entra por seed quando a feira
  definir — é "atributo de organização, nunca de priorização".
- **Unidade de venda:** lista sugerida (`unidade, par, dúzia, kg, 500 g, 100 g, pote, litro,
  pacote, metro, fatia`) + "outra" em texto curto. Sem taxonomia: o vocabulário da feira
  cabe.
- **Preço:** `bigint` em centavos lido como `Amount` (ADR 0004); entrada em pt-BR
  ("12,50") por `Amount.parse_brl`, sem ponto flutuante; "12.50" é recusado com mensagem
  que ensina o formato. Sem sugestão de preço, sem comparação, sem "acima da média".
- **Mínimo obrigatório:** nome e preço para salvar; ao menos uma foto para publicar. Até
  4 fotos, mesma pipeline do Epic 1 (ADR 0010).

## Alternativas consideradas

- **Página de produto** (`/produto/123`). Mais compartilhável; recusada pelo 2.4 — o
  produto solto esconde quem produz.
- **Categorias provisórias do desenvolvedor.** Recusado pelo 2.3.
- **Máscara de preço em JS.** Adiada: avaliar no teste real se "12,50" digitado à mão
  atrapalha.

## Consequências

- Variação de grafia na unidade ("kg"/"quilo") é aceita; a agregação da rede é por nome de
  produto, não por unidade.
- Compartilhar "esse bolo" no WhatsApp leva à loja com âncora; se a feira pedir link de
  produto, reavaliar.
