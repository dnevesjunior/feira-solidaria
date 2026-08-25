# Plataforma da Feira Solidária

Plataforma digital de uma rede de empreendimentos de economia solidária da
Baixada Santista (SP), com feira presencial e moeda comunitária própria, o
**Chiquinho**. Iniciativa do GT7 — Economia Solidária do Observatório do
Trabalho e da Classe Trabalhadora (IEA/USP), com PUC-SP e ITCP-USP.

Não é um marketplace. As restrições que definem o projeto estão em
[`CLAUDE.md`](CLAUDE.md) — leia antes de qualquer coisa. As funcionalidades
estão em [`docs/epics/`](docs/epics/); as decisões, em
[`docs/decisions/`](docs/decisions/).

Licença: [AGPL-3.0](LICENSE) ([ADR 0001](docs/decisions/0001-licenca.md)).

## Subir local (menos de 10 minutos)

Requisitos: Ruby 3.3.8, PostgreSQL 16 aceitando o seu usuário no socket local,
Node não é necessário.

```sh
git clone git@github.com:dnevesjunior/feira-solidaria.git
cd feira-solidaria
bin/setup        # bundle, banco, migrations, seeds
bin/dev          # http://localhost:3000
```

Seeds criam pessoas fictícias (`db/seeds/pessoas.rb`); todas com senha
`feira1234`. Para entrar: telefone `13 90000-0001`.

Testes: `bundle exec rspec`. Lint: `bin/rubocop`. Segurança: `bin/brakeman`.

## Estrutura

| Onde | O quê |
|---|---|
| `CLAUDE.md` | Restrições do projeto. Fonte da verdade. |
| `docs/epics/` | Funcionalidades, um epic por arquivo, com critérios de "pronto significa". |
| `docs/decisions/` | ADRs. Decisões de arquitetura são achados de pesquisa. |
| `docs/operacao/` | Servidor, backup, restore testado. |
| `docs/REFERENCIAS.md` | Bibliografia. |
| `app/models/amount.rb` | Valor monetário: inteiro + unidade, Real e Chiquinho não somáveis. |
| `app/models/event.rb` | Log de eventos append-only. Todo tipo em `Event::Catalog`. |
| `app/models/concerns/enterprise_scoped.rb` | Escopo por empreendimento. |
| `app/queries/` | Query objects; leituras que cruzam empreendimentos ficam nomeadas aqui. |
| `spec/schema/` | Testes de tese: nenhum float, todo modelo com `enterprise_id` é escopado. |

## Contas

Não há cadastro público. A coordenação cria contas, de preferência em reunião
presencial ([ADR 0007](docs/decisions/0007-autenticacao-por-telefone.md)):

```sh
bin/rails "contas:criar[13999990001,Maria das Graças Oliveira]"
bin/rails "contas:redefinir_senha[13999990001]"     # registra evento
```

Em produção: `bin/kamal app exec --reuse 'bin/rails "contas:criar[...]"'`.

## Deploy

`git push` em `main` → CI (rubocop, brakeman, rspec) → `kamal deploy`
([ADR 0003](docs/decisions/0003-deploy-e-custo.md)). Operação do servidor,
backup e restore em [`docs/operacao/`](docs/operacao/).
