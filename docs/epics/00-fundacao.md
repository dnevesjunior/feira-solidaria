# Epic 0 — Fundação

> Pré-requisito: ler `CLAUDE.md` inteiro.

## Objetivo

Ter um Rails em produção, com deploy automatizado, que sobe sozinho e não
constrange nenhuma das restrições dos epics seguintes.

Este epic não entrega nada visível para as famílias. Ele existe para que os
Epics 1–3 não precisem parar para resolver infraestrutura.

## Fora de escopo

Qualquer modelo de domínio (empreendimento, produto, pedido). Isso é Epic 1+.
Resistir à tentação de "já deixar criado".

---

## Escopo

### 0.1 Projeto Rails

- Rails na última versão estável, PostgreSQL, Hotwire.
- `pt-BR` como locale único. Timezone `America/Sao_Paulo`.
- Formatação de moeda em pt-BR (R$ 1.234,56).
- Sem `webpack`/bundler pesado se `importmap` ou `propshaft` bastar — peso
  importa (`CLAUDE.md` §3.6).

### 0.2 Decisões que precisam de ADR neste epic

Cada uma vira arquivo em `docs/decisions/`:

1. **Licença do repositório.** Antes do primeiro commit. Ver `CLAUDE.md` §5.1.
   Registrar a alternativa permissiva considerada e o motivo da recusa.
2. **Framework de teste** (Minitest ou RSpec).
3. **Alvo de deploy e custo mensal estimado.** Orçamento de extensão
   universitária. Registrar o teto.
4. **Tipo de valor monetário.** Inteiro em centavos + objeto de valor com
   unidade explícita. Ver 0.4.
5. **Estratégia de escopo por empreendimento** (multitenancy). Ver 0.5.

### 0.3 Autenticação

- Autenticação nativa do Rails, sem dependência externa pesada.
- **Login por e-mail é premissa frágil neste público.** Parte das pessoas usa
  apenas WhatsApp e pode não ter e-mail ativo. **Resolvido no Epic 0:**
  identificador é o telefone, e-mail é opcional, recuperação de senha é
  presencial pela coordenação (ADR 0007; revisão 2.4).
- Sem login social (dependência de terceiro + telemetria).
- Sem verificação por e-mail bloqueante no primeiro acesso.

### 0.4 Primitiva monetária

Criar antes de existir dinheiro no sistema, porque depois é refatoração cara.

- Objeto de valor com **inteiro na menor unidade + unidade explícita**
  (`:brl`, `:chiquinho`).
- Soma entre unidades distintas **levanta exceção**. Testar isso.
- Nenhum `float` ou `Float` em qualquer caminho de valor. Teste que percorre o
  schema e falha se aparecer coluna de ponto flutuante em campo monetário.
- Type customizado do ActiveRecord para persistência.

### 0.5 Escopo por empreendimento

- Definir a estratégia agora (coluna `enterprise_id` + escopo aplicado por
  padrão é suficiente; não precisa de schema por tenant).
- O escopo é aplicado no nível do modelo/query object, **não na controller**.
- Escrever o teste que prova o isolamento antes de existir a segunda loja.

### 0.6 Log de eventos (append-only)

A peça mais importante deste epic.

- Tabela `events` (ou nome equivalente): ator, tipo, entidade alvo, payload
  JSON, `occurred_at`, `created_at`.
- **Append-only:** sem `UPDATE`, sem `DELETE`. Impor no nível do modelo e,
  preferencialmente, com constraint/trigger no banco.
- API interna trivial de registrar: uma chamada, sem cerimônia. Se registrar um
  evento for chato, ninguém registra.
- Nenhum consumidor ainda. Só o registro.
- Documentar em ADR: por que append-only, e por que isto não pode ser adicionado
  depois (`CLAUDE.md` §3.3).

### 0.7 Telemetria própria

- Contagem de pageview e erro, em tabela própria, sem PII, sem cookie de
  rastreio, sem SDK externo (`CLAUDE.md` §3.3).
- Se houver monitoramento de exceção, garantir scrub de PII.

### 0.8 CI e deploy

- CI roda testes em cada push.
- Deploy automatizado a partir da branch principal.
- Healthcheck.
- Backup de banco automatizado, com **restore testado pelo menos uma vez neste
  epic**. Backup não testado não é backup.

### 0.9 Seeds realistas

- Nomes de empreendimento, produtos e preços plausíveis de uma feira artesanal
  da Baixada Santista. **Não** `Product 1`, `Test Store`, `Lorem ipsum`.
- Motivo: as primeiras demonstrações para as famílias e para a coordenação
  acadêmica saem do seed. Seed falso e genérico produz reunião ruim.

### 0.10 README

