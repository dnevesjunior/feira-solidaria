# CLAUDE.md — Plataforma da Feira Solidária

> Documento de contexto persistente. Leia antes de qualquer plano ou implementação.
> Este arquivo descreve **restrições**, não funcionalidades. As funcionalidades estão em `docs/epics/`.

---

## 1. O que é este projeto

Plataforma digital para uma rede de empreendimentos de economia solidária ligada a um
grupo da Baixada Santista (SP), atualmente com ~17 famílias em expansão para ~30, que
opera uma feira artesanal presencial e uma moeda comunitária própria (**Chiquinho**).

O projeto nasce como iniciativa do **GT7 — Economia Solidária** do Observatório do
Trabalho e da Classe Trabalhadora (IEA/USP), em articulação com PUC-SP e ITCP-USP.

**É um projeto acadêmico E um projeto de uso real.** As duas coisas ao mesmo tempo,
com hierarquia explícita (ver §2).

### 1.1 Não é um marketplace convencional

Este é o ponto mais importante deste documento.

Existe um repertório canônico de marketplace — rating de vendedor, ranking por
relevância, produto patrocinado, funil de conversão, checkout integrado, growth
loops. Esse repertório **não é neutro**: ele foi engendrado num contexto de
propriedade privada dos meios de produção, heterogestão e concorrência entre
vendedores, e carrega essa política embutida nos seus artefatos técnicos
(cf. Winner, 1980; Dagnino, 2008).

Reproduzir esse repertório aqui destruiria a tese do projeto — que é justamente
construir uma tecnologia *adequada* à autogestão em vez de adaptar uma tecnologia
concebida para o oposto.

**Se uma sugestão de implementação parecer "o jeito padrão de fazer marketplace",
trate isso como sinal de alerta, não de validação.** Explicite a tensão antes de
implementar.

---

## 2. Hierarquia de clientes (regra de desempate)

1. **Cliente primário: as famílias da feira.**
2. **Cliente secundário: a agenda de pesquisa.**

Quando os dois conflitarem, o primário vence. Sempre.

Consequência operacional, sem exceção na v1:

> **Nenhuma funcionalidade entra se ela serve apenas à pesquisa.**
> A pesquisa observa o que a plataforma já produz por operar. Instrumentos de
> coleta ativa (questionários, escalas, entrevistas) são propostas separadas,
> com consentimento coletivo, e a plataforma funciona sem eles.

**Critério de sucesso da v1:** as famílias venderam mais do que venderiam sem a
plataforma. Nenhum dado interessante compensa um "não" aqui.

---

## 3. Restrições inegociáveis

Cada linha abaixo evita uma refatoração cara ou uma falha de tese. Para violar
qualquer uma delas é preciso um ADR em `docs/decisions/` com justificativa.

### 3.1 Dinheiro e pagamento

- **A plataforma não intermedia pagamento em reais.** Nenhum gateway, nenhum
  split, nenhuma custódia. Pedido é roteado; a liquidação acontece fora
  (Pix direto, dinheiro, entrega). Motivo: intermediar pagamento aciona regime
  de instituição de pagamento (BCB) e inviabiliza um piloto.
- **Valores monetários são inteiros na menor unidade.** Nunca `float`.
- **Real e Chiquinho são unidades distintas e não somáveis.** O tipo deve tornar
  a soma acidental impossível, não improvável.
- **Saldo nunca é coluna mutável.** Saldo é sempre derivado de lançamentos
  imutáveis (ver §3.3). Isso vale desde o Epic 0, mesmo antes da moeda existir.

### 3.2 Ordenação, reputação e visibilidade

- **Não existe rating de vendedor.** Nem nota, nem estrelas, nem review público
  de pessoa. Motivo: sistema de reputação individual introduz competição entre
  membros de uma rede que se define pela cooperação, e é reconhecidamente um
  vetor de comportamento arbitrário e punitivo (cf. Scholz, 2016).
