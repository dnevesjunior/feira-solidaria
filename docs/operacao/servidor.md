# Servidor — Epic 0

> Estado em 2026-08-25. Ver [ADR 0003](../decisions/0003-deploy-e-custo.md).

| | |
|---|---|
| Host | `67.205.134.61` (DigitalOcean nyc1, 1 vCPU, 2 GB, Ubuntu 24.04) |
| Acesso | SSH `root`, chave do autor e chave do CI (`feira-ci`) |
| Compartilhado com | `staging.terapiaconecta.com.br` (nginx + Rails + MySQL) |
| Domínio | `feira.reciboemdia.com.br` → nginx do host → `127.0.0.1:8080` (kamal-proxy) |
| Contêineres | `feira-web-*` (app), `feira-db` (PostgreSQL 16), `kamal-proxy` |
| Dados | `/var/lib/feira/postgres`, `/var/lib/feira/storage` (dono uid 1000 = usuário `rails` do contêiner; sem isso, upload de foto dá 500) |
| Backups | `/var/backups/feira` (30 dias), script `/opt/feira/bin/backup`, cron 03:00 |

**Este servidor não serve ao piloto com famílias reais.** Antes do Epic 3
entrar no ar, a produção migra para VPS dedicado (ADR 0003, item 6).

## Primeira instalação (feita uma vez)

```sh
# na máquina do autor, com KAMAL_REGISTRY_PASSWORD (token GHCR) e POSTGRES_PASSWORD no ambiente
bin/kamal proxy boot_config set --http-port 8080 --https-port 8443 --publish-host-ip 127.0.0.1
bin/kamal setup            # sobe proxy, banco e app
```

No host:

```sh
cp docs/operacao/nginx-feira.conf /etc/nginx/sites-available/feira.reciboemdia.com.br
ln -s /etc/nginx/sites-available/feira.reciboemdia.com.br /etc/nginx/sites-enabled/
nginx -t && systemctl reload nginx
certbot --nginx -d feira.reciboemdia.com.br      # depois do DNS apontar
mkdir -p /opt/feira/bin && cp bin/backup /opt/feira/bin/ && chmod +x /opt/feira/bin/backup
echo '0 3 * * * root /opt/feira/bin/backup >> /var/log/feira-backup.log 2>&1' > /etc/cron.d/feira-backup
```

## Rotina

- Deploy: `git push origin main`. Acompanhar em Actions.
- Console: `bin/kamal console`. Logs: `bin/kamal logs`.
- Backup manual: `ssh root@67.205.134.61 /opt/feira/bin/backup`.
- Restore de teste: copiar o dump para a máquina local e rodar
  `bin/restore-check caminho/do/dump`. Registrar em `docs/operacao/restore-AAAA-MM-DD.md`.
- Logs de acesso do nginx: rotação padrão do Ubuntu (14 dias), conforme ADR 0008.
