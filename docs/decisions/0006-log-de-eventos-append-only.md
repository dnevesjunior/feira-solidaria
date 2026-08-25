# ADR 0006 — Log de eventos append-only, imposto no banco, sem dado pessoal no payload

**Data:** 2026-08-25 · **Estado:** aceita

## Contexto

`CLAUDE.md` §3.3: o log de eventos é cidadão de primeira classe; toda transição de estado
relevante gera registro append-only com ator, timestamp e payload; isso é impossível de
reconstruir retroativamente. Epic 0.6 pede imposição no modelo e no banco, e uma API
trivial de registro.

A revisão de agosto (item 2.1) identificou um conflito: o Epic 3 exige expurgo de dados de
comprador (3.9), e o Epic 3.8 prevê `order.created` — que, se carregasse nome e telefone
do comprador no payload, seria imutável e indeletável. Append-only e expurgo só coexistem
se o payload não contiver dado pessoal.

## Decisão

Tabela `events`:

| coluna | tipo | nota |
|---|---|---|
| `kind` | string, not null | ex.: `enterprise.published` |
| `actor_type`, `actor_id` | polimórfico, nulo | nulo = sistema ou comprador sem conta |
| `subject_type`, `subject_id` | polimórfico, nulo | entidade alvo |
| `payload` | jsonb, not null, default `{}` | |
| `occurred_at` | timestamptz, not null | quando aconteceu no domínio |
| `created_at` | timestamptz, not null | quando foi gravado |

Imposição em três camadas:

1. **Banco:** função + trigger `BEFORE UPDATE OR DELETE ON events` que levanta exceção.
   Nenhum cliente SQL, migration ou console escapa. Exige `schema_format = :sql`.
2. **ActiveRecord:** `Event#readonly?` retorna `persisted?` — cria-se, não se altera.
3. **Catálogo:** `Event::Catalog` registra cada `kind` com descrição e **allowlist de
   chaves de payload**. `kind` fora do catálogo ou chave fora da allowlist invalidam o
   registro. O catálogo é, ao mesmo tempo, o dicionário de dados dos eventos.

API: `Event.record(kind, subject:, actor: nil, payload: {}, occurred_at: Time.current)`.
Uma chamada. Se registrar for chato, ninguém registra.

**Regra de conteúdo:** o payload **nunca** contém dado pessoal de comprador — nome,
telefone, observação livre, nada. Só referências (`order_id`) e valores de domínio
(quantidades, valores, estados). O evento diz *que* um pedido foi criado e *o quê* continha;
*quem* comprou está no registro do pedido, que tem prazo de retenção e expurgo. Dados de
membros (nome de usuário criado, por exemplo) seguem a mesma regra: referência, não cópia.

Eventos do Epic 0: `user.created`, `user.password_reset_by_coordination`. Cada epic
acrescenta os seus ao catálogo.

## Alternativas consideradas

- **`paper_trail` / `audited`.** Auditoria de mudanças de coluna, bolt-on. Não é log de
  eventos de domínio; não registra "pedido roteado" ou "rateio executado"; e é mutável por
  desenho. Recusadas.
- **Só imposição no modelo.** Um `Event.update_all` ou um `psql` passam. Insuficiente para
  algo que o §3.3 chama de impossível de reconstruir.
- **`REVOKE UPDATE, DELETE` no papel do banco.** Bom complemento, mas o Rails usa um único
  papel para migrations e aplicação; o trigger é mais simples e vai junto no schema. Pode ser
  adicionado no VPS dedicado.
- **Payload com PII + crypto-shredding.** Cifrar PII com chave por comprador e apagar a
  chave no expurgo. Funciona, mas é mais complexo e mais fácil de errar do que simplesmente
  não gravar. Recusado.

## Limites

A regra "sem PII no payload" é garantida por allowlist e revisão, não por prova formal: um
`kind` cadastrado com uma chave errada pode vazar. É improvável, não impossível — e o
`CLAUDE.md` exige "impossível" apenas para a soma de unidades monetárias (§3.1).

## Consequências

- `db/structure.sql` em vez de `schema.rb`.
- Todo epic lista seus `kind`s e os registra no catálogo antes de emitir.
- O expurgo do Epic 3 opera sobre `orders`, não sobre `events`.
- O log é exportável pelo empreendimento junto com seus dados (Epic 1.5).

## Rastro teórico

`CLAUDE.md` §3.3 e §6: as transições registradas são o material empírico da pesquisa
(Epic 7), mas o registro existe primeiro porque serve ao empreendimento — histórico
próprio, exportável, não editável por ninguém, inclusive pela universidade.