- **Não existe ranking por "relevância" ou por desempenho de vendas.** A regra
  de ordenação da vitrine é um **parâmetro de governança** (Epic 5). O padrão
  inicial é **rotativo com semente diária**, para que a posição não seja um
  ativo acumulável.
- **Não existe destaque pago, impulsionamento ou anúncio.**

### 3.3 Dados, registro e soberania

- **Todo dado pertence ao empreendimento que o gerou.** Não à plataforma, não à
  universidade, não ao pesquisador.
- **Exportação completa desde o Epic 1.** Toda entidade principal precisa de
  export legível (CSV/JSON) acessível ao próprio empreendimento. Portabilidade
  não é feature de LGPD; é premissa política (cf. Scholz, 2016, princípio de
  portabilidade de dados).
- **Log de eventos é cidadão de primeira classe, não auditoria bolt-on.** Toda
  transição de estado relevante gera registro *append-only* com ator, timestamp
  e payload: pedido criado/aceito/concluído, membro entrou/saiu, parâmetro
  alterado, lançamento de moeda, rateio executado. Isso é impossível de
  reconstruir retroativamente — dado não registrado nos primeiros meses
  simplesmente não existe.
- **Nenhum SDK de analytics de terceiros.** Sem Google Analytics, sem pixel de
  rede social, sem Hotjar, sem Sentry com PII. Telemetria é própria e auditável.
- **Nenhuma decisão automatizada sobre pessoas.** Sem score, sem classificação
  de risco, sem recomendação personalizada por perfil.

### 3.4 Governança

- **Toda mudança de parâmetro de governança gera registro imutável** com autor,
  data, valor anterior, valor novo e justificativa textual.
- **Parâmetros de governança não são constantes no código.** Taxa de manutenção,
  regra de ordenação, regra de rateio, regra de emissão de moeda: todos vivem em
  banco, versionados, com valor-padrão declarado — nunca `hardcoded` numa
  constante de classe.
- Motivo: o projeto existe para tornar essas decisões *deliberáveis e
  observáveis*. Hard-codar qualquer uma delas destrói simultaneamente o valor de
  uso e o valor de pesquisa.

### 3.5 Escopo por empreendimento

- Toda consulta a dado de loja é escopada por empreendimento no nível mais baixo
  possível (default scope / query object), não por filtro na controller.
- Vazamento de dado entre lojas neste projeto não é bug: é falha de tese.

### 3.6 Acessibilidade e contexto de uso real

- **Mobile-first, e mobile ruim.** Assuma Android de baixo custo, conexão
  instável, plano de dados limitado. Peso de página é requisito, não polimento.
- **Sem dependência de app.** Web.
- **Português claro, sem jargão de e-commerce.** "Pedido", não "checkout".
  "Sua loja", não "seu dashboard de seller".
- Contraste e tamanho de toque adequados; parte do público tem baixa
  familiaridade digital e faixa etária alta.

---

## 4. Glossário do domínio

Use estes termos no código. Não traduza para o vocabulário de e-commerce.

| Termo | Significado | Evite |
|---|---|---|
| **Empreendimento** | Unidade produtiva familiar ou coletiva membro da rede | `Seller`, `Vendor`, `Merchant` |
| **Feira** | A rede como um todo; o hub | `Marketplace`, `Platform` |
| **Vitrine** | Página pública de um empreendimento | `Storefront page` |
| **Capacidade** | Quanto um empreendimento produz por período | `Stock`, `Inventory` |
| **Pedido** | Intenção de compra roteada para o empreendimento | `Order` está ok; `Checkout` não |
| **Pedido coletivo** | Pedido grande rateado entre vários empreendimentos | — |
| **Rateio** | Regra de distribuição de um pedido coletivo | `Allocation algorithm` |
| **Assembleia** | Instância de decisão coletiva sobre parâmetros | `Admin settings` |
| **Chiquinho** | Moeda comunitária da rede | `Token`, `Points`, `Credits` |
| **Lançamento** | Registro imutável de movimentação de moeda | `Transaction` (ok em inglês interno) |

