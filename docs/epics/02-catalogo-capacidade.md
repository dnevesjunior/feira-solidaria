# Epic 2 — Catálogo com capacidade declarada

> Pré-requisitos: `CLAUDE.md`, Epics 0 e 1 concluídos.

## Objetivo

Cada empreendimento cadastra o que produz, a que preço, e **quanto consegue
produzir por período**.

## Por que a capacidade importa

É o campo que quase nenhum marketplace tem, e é pré-requisito do Epic 4 (pedido
coletivo). Marketplace convencional modela **estoque** — uma quantidade
existente, pronta, que decrementa a cada venda. Produção artesanal familiar não
funciona assim: o item é feito sob demanda, e o limite real não é o que existe
na prateleira, é quanto a pessoa consegue fazer numa semana sem adoecer.

Modelar estoque aqui seria importar um pressuposto de produção industrial para
um contexto que não é industrial — exatamente o erro que o projeto existe para
não cometer (`CLAUDE.md` §1.1).

Custa quase nada agora. Adicionar depois significa pedir a 30 famílias que
revisitem todo o catálogo.

## Fora de escopo

Pedido (Epic 3), rateio entre empreendimentos (Epic 4), preço em Chiquinho
(Epic 6). Preço aqui é **em reais**, usando a primitiva monetária do Epic 0.

---

## Escopo

### 2.1 Modelo `Product`

- Pertence a um empreendimento (escopado — `CLAUDE.md` §3.5).
- Nome, descrição, fotos (mesma pipeline de compressão do Epic 1).
- Preço unitário em reais (inteiro, unidade explícita).
- Unidade de venda em texto livre controlado: unidade, par, dúzia, kg, 100g,
  pote, litro. Não inventar taxonomia sofisticada — a feira tem vocabulário
  próprio e ele deve caber.
- Estado: rascunho / publicado / pausado.
  **"Pausado" é importante e distinto de "sem estoque":** significa "não estou
  produzindo isso agora", que é a situação real de quem parou por doença,
  viagem, falta de insumo ou porque a demanda mudou de estação.

### 2.2 Capacidade declarada

- Campo por produto: **quantidade que o empreendimento consegue produzir por
  período**, com período configurável (semana como padrão).
- Prazo típico de entrega em dias.
- É **declaração**, não contrato. Interface deve deixar isso claro: "quanto você
  consegue fazer numa semana, mais ou menos". Sem penalidade, sem alerta de
  descumprimento, sem métrica de "confiabilidade" — isso seria rating por outro
  nome (`CLAUDE.md` §3.2).
- Editável a qualquer momento pelo próprio empreendimento, com a alteração
  registrada em evento: a pessoa vê o que declarou ao longo do tempo e recebe
  isso no export. (Que o histórico também sirva à pesquisa é consequência, não
  motivo — `CLAUDE.md` §2; revisão 2.8.)

### 2.3 Categorias

- Lista **curta e fechada**, definida com a feira, não inventada pelo
  desenvolvedor. Se ninguém perguntou às famílias quais são as categorias, ainda
  não dá para implementar isso — deixar um único agrupamento e voltar depois.
- Categoria é atributo de organização, nunca de priorização de exibição.

### 2.4 Catálogo agregado da feira

- Página que lista produtos de toda a rede.
- Mesma regra de ordenação rotativa do hub, lida do objeto de configuração
  (`CLAUDE.md` §3.4).
- Filtro por categoria. Busca por nome.
- **Sem** "mais vendidos", "em alta", "recomendados para você", "quem viu também
  viu". Nenhuma ordenação derivada de comportamento agregado ou de perfil
  individual.
- Cada item leva à vitrine do empreendimento — a loja é a unidade de
  apresentação, não o produto solto. A pessoa deve saber de quem está comprando.

### 2.5 Visão agregada de capacidade (interna)

- Para a coordenação da feira: dado um produto ou categoria, qual é a capacidade
  somada da rede.
- Só leitura, sem ação associada ainda.
- É o embrião do Epic 4 e o primeiro momento em que a rede consegue **se ver
  como capacidade produtiva coletiva** — algo que a feira presencial
  estruturalmente não consegue fazer.

### 2.6 Exportação

- Estender o export do Epic 1 para incluir produtos e histórico de capacidade.

