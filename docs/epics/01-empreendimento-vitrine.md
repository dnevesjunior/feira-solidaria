# Epic 1 — Empreendimento e vitrine

> Pré-requisitos: `CLAUDE.md`, Epic 0 concluído.

## Objetivo

Cada empreendimento tem uma página pública sua, que ela mesma edita, acessível
por um endereço que dá para dizer em voz alta.

## Por que este epic vem primeiro

É a primeira coisa que as famílias **veem**. Ver a própria loja no ar é o que
sustenta o engajamento nos meses seguintes, antes de qualquer venda acontecer.
Um projeto que passa três meses em infraestrutura antes de mostrar algo perde a
comunidade no caminho.

## Fora de escopo

Produtos (Epic 2), pedidos (Epic 3), moeda (Epic 6). A vitrine deste epic
apresenta o empreendimento e sua história — não um catálogo.

---

## Escopo

### 1.1 Modelo `Enterprise` (Empreendimento)

- Nome, slug, descrição curta, imagem de capa, imagem de perfil.
- Contato: WhatsApp (obrigatório), Instagram (opcional).
- Endereço/território de atuação — **opcional e granularidade grossa**
  (bairro, não rua). Boa parte do público mora em área de vulnerabilidade;
  publicar endereço exato de residência é risco de segurança, não feature.
- Estado: rascunho / publicado. Loja nova nasce em rascunho.
- Membros: um empreendimento pode ter mais de uma pessoa. Modelar
  `Enterprise` ↔ `User` como muitos-para-muitos desde já. É unidade **familiar
  ou coletiva**, não pessoa física (`CLAUDE.md` §4).

### 1.2 Hub

- Página inicial da feira: quem é a rede, e a lista de empreendimentos
  publicados.
- **Ordenação rotativa com semente diária.** Não alfabética (privilegia "A"),
  não por data de cadastro (privilegia quem chegou antes), não por desempenho
  (não existe desempenho ainda, e não vai existir — `CLAUDE.md` §3.2).
- A ordenação já deve ser lida de um **objeto de configuração**, não de uma
  constante, para que o Epic 5 apenas passe a permitir alterá-la. Valor padrão
  declarado; mudança ainda não disponível.
- Busca simples por nome. Sem "relevância", sem personalização.

### 1.3 Vitrine (`store#show`)

- Rota curta e falável: `/nome-da-loja`. Slug gerado do nome, editável,
  imutável depois de publicado (ou com redirecionamento, se mudar).
- Conteúdo editável pelo próprio empreendimento via **EditorJS**.
- Blocos permitidos: parágrafo, título, lista, imagem, citação. **Allowlist
  explícita.** Sem HTML bruto, sem embed arbitrário, sem script.
- Persistir o **JSON estruturado do EditorJS**, nunca HTML renderizado.
  Renderização server-side a partir do JSON, com sanitização.
- Motivo: HTML bruto salvo por usuário é vetor de XSS e impossibilita
  reprocessar o conteúdo depois (tradução, versão para impressão, exportação).

### 1.4 Edição

- Área de edição em português simples: "Minha loja", "Editar minha página".
- Preview antes de publicar.
- Upload de imagem com **redimensionamento e compressão no servidor**. As fotos
  vêm de celular, com 4–8 MB cada. Sem isso, a vitrine fica inutilizável em
  conexão ruim (`CLAUDE.md` §3.6).
- Limite de tamanho e quantidade, com mensagem de erro que explica o que fazer.

### 1.5 Exportação

- Botão que exporta todo o conteúdo do empreendimento (dados + JSON da vitrine +
  links das imagens) em arquivo legível.
- Acessível ao próprio empreendimento, sem pedir a ninguém.
- **Existe desde este epic.** Não é feature de LGPD adicionada depois; é
  premissa (`CLAUDE.md` §3.3; cf. Scholz, 2016 — portabilidade de dados).

### 1.6 Eventos registrados

`enterprise.created`, `enterprise.published`, `enterprise.updated`,
`enterprise.member_added`, `enterprise.member_removed`, `enterprise.exported`.

---

## Notas de desenho

**Sobre a página de erro 404 de loja inexistente:** alguém vai digitar errado o
endereço que ouviu numa conversa. Levar de volta ao hub com a busca aberta.

**Sobre o slug:** ele vai ser lido em voz alta, escrito em papel e digitado por
alguém no ponto de ônibus. Curto, sem acento, sem hífen duplo, sem número.

**Sobre "rascunho":** publicar deve ser um ato deliberado do empreendimento.
Ninguém deve descobrir que sua página está no ar sem ter decidido isso.