Nomes de classe em inglês são aceitáveis (`Enterprise`, `CollectiveOrder`,
`Apportionment`, `Assembly`, `Entry`), mas a **interface é sempre em português**
com estes termos.

---

## 5. Stack e convenções

- **Ruby on Rails** (última versão estável), PostgreSQL.
- Hotwire (Turbo + Stimulus). Evite SPA — peso e complexidade sem ganho aqui.
- **EditorJS** para conteúdo editável da vitrine (já validado pelo autor em
  projeto anterior). Persistir como JSON estruturado, **nunca HTML bruto**;
  renderizar server-side com allowlist de blocos.
- Testes: **RSpec** (ADR 0002). Testes de sistema para os critérios de "pronto
  significa" de cada epic.
- Deploy: **Kamal em VPS próprio** (ADR 0003). Custo baixo e previsível — é
  orçamento de extensão universitária, não de startup.
- Timezone `America/Sao_Paulo`. Locale `pt-BR`. Moeda formatada em pt-BR.

### 5.1 Licença

Definir **antes do primeiro commit** (ADR obrigatório). O default proposto é
**AGPL-3.0** ou licença no espírito *coopyleft* (cf. CoopCycle), pela razão de
que uma licença permissiva permitiria que o código fosse apropriado para montar
exatamente a versão extrativista que o projeto critica (cf. Bauwens & Kostakis,
2014, sobre a insuficiência do cooperativismo de plataforma sob copyright
fechado).

Verificar compatibilidade com a política de propriedade intelectual da USP antes
de fechar.

---

## 6. Registro de decisões (ADRs)

`docs/decisions/NNNN-titulo.md`, formato curto: contexto, decisão, alternativas
consideradas, consequências.

**As decisões de arquitetura deste projeto são achados de pesquisa.** "Por que
ledger de partidas dobradas em vez de campo saldo" é decisão técnica; "por que a
taxa de manutenção é parâmetro de assembleia e não constante" é dado do artigo.
Não deixe isso morrer em mensagem de commit.

---

## 7. Como conduzir um epic

1. Leia este arquivo e `docs/epics/NN-*.md`.
2. Em plan mode, produza o plano **de um epic por vez**.
3. Escreva os testes de sistema dos critérios de "pronto significa" **antes** da
   implementação.
4. Ao final do epic, responda explicitamente:
   **"Quais decisões deste epic contradizem ou tensionam o CLAUDE.md?"**

### 7.1 Ordem dos epics

| # | Epic | Estado |
|---|---|---|
| 0 | Fundação | implementado (ago/2026) |
| 1 | Empreendimento e vitrine | implementado (ago/2026) — pendente teste em celular real |
| 2 | Catálogo com capacidade declarada | especificado |
| 3 | Roteamento de pedido | especificado — **fim da v1** |
| 4 | Pedido coletivo | a especificar |
| 5 | Governança de parâmetros | a especificar |
| 6 | Chiquinho (moeda) | a especificar |
| 7 | Camada de observação | a especificar |

**A v1 termina no Epic 3.** Colocar no ar, medir, e só então seguir. A moeda vem
*depois* da governança (Epic 6 depois do 5) porque as regras da moeda são a
primeira coisa que a assembleia deve deliberar.

---

## 8. Processo, não só produto

A rede opera com metodologias dialógicas e horizontais (cf. Freire, 1968). Se as
famílias receberem a plataforma pronta, ela é mais uma coisa que a universidade
trouxe. Se participarem de decidir a regra de rateio e a taxa, a plataforma é
delas.

Isso quase não aparece no código — e define o destino do projeto. Na dúvida entre
uma implementação que decide por elas e uma que expõe a decisão, escolha a
segunda, mesmo que custe mais.

---

## 9. Bibliografia

Ver `docs/REFERENCIAS.md`. Ao implementar algo que responde diretamente a uma
referência, cite no ADR ou em comentário de módulo — o rastro teórico é parte do
entregável acadêmico.
