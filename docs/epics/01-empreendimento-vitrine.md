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
