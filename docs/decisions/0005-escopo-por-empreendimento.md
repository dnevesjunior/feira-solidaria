# ADR 0005 — Escopo por empreendimento: coluna `enterprise_id`, concern e query objects

**Data:** 2026-08-25 · **Estado:** aceita

## Contexto

`CLAUDE.md` §3.5: toda consulta a dado de loja é escopada por empreendimento no nível mais
baixo possível, não por filtro na controller; vazamento entre lojas é falha de tese. Epic
0.5 pede a estratégia definida agora e um teste de isolamento escrito antes de existir a
segunda loja. Não existe modelo `Enterprise` no Epic 0.

## Decisão

- **Multitenancy por coluna:** toda tabela de dado de loja tem `enterprise_id NOT NULL` com
  chave estrangeira. Sem schema por tenant, sem banco por tenant — 30 empreendimentos não
  justificam a complexidade.
- **`Current.enterprise`** (`ActiveSupport::CurrentAttributes`) carrega o empreendimento da
  requisição, definido pela camada de autenticação a partir da associação membro ↔
  empreendimento (Epic 1).
- **Concern `EnterpriseScoped`** em todo modelo com `enterprise_id`: declara
  `belongs_to :enterprise`, o escopo `of(enterprise)` e `for_current`, que levanta
  `EnterpriseScoped::MissingScope` se `Current.enterprise` for nulo. Falhar alto é melhor
  do que devolver tudo.
- **Query objects** (`app/queries/`, base `ApplicationQuery`) recebem o empreendimento no
  construtor. Leituras que cruzam empreendimentos (hub, catálogo agregado, visão de
  capacidade da rede) são query objects explícitos e nomeados — a exceção fica visível no
  código, não escondida num `unscoped`.
- **Sem `default_scope`.** Ele vaza em associações, é silenciosamente removido por
  `unscoped`, e esconde o escopo em vez de expô-lo.
- **Teste de schema** (`spec/schema/enterprise_scope_spec.rb`): para cada modelo ActiveRecord
  cuja tabela tenha coluna `enterprise_id`, afirma que inclui `EnterpriseScoped`. Verde por
  vacuidade no Epic 0; obriga o Epic 1 a seguir o padrão. É o teste "antes da segunda loja".

## Alternativas consideradas

- **`default_scope { where(enterprise: Current.enterprise) }`.** Aparentemente mais seguro
  por ser automático. Recusado pelos motivos acima e porque a mágica torna as exceções
  legítimas (hub, agregados) invisíveis.
- **Gems de multitenancy (`acts_as_tenant`, `apartment`).** Dependência para um problema que
  cabe em um concern de 20 linhas. `apartment` (schema por tenant) é desproporcional.
- **Row-level security no PostgreSQL.** Defesa em profundidade real, mas exige sessão de
  banco por tenant e complica Solid Queue e migrations. Fica como possibilidade se um
  incidente mostrar que a camada de aplicação não bastou.

## Consequências

- Epic 1 cria `Enterprise` e a primeira tabela escopada, e o teste de schema passa a morder.
- Toda controller que serve dado de loja obtém dados via `Model.for_current` ou query object;
  nunca via `Model.where(enterprise_id: params[...])`.
