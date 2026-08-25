# ADR 0009 — Vitrine como JSON estruturado, renderizado no servidor por allowlist

**Data:** 2026-08-25 · **Estado:** aceita (EditorJS provisório até o teste em celular real)

## Contexto

`CLAUDE.md` §5 fixa EditorJS para o conteúdo editável da vitrine, persistido como JSON
estruturado e renderizado no servidor com allowlist de blocos — nunca HTML bruto. O Epic 1.3
pede blocos parágrafo, título, lista, imagem e citação, e que conteúdo com script seja
rejeitado. A revisão de agosto (2.10) alertou que o EditorJS foi desenhado para desktop, e
o público usa Android de baixo custo (§3.6).

## Decisão

- **Formato de persistência: o JSON do EditorJS** (`enterprises.content`, jsonb), com o
  objeto de valor `EditorJs::Document` como única porta de entrada. Ele valida tipo de bloco
  contra `BLOCKS = paragraph header list quote image`, níveis de título (2–3), formato de
  lista, tamanho, e que toda imagem referencia um `ContentImage` **do próprio
  empreendimento** por `signed_id`. Texto com `<script`, `on*=`, `javascript:`, iframe etc.
  torna o documento **inválido** — rejeitado com mensagem, não limpo em silêncio.
- **Renderização no servidor** (`EditorJs::Renderer`): HTML gerado a partir do documento
  validado; texto inline passa pelo sanitizador com `b i strong em a br` e `href` só
  `http(s)`. Imagens saem com `width`/`height` e `loading="lazy"`.
- **Editor: EditorJS vendorizado** (`vendor/javascript`, via importmap, sem CDN — §3.3),
  ~400 KB carregados **só** na página de edição. A vitrine pública não carrega editor.
- **A allowlist do cliente espelha a do servidor, e o servidor manda.** O JavaScript é
  conveniência; a segurança está no `Document`.
- **Plano B declarado:** se o teste em celular real (primeira semana) mostrar que o EditorJS
  não serve a este público, entra um formulário simples (texto + fotos) que grava **o mesmo
  JSON** (`paragraph` + `image`). Nada muda no banco, no renderer ou no export.

## Alternativas consideradas

- **HTML sanitizado (Action Text / Trix).** Mais simples, mas o formato é HTML: reprocessar
  depois (impressão, tradução, export estruturado) exige parsear HTML. Recusado pelo §5.
- **Markdown.** Leve e portátil, mas pede que a pessoa aprenda sintaxe; contraria §3.6.
- **Limpar em vez de rejeitar** conteúdo perigoso. Recusado: limpar em silêncio esconde
  da pessoa que algo foi descartado, e um sanitizador é uma lista de "o que tirar" — uma
  allowlist é "o que entra".

## Consequências

- Todo bloco novo passa por `Document` (validação), `Renderer` (HTML) e pelo editor
  (tool) — três lugares, de propósito, para que o servidor nunca dependa do cliente.
- Imagens de conteúdo são entidades escopadas (`ContentImage`), não URLs soltas: é o que
  impede vazamento entre lojas (§3.5) e permite o export com arquivos (ADR 0012).
- Decisão sobre EditorJS vs. plano B deve ser anotada aqui após o teste real.