---

## Pronto significa

- [ ] Uma pessoa da feira, com um celular Android modesto e sem ajuda
      presencial, cria a página do seu empreendimento, sobe uma foto de capa,
      escreve três parágrafos e publica.
- [ ] O endereço da loja cabe numa frase dita em voz alta e funciona quando
      digitado por outra pessoa.
- [ ] A vitrine carrega em menos de 3 segundos em 3G simulado.
- [ ] Uma foto de 6 MB tirada de celular é aceita e servida comprimida.
- [ ] O empreendimento exporta seus dados sozinho, sem pedir a ninguém.
- [ ] Conteúdo com tentativa de script é rejeitado — teste prova.
- [ ] Duas visitas ao hub em dias diferentes mostram ordens diferentes.
- [ ] Nenhum dado de uma loja aparece em consulta escopada a outra — teste prova.

---

## Ao final do epic

Responder: **quais decisões deste epic contradizem ou tensionam o `CLAUDE.md`?**

---

## Encerramento — 2026-08-25

### Checklist

| Critério | Estado | Prova |
|---|---|---|
| Pessoa com Android modesto cria página, sobe capa, escreve três parágrafos e publica | ⚠️ automatizado; **falta o teste real** | `spec/system/vitrine_spec.rb` (Chrome, 412×915, capa de 6 MB, EditorJS) — passo 11 do plano pendente |
| Endereço cabe numa frase e funciona digitado | ✅ | `spec/models/enterprise/slug_spec.rb`; `GET /doces-da-cida` |
| Vitrine < 3 s em 3G simulado | ✅ (proxy) | HTML+CSS+JS < 100 KB gzip sem imagens, sem editor (`spec/requests/enterprise_show_spec.rb`); imagens lazy com dimensões |
| Foto de 6 MB aceita e servida comprimida | ✅ | `spec/models/content_image_spec.rb`: > 6 MB → < 20% do peso, ≤ 1600 px |
| Empreendimento exporta sozinho | ✅ | zip com `empreendimento.json`, `vitrine.json`, `eventos.json`, `imagens/` |
| Script rejeitado — teste prova | ✅ | `spec/models/editor_js/document_spec.rb`; PATCH com script → 422 e nada gravado |
| Hub em dias diferentes mostra ordens diferentes | ✅ | `spec/queries/published_enterprises_query_spec.rb` |
| Nenhum dado de uma loja em consulta escopada a outra | ✅ | `spec/requests/my_enterprise_spec.rb` (sessão forçada, imagem de outra loja, `for_current`) |

Adições sobre o especificado: "próxima feira" no hub (`FairEvent`), visitas da
própria vitrine (ADR 0008), `Governance::Parameter` (ADR 0011).

### Quais decisões deste epic contradizem ou tensionam o `CLAUDE.md`?

1. **Sem papel de coordenação:** qualquer membro edita "próxima feira" e adiciona
   pessoas ao empreendimento de que participa. Aceito para não criar hierarquia antes do
   Epic 5; tudo gera evento. Risco de edição errada assumido.
2. **Slug sem dígitos** ("Doces da 13" → `doces-da`). Segue a nota do epic; a pessoa
   edita o endereço enquanto está em rascunho.
3. **Slug imutável após publicar, sem redirecionamento.** Mudar de nome quebra o link
   falado. Redirecionamento é pequeno; entra se surgir demanda.
4. **Proxy de imagens pelo Puma** em 1 vCPU — escolha pró-3G que custa CPU (ADR 0010).
5. **HEIC recusado** (iPhone). Público-alvo é Android; reavaliar se aparecer demanda.
6. **Texto do hub por commit** até o Epic 5 — o desenvolvedor é o gargalo de uma
   decisão da rede. Placeholder marcado; aguarda texto da coordenação.
7. **`Governance::Parameter` sem autor/justificativa** — sem violação porque não há
   mudança possível; o Epic 5 troca o formato antes da primeira alteração (ADR 0011).
8. **EditorJS ainda não validado com o público** (revisão 2.10). A automação prova que
   funciona num Chrome de celular; não prova que uma pessoa de 65 anos consegue usar.
   Plano B declarado no ADR 0009. **O epic não está fechado até o teste real.**
9. **Visitas da própria vitrine** são um número que a pessoa vê — é a primeira métrica da
   plataforma. Só a própria, nunca comparativa (ADR 0008); ainda assim, é um número, e
   números viram metas. Observar como as famílias o recebem.