- Como subir local em menos de 10 minutos.
- Estrutura de pastas e onde ficam ADRs e epics.
- Aponta para `CLAUDE.md` como fonte das restrições.

---

## Pronto significa

Comportamento observável, não artefato:

- [ ] `git push` na branch principal resulta em site no ar, sem intervenção
      manual.
- [ ] Um desenvolvedor novo clona, roda um comando, e tem ambiente funcional
      com dados de seed que parecem reais.
- [ ] Somar 10 reais com 10 chiquinhos levanta exceção — e existe teste que
      prova.
- [ ] Um registro de evento gravado não pode ser alterado nem apagado pela
      aplicação — e existe teste que prova.
- [ ] Um backup foi restaurado com sucesso em ambiente limpo, ao menos uma vez.
- [ ] Nenhuma requisição de terceiro sai da página (verificado no inspetor de
      rede).
- [ ] Existem os ADRs 0001–0008 em `docs/decisions/` (licença, testes, deploy,
      valor monetário, escopo, log de eventos, autenticação, telemetria).

---

## Ao final do epic

Responder: **quais decisões deste epic contradizem ou tensionam o `CLAUDE.md`?**

---

## Encerramento — 2026-08-25

### Checklist

| Critério | Estado | Prova |
|---|---|---|
| `git push` na `main` → site no ar | ⚠️ parcial | App no ar via `kamal deploy` da máquina do autor; o job de deploy do CI depende de duas ações pendentes do autor (chave do CI no host via `bin/host-setup`; acesso do repositório ao pacote no GHCR) |
| Dev novo clona, roda um comando, tem ambiente com seed | ✅ | `bin/setup` + `db/seeds/pessoas.rb` |
| 10 reais + 10 chiquinhos levanta exceção | ✅ | `spec/models/amount_spec.rb` |
| Evento não pode ser alterado nem apagado | ✅ | `spec/models/event_spec.rb` (ActiveRecord e trigger SQL) |
| Backup restaurado em ambiente limpo | ✅ | `docs/operacao/restore-2026-08-25.md` |
| Nenhuma requisição de terceiro sai da página | ✅ | `spec/requests/no_third_party_spec.rb` + inspeção manual do HTML em produção |
| ADRs 0001–0008 | ✅ | `docs/decisions/` |
| Nenhum float no schema | ✅ | `spec/schema/no_float_spec.rb` |
| Isolamento por empreendimento preparado | ✅ | `spec/schema/enterprise_scope_spec.rb` |

Pendências operacionais (não bloqueiam o Epic 1): DNS de
`feira.reciboemdia.com.br`, certificado TLS, destino do backup remoto
(Backblaze B2 ou outro), e a migração para VPS dedicado antes do Epic 3
(ADR 0003).

### Quais decisões deste epic contradizem ou tensionam o `CLAUDE.md`?

1. **Coordenação cria contas e redefine senhas de qualquer pessoa** (ADR 0007).
   Assimetria de poder inevitável sem canal de recuperação autônomo. Mitigação:
   evento `user.password_reset_by_coordination` registrado. Pauta do Epic 5:
   quem pode, e como se sabe que fez.
2. **O rito "conta criada em reunião" foi decidido pelo desenvolvedor**, não pela
   rede. Coerente com o §8 na intenção, mas precisa ser validado com a
   coordenação antes do Epic 1.
3. **GitHub e GHCR (Microsoft) como CI e registry** (ADR 0003). Dependência de
   plataforma corporativa num projeto que critica plataformas. Tudo é portável;
   fica como dívida política nomeada.
4. **Servidor compartilhado, fora do Brasil**, com dado de outro projeto na mesma
   máquina. Só seeds fictícios agora; migração para VPS dedicado é condição para
   o Epic 3 (ADR 0003).
5. **Seeds inventados pelo desenvolvedor.** Nomes fictícios plausíveis são ainda
   o desenvolvedor imaginando a feira. O vocabulário real deve vir das famílias
   antes do Epic 2.
6. **Teste de float estrito** proíbe `numeric` em qualquer coluna — mais do que o
   §3.1 pede. Deliberado (ADR 0004).
7. **Logs de acesso com IP** por 14 dias no host (ADR 0008). Dado pessoal, fora
   da telemetria própria; registrado com prazo.
8. **"Sem PII no payload" é allowlist, não prova formal** (ADR 0006). Um tipo de
   evento cadastrado com chave errada pode vazar; a barreira é o catálogo e a
   revisão.
9. **`allow_browser versions: :modern` do Rails foi removido.** O padrão do
   framework bloquearia navegadores antigos de Android barato (§3.6) — um caso
   em que "o jeito padrão" era o jeito errado.
