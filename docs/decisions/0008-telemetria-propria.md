# ADR 0008 — Telemetria própria: o que se conta, quem vê, por quanto tempo

**Data:** 2026-08-25 · **Estado:** aceita

## Contexto

`CLAUDE.md` §3.3: nenhum SDK de analytics de terceiros; telemetria própria e auditável.
Epic 0.7: contagem de pageview e erro em tabela própria, sem PII, sem cookie de rastreio.
A revisão de agosto (item 2.9) apontou que "pageview por loja" muda de natureza conforme
quem vê: é funcionalidade se o empreendimento vê a sua; é ranking por outro nome se vê a
das outras; serve só à pesquisa se ninguém vê (`CLAUDE.md` §2).

## Decisão

### Pageviews

- Tabela `page_views(path, day, count)`, única em `(path, day)`. Incremento por `upsert`
  em `after_action`, apenas para GET + HTML + 2xx.
- **Não se guarda:** IP, user-agent, referer, query string, identificador de sessão, nada
  por requisição. O user-agent é lido apenas para descartar bots óbvios e não é
  armazenado. Sem cookie.
- **Quem vê:** o empreendimento vê a contagem da **própria** vitrine, nunca a das outras;
  uma contagem global da feira é visível a todos os membros. Sem comparação, sem ranking,
  sem "sua loja está abaixo da média". Sem interface no Epic 0.
- **Retenção:** indefinida — é agregado diário sem dado pessoal e faz parte do histórico do
  empreendimento (exportável).

### Erros

- Tabela `error_reports(exception_class, message, backtrace, controller, action,
  occurred_at)`, alimentada por `Rails.error.subscribe`.
- `message` e `backtrace` passam por `ActiveSupport::ParameterFilter` e por remoção de
  padrões de telefone e e-mail antes de gravar.
- **Retenção:** 90 dias, expurgo por tarefa recorrente do Solid Queue.
- Sem serviço externo de monitoramento de exceções. Se um dia for necessário, deve ser
  auto-hospedado (ex.: GlitchTip) e com o mesmo scrub.

### Logs de acesso

O nginx do host e o Puma registram requisições com IP. Não são telemetria e não saem da
máquina, mas são dado pessoal: rotação em **14 dias**, sem envio a terceiros. Registrado
aqui porque o §3.3 não os cobre e alguém vai perguntar.

## Alternativas consideradas

- **Google Analytics, Plausible (nuvem), Matomo (nuvem).** Recusados pelo §3.3. Plausible e
  Matomo auto-hospedados seriam aceitáveis, mas são um serviço a mais para manter em 2 GB de
  RAM, para responder uma pergunta que uma tabela de contagem responde.
- **Sentry / Honeybadger.** Recusados: dado de erro (com parâmetros, cabeçalhos, IP) sairia
  para terceiro.
- **Registro por requisição com IP anonimizado.** Permitiria "visitantes únicos", que é a
  métrica que todo mundo quer. Recusado: anonimização de IP é frágil, e "únicos por loja"
  é o primeiro passo para comparar lojas.

## Consequências

- Nenhuma tag de terceiro no layout. Teste de request afirma que o HTML da página de login
  não referencia host externo.
- O Epic 1 decide onde mostrar a contagem da própria vitrine; o Epic 7 pode ler
  `page_views` sem pedir nada novo.