### 2.7 Eventos registrados

`product.created`, `product.published`, `product.paused`, `product.updated`,
`product.capacity_changed` (com valor anterior e novo).

---

## Notas de desenho

**Sobre cadastrar produto pelo celular:** é a tarefa mais repetitiva que uma
família vai fazer na plataforma. Formulário longo com muitos campos obrigatórios
é o ponto mais provável de abandono do projeto inteiro. Mínimo obrigatório:
nome, foto, preço. Todo o resto é preenchível depois.

**Sobre preço:** não sugerir preço, não comparar com o de outros
empreendimentos, não sinalizar "acima da média". Precificação é decisão do
empreendimento, e insinuar comparação introduz concorrência interna numa rede
que se define pela cooperação.

**Sobre foto:** oferecer orientação simples e opcional de como fotografar
(luz natural, fundo liso). Isso é formação, e é o tipo de coisa que a parceria
com o grupo de comunicação comunitária pode produzir bem melhor do que um
desenvolvedor sozinho.

---

## Pronto significa

- [ ] Uma pessoa cadastra três produtos pelo celular em menos de 10 minutos,
      sem ajuda.
- [ ] Um produto pode ser pausado e volta a aparecer quando despausado.
- [ ] A coordenação consulta a capacidade semanal somada da rede para uma
      categoria e obtém um número.
- [ ] Alterar a capacidade declarada gera evento com valor anterior e novo —
      teste prova.
- [ ] O catálogo agregado não expõe nenhuma ordenação derivada de vendas,
      cliques ou perfil — revisão de código confirma.
- [ ] O export do empreendimento inclui produtos e histórico de capacidade.

---

## Ao final do epic

Responder: **quais decisões deste epic contradizem ou tensionam o `CLAUDE.md`?**

---

## Encerramento — 2026-08-26

### Checklist

| Critério | Estado | Prova |
|---|---|---|
| Três produtos pelo celular em < 10 min, sem ajuda | ✅ como PoC | `spec/system/produtos_spec.rb` (três produtos com foto, um publicado); formulário com **2** campos obrigatórios (nome, preço) e foto só ao publicar. Teste com pessoas da feira: condição do piloto (nota de sequência no Epic 1) |
| Pausar e voltar ao despausar | ✅ | `spec/requests/products_spec.rb` (vitrine e catálogo) |
| Coordenação consulta capacidade somada e obtém um número | ✅ (todos os membros) | `/capacidade-da-rede`: soma semanal normalizada — `spec/queries/products_queries_spec.rb` |
| Alterar capacidade gera evento com valor anterior e novo | ✅ | `spec/models/product_spec.rb` |
| Catálogo sem ordenação derivada de vendas/cliques/perfil | ✅ | spec de tese sobre o SQL do `PublishedProductsQuery` |
| Export inclui produtos e histórico de capacidade | ✅ | `produtos.json` + `imagens/produto-*` |

### Quais decisões deste epic contradizem ou tensionam o `CLAUDE.md`?

1. **Normalização mensal por 12 ÷ 52 com divisão inteira** é aproximação apresentada como
   número. A página diz "aproximado"; o Epic 4 deve tratar como estimativa (ADR 0013).
2. **Foto obrigatória para publicar** pode travar quem não tem foto boa. Rascunho salva
   sem foto; a orientação no formulário é provisória até o material do grupo de
   comunicação comunitária.
3. **Capacidade da rede visível a todos os membros** expõe cada declaração (somada por
   produto). Coerente com cooperação; pode constranger ("declarei pouco"). Observar.
4. **Produto sem página própria** dificulta compartilhar um item no WhatsApp; o link é da
   loja com âncora (ADR 0014).
5. **Unidade de venda livre** gera variação de grafia. Aceito: o vocabulário da feira vale
   mais que uma taxonomia limpa; a agregação é por nome de produto.
6. **Categorias adiadas** = catálogo sem filtro até a feira definir a lista.
7. **Preço digitado em pt-BR sem máscara**; "12.50" é recusado com mensagem. Avaliar no
   teste real se precisa de máscara.
8. **A vitrine agora mostra preço** — é o primeiro dado "de mercado" público. Sem
   comparação, sem média, sem ordenação por preço, de propósito.
