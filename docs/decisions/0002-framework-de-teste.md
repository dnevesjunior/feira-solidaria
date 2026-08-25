# ADR 0002 — Framework de teste: RSpec

**Data:** 2026-08-25 · **Estado:** aceita

## Contexto

`CLAUDE.md` §5 deixa a escolha entre Minitest e RSpec para o Epic 0, exigindo testes de
sistema para os critérios de "pronto significa" de cada epic.

## Decisão

**RSpec** (`rspec-rails`), com **Capybara** para testes de sistema. Sem `factory_bot` por
enquanto: os modelos do Epic 0 são poucos e simples; reavaliar no Epic 2 se as fixtures
ficarem repetitivas.

Convenções:

- `spec/models`, `spec/requests`, `spec/system` como pastas principais.
- `spec/schema/` para testes que percorrem o schema inteiro e impõem restrições do
  `CLAUDE.md` (nenhum float; todo modelo com `enterprise_id` é escopado). São testes de
  tese, não de funcionalidade.
- Descrições em português quando descrevem comportamento de domínio ("soma reais com
  chiquinhos e levanta exceção"); em inglês quando descrevem mecânica técnica.

## Alternativas consideradas

- **Minitest.** Padrão do Rails, zero dependência, geradores prontos. Foi a recomendação
  técnica inicial por ser "uma coisa a menos" num projeto de uma pessoa. Recusada por
  preferência do autor, que tem mais familiaridade com RSpec — e familiaridade de quem
  mantém vale mais do que economia de uma dependência.

## Consequências

- `rails new` com `--skip-test`; `rspec-rails`, `capybara` e `selenium-webdriver` no grupo
  de teste.
- Geradores do Rails produzem specs em vez de tests (`config.generators`).
- CI roda `bundle exec rspec`.
