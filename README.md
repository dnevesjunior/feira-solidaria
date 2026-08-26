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

Seeds criam pessoas, empreendimentos e uma próxima feira, todos fictícios
(`db/seeds/`); todas as contas com senha `feira1234`. Para entrar: telefone
`13 90000-0001` (Maria, do "Bordados do Dique").

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
| `app/models/editor_js/` | `Document` (validação por allowlist) e `Renderer` (JSON → HTML). |
| `app/models/enterprise_export.rb` | Export completo em zip: dados, vitrine, eventos, imagens. |
| `app/models/governance/` | Parâmetros de governança em banco com default declarado. |
| `app/models/product.rb`, `product/capacity.rb` | Produto com preço em `Amount` e capacidade declarada (normalizada para semana). |
| `vendor/javascript/` | EditorJS vendorizado (sem CDN). |
| `spec/schema/` | Testes de tese: nenhum float, todo modelo com `enterprise_id` é escopado. |

## Minha loja

Quem tem conta cria o próprio empreendimento em `/minha-loja/nova`, escreve a
página em `/minha-loja/editar` (EditorJS: parágrafo, título, lista, citação,
foto) e publica quando quiser. A vitrine pública fica em `/<endereco>`. Tudo o
que a plataforma guarda sobre o empreendimento sai em `/minha-loja/exportar`.

Produtos ficam em `/minha-loja/produtos` (nome e preço bastam; foto para
publicar; capacidade declarada opcional). Catálogo público em `/produtos`;
capacidade somada da rede em `/capacidade-da-rede` (membros).

Fotos precisam de `libvips` no sistema (`sudo apt install libvips42`).

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
