# ADR 0013 — Capacidade declarada: estimativa, não estoque nem contrato

**Data:** 2026-08-26 · **Estado:** aceita

## Contexto

Marketplace convencional modela **estoque**: uma quantidade existente que decrementa a cada
venda. Produção artesanal familiar não funciona assim — o item é feito sob demanda, e o
limite real é quanto a pessoa consegue fazer numa semana sem adoecer (Epic 2). Modelar
estoque aqui seria importar um pressuposto industrial (`CLAUDE.md` §1.1). O Epic 4 (pedido
coletivo) precisa desse dado; adicioná-lo depois exigiria revisitar todo o catálogo.

A revisão de agosto (2.5) pediu que a visão agregada fosse de todos os membros, não só da
coordenação; e (2.8) que o registro do histórico fosse justificado por uso, não por
pesquisa.

## Decisão

- Campos por produto: `capacity_quantity` (inteiro, opcional) e `capacity_period`
  (`day` / `week` / `month`, padrão semana), mais `lead_time_days` (prazo típico).
- **É declaração.** O rótulo diz "quanto você consegue fazer, mais ou menos" e "é só uma
  estimativa sua; ninguém cobra isso". Sem penalidade, sem alerta de descumprimento, sem
  índice de confiabilidade — isso seria rating por outro nome (§3.2).
- **Normalização semanal com aritmética inteira:** dia × 7, semana × 1, mês × 12 ÷ 52
  (divisão inteira). Em Ruby (`Product::Capacity.weekly`) e em SQL
  (`Product::Capacity::WEEKLY_SQL`), idênticos. É aproximado por natureza; a interface diz
  "aproximado".
- **Histórico = eventos.** Toda mudança gera `product.capacity_changed` com
  `quantity_from/to` e `period_from/to` (ADR 0006). Sem tabela própria. O empreendimento vê
  o próprio histórico na tela de edição e o recebe no export — esse é o motivo de existir;
  que também sirva à pesquisa é consequência (§2).
- **Capacidade da rede** (`/capacidade-da-rede`): soma semanal por nome de produto
  (normalizado sem acento/caixa) e nº de empreendimentos, visível a **todos os membros
  logados**; nunca na vitrine pública. Sem ranking, sem comparação por loja.
- **"Pausado"** é estado do produto — "não estou produzindo agora" — distinto de "sem
  estoque". Some da vitrine e do catálogo; volta ao despausar.

## Alternativas consideradas

- **Estoque decremental.** Recusado pelo §1.1: pressuposto industrial.
- **Capacidade só por semana.** Mais simples, mas pão é por dia e bordado é por mês; pedir
  que a pessoa converta de cabeça é pedir erro.
- **Capacidade obrigatória.** Recusado: o cadastro pelo celular é o ponto mais provável de
  abandono (Epic 2, nota); só nome e preço são obrigatórios.
- **Tabela de histórico própria.** Redundante com o log de eventos.
- **Visão agregada só para a coordenação.** Exigiria criar um papel antes do Epic 5 e
  contraria Ostrom (monitoramento por quem é afetado).

## Consequências

- O Epic 4 lê `weekly_capacity` como **estimativa**, nunca como limite rígido; a decisão
  de aceitar ou recusar continua da pessoa (Epic 3.6).
- Tensão declarada: cada família vê a declaração das outras (somada por produto). É o
  oposto de segredo comercial — coerente com cooperação, mas pode constranger. Observar.
