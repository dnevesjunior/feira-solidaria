# ADR 0011 — Parâmetros de governança em banco, com default declarado no código

**Data:** 2026-08-25 · **Estado:** aceita (formato provisório até o Epic 5)

## Contexto

`CLAUDE.md` §3.4: parâmetros de governança — regra de ordenação, taxa, rateio, emissão —
vivem em banco, versionados, com valor-padrão declarado, nunca como constante. O Epic 1.2
pede que a ordenação do hub já seja lida de um objeto de configuração, para que o Epic 5
apenas passe a permitir alterá-la. Existe hoje um único parâmetro: `hub_ordering`.

## Decisão

- Tabela `governance_parameters(key, value jsonb, note, created_at)`. **Cada mudança é
  uma linha nova**; o vigente é o registro mais recente da chave. Registros são
  `readonly?` no modelo (nunca `UPDATE`).
- Defaults declarados em `Governance::DEFAULTS` (`hub_ordering: "daily_rotation"`).
  `Governance::Parameter.value_for(:hub_ordering)` devolve o vigente ou o default. Chave
  fora dos defaults levanta erro: não existe parâmetro "de fato" que o código não conheça.
- **Sem interface de alteração.** O Epic 5 acrescenta autor, valor anterior, justificativa
  textual, o processo de assembleia e o evento correspondente (§3.4) — sem mudar quem lê.
- Regra vigente: `daily_rotation` — embaralhamento determinístico com semente = data (fuso
  de São Paulo). Igual para todo mundo no mesmo dia; a semente é **publicada no rodapé do
  hub** com a frase "a ordem muda todo dia e não depende de vendas, cliques ou de quem
  chegou primeiro". A regra é observável, que é o ponto.

## Alternativas consideradas

- **Constante `HUB_ORDERING = :daily_rotation`.** Recusado pelo §3.4, mesmo sendo o único
  valor possível hoje: o custo de ter a tabela agora é uma migration; o custo de introduzi-la
  no Epic 5 seria refatorar quem lê.
- **Rotação por deslocamento** (ordem fixa girando um por dia). Preserva ordem relativa —
  quem cadastrou depois de X sempre vem depois de X. Recusado; embaralhar com semente é
  mais justo e igualmente observável.
- **Aleatório por requisição.** Mais "justo" estatisticamente, mas não observável: duas
  pessoas não veem a mesma ordem e ninguém consegue auditar a regra.

## Consequências

- Tensão declarada: a tabela nasce sem autor/justificativa. Não há violação porque não há
  mudança possível; o Epic 5 precisa trocar o formato **antes** da primeira alteração.
- Toda regra nova de ordenação entra em `HubOrdering` e é escolhida pelo parâmetro.
