# ADR 0003 — Deploy com Kamal em VPS próprio; teto de custo

**Data:** 2026-08-25 · **Estado:** aceita

## Contexto

`CLAUDE.md` §5 pede deploy de custo baixo e previsível — orçamento de extensão
universitária. `CLAUDE.md` §3.3 pede soberania sobre o dado: ele pertence aos
empreendimentos, não a um provedor. O Epic 0 exige que `git push` na branch principal
resulte em site no ar, com backup testado.

Existe um VPS já pago pelo autor: DigitalOcean, região `nyc1`, 1 vCPU, 2 GB RAM, Ubuntu
24.04, Docker instalado, compartilhado com outro projeto (`staging.terapiaconecta.com.br`)
que já ocupa nginx nas portas 80/443 e ~1 GB de memória. Existe também um domínio de teste,
`reciboemdia.com.br`, apontando para esse VPS.

## Decisão

1. **Kamal 2** (já incluído no Rails 8) como ferramenta de deploy, com a aplicação e o
   PostgreSQL em contêineres no VPS. Imagem publicada no **GHCR** (GitHub Container
   Registry), gratuito para repositório público.
2. **Kamal atrás do nginx existente.** `kamal-proxy` escuta em `127.0.0.1:8080`; o nginx do
   host roteia `feira.reciboemdia.com.br` para ele e termina TLS com certbot. Não se toca no
   site do outro projeto.
3. **Um único banco PostgreSQL** para aplicação, Solid Queue e Solid Cache — um só backup.
   Jobs rodam dentro do Puma (`SOLID_QUEUE_IN_PUMA`), sem contêiner extra: memória é o
   recurso escasso.
4. **CI e deploy no GitHub Actions**: push em `main` → testes → `kamal deploy`.
5. **Backup diário** (`pg_dump` + volume de arquivos) com cópia local em `/var/backups/feira`
   e envio para object storage S3-compatível (Backblaze B2, 10 GB gratuitos, a confirmar).
   Restore testado ao menos uma vez por epic, com registro em `docs/operacao/`.
6. **Este VPS serve ao Epic 0 e às demonstrações. Não serve ao piloto real.** Antes de o
   Epic 3 entrar no ar com dados de famílias reais, a produção migra para um **VPS dedicado**,
   de preferência em região São Paulo (latência de `nyc1` para a Baixada Santista é
   ~130 ms; provedores com região SP: Vultr, Magalu Cloud, Hostinger, AWS/GCP). Motivos:
   isolamento de dado pessoal de outro projeto, memória, latência, e jurisdição.

## Custo

| Item | Hoje | Piloto |
|---|---|---|
| VPS | R$ 0 incremental (já pago) | R$ 30–60/mês (dedicado, 2 GB, SP) |
| Domínio | R$ 0 incremental (já pago) | ~R$ 40/ano (`.org.br` próprio, opcional) |
| Object storage | R$ 0 (B2, 10 GB) | R$ 0–5/mês |
| GitHub Actions / GHCR | R$ 0 (repo público) | R$ 0 |
| **Teto registrado** | | **R$ 100/mês** |

Ultrapassar o teto exige novo ADR.

## Alternativas consideradas

- **Fly.io** (região GRU). Menos operação, mas custo variável por uso e dependência de
  vendor para banco e volumes. Recusado pela previsibilidade e pela soberania do dado.
- **Render / Heroku.** Idem, com custo maior.
- **Postgres gerenciado** (Neon, Supabase, DO Managed). Reduz a carga de backup, mas coloca
  o dado dos empreendimentos sob um terceiro e adiciona custo fixo. Recusado; backup próprio
  testado é obrigação assumida em troca.
- **systemd + Puma + `git pull` no host.** Sem Docker, mais leve em memória. Recusado
  porque Kamal já vem pronto no Rails 8, isola o app do outro projeto no mesmo host, e torna
  a migração para o VPS dedicado uma mudança de uma linha em `config/deploy.yml`.

## Tensões com o `CLAUDE.md`

- **GitHub e GHCR (Microsoft) como CI e registry.** Dependência de plataforma corporativa
  num projeto que critica plataformas. Aceita porque tudo é portável — git, `Dockerfile`,
  Kamal — e a migração para Codeberg/Forgejo com registry próprio é mecânica. Fica anotada
  como dívida política, não técnica.
- **Servidor compartilhado, fora do Brasil, para o Epic 0.** Só há seeds fictícios nele;
  a migração antes do piloto é condição, não sugestão.

## Consequências

- `config/deploy.yml` com `proxy.ssl: false` e host fixo; `production.rb` com
  `assume_ssl = true`.
- Site nginx e certificado são configuração de host, documentada em `docs/operacao/`.
- Pré-requisito externo: registro DNS `A feira.reciboemdia.com.br → 67.205.134.61`.
