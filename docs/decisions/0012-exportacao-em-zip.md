# ADR 0012 — Exportação do empreendimento como zip portátil, com os arquivos

**Data:** 2026-08-25 · **Estado:** aceita

## Contexto

`CLAUDE.md` §3.3: todo dado pertence ao empreendimento; exportação completa desde o Epic 1,
acessível ao próprio empreendimento sem pedir a ninguém. O Epic 1.5 falava em "links das
imagens"; a revisão de agosto (2.12) apontou que link não é portabilidade — quando a
plataforma sair do ar, o link morre.

## Decisão

Um botão em "Minha loja" gera, na hora, um **zip** com:

| arquivo | conteúdo |
|---|---|
| `LEIA-ME.txt` | o que é cada arquivo, em português |
| `empreendimento.json` | dados cadastrais, situação, membros (nome e telefone) |
| `vitrine.json` | o documento EditorJS **bruto**, como está no banco |
| `eventos.json` | todos os eventos cujo alvo é o empreendimento (tipo, quando, detalhes) |
| `imagens/` | os arquivos **originais** de perfil, capa e conteúdo |

Formatos abertos (JSON, JPEG/PNG). Gera evento `enterprise.exported`. Síncrono: 12 fotos
de celular são poucos MB; se crescer, vira job com link temporário.

Os telefones dos membros entram porque são dados **do empreendimento**, exportados **por
ele**; não é um terceiro pedindo. Dados de comprador (Epic 3) entrarão com o mesmo critério
e sujeitos à retenção do ADR de expurgo.

## Alternativas consideradas

- **JSON único com links.** Recusado (2.12).
- **Export assíncrono com e-mail.** Não há e-mail neste público (ADR 0007).
- **Formato próprio ou banco de dados.** Recusado: portabilidade é poder abrir em qualquer
  computador sem esta plataforma.

## Consequências

- `rubyzip` como dependência.
- Cada epic que cria entidade principal estende `EnterpriseExport` (produtos, pedidos).
- Teste de tese: o zip contém os quatro JSON/TXT e os arquivos de imagem.
