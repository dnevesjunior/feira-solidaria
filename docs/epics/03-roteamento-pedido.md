# Epic 3 — Roteamento de pedido

> Pré-requisitos: `CLAUDE.md`, Epics 0–2 concluídos.
> **Este epic encerra a v1.**

## Objetivo

Uma pessoa escolhe itens, envia um pedido, e o empreendimento recebe esse pedido
de forma estruturada pelo WhatsApp. A plataforma registra o pedido e acompanha
seu desfecho. **Nenhum dinheiro passa pela plataforma.**

## O limite que não se atravessa

A plataforma **não intermedia pagamento em reais** (`CLAUDE.md` §3.1). Sem
gateway, sem split, sem custódia, sem "carteira". A liquidação acontece
diretamente entre comprador e empreendimento, por Pix ou dinheiro, fora do
sistema.

Isso não é limitação técnica nem timidez de escopo: intermediar pagamento
aciona regime regulatório de instituição de pagamento e inviabiliza um piloto de
extensão universitária. Qualquer sugestão de "integrar Pix para facilitar" deve
ser recusada e, se insistente, registrada como ADR de recusa.

## Fora de escopo

Pedido coletivo e rateio (Epic 4). Aqui, um pedido pertence a **um**
empreendimento. Se a pessoa escolher itens de dois empreendimentos, o sistema
gera **dois pedidos independentes** — e a interface deve dizer isso claramente
antes do envio.

---

## Escopo

### 3.1 Cesta

- Leve, sem login obrigatório para o comprador.
- Persistência em sessão. Sem cookie de rastreio, sem identificação
  entre visitas (`CLAUDE.md` §3.3).
- Se contiver itens de mais de um empreendimento, exibir de forma explícita que
  isso resultará em pedidos separados, com contatos separados.

### 3.2 `Order` (Pedido)

- Pertence a um empreendimento. Contém itens com quantidade e **preço
  congelado no momento do pedido** (nunca referenciar o preço atual do produto —
  ele muda).
- Dados do comprador: nome e WhatsApp. Nada além disso.
  **Não pedir CPF, endereço completo, data de nascimento ou e-mail.** Coletar
  dado que não se usa é violação de minimização (LGPD) e não serve a ninguém.
- Observação livre do comprador.
- Ciclo de vida explícito e curto:
  `recebido → confirmado → concluído`, com ramos `recusado` e `cancelado`.
- **Cada transição é registrada manualmente pelo empreendimento.** A plataforma
  não infere, não presume, não conclui automaticamente por decurso de prazo.

### 3.3 Roteamento por WhatsApp

- Ao enviar, o sistema gera uma **mensagem estruturada** e abre o WhatsApp do
  empreendimento com ela pré-preenchida.
- A mensagem contém: código do pedido, itens, quantidades, valores, total, nome
  do comprador, observação, e o link do pedido no sistema.
- Formato pensado para ser **lido no celular sem rolar muito**, e para que o
  empreendimento consiga responder direto na conversa.
- Usar link `wa.me` — sem API oficial, sem custo, sem cadastro de conta
  comercial. Se no futuro houver volume que justifique, é outra conversa.

### 3.4 Página do pedido

- Endereço com token não sequencial (não `/pedidos/1`).
- Comprador vê o estado do pedido.
- Empreendimento, autenticado, altera o estado.
- Sem chat interno. A conversa acontece no WhatsApp, onde essas pessoas já
  estão. Construir mensageria própria seria pedir que mudem de hábito para
  atender à plataforma.

### 3.5 Painel do empreendimento

- Lista dos pedidos por estado.
- **Sem métrica de conversão, sem funil, sem gráfico de desempenho, sem meta.**
  Painel de vendas com metas é dispositivo de intensificação do trabalho, e o
  Observatório existe, entre outras coisas, para estudar isso. Não faz sentido
  produzi-lo aqui.
- O que é útil e legítimo: quais pedidos estão abertos e o que precisa ser feito
  hoje.

### 3.6 Capacidade como aviso, nunca como bloqueio

- Se a soma de pedidos abertos ultrapassar a capacidade declarada, exibir
  **aviso ao empreendimento** — não bloquear o pedido, não esconder o produto,
  não avisar o comprador.
- A decisão de aceitar ou recusar é da pessoa que produz. O sistema informa;
  quem decide é ela.
- Este é um caso onde o padrão de marketplace ("sem estoque → indisponível")
  seria tecnicamente trivial e politicamente errado.

### 3.7 Registro de desfecho

- Ao concluir, o empreendimento marca se o pedido foi efetivamente pago e
  entregue — sim/não/parcial, mais uma observação opcional.
- Sem cobrança, sem verificação, sem consequência automática de resposta
  negativa.
- É a única fonte que permitirá responder à pergunta que define o sucesso da v1
  (`CLAUDE.md` §2).

### 3.8 Eventos registrados

`order.created`, `order.routed`, `order.confirmed`, `order.refused`,
`order.cancelled`, `order.completed`, `order.outcome_recorded`.

### 3.9 Retenção e minimização

- Dado de comprador tem prazo de retenção definido em ADR e rotina de expurgo
  implementada — não anotada como pendência.
- Exportação do Epic 1 estendida para incluir pedidos.

---

## Medição do sucesso da v1

Antes de subir este epic, registrar a **linha de base**: quanto as famílias
vendem hoje, por feira e por mês, sem a plataforma. Levantamento simples com a
coordenação. Sem isso, não haverá comparação possível depois — e a pergunta
central do projeto fica sem resposta.

Não confundir com pesquisa: é medição de produto, feita com a coordenação, e
serve primeiro às famílias.

---

## Pronto significa

- [ ] Uma pessoa que nunca viu a plataforma escolhe dois itens, envia o pedido e
      o empreendimento recebe uma mensagem legível no WhatsApp em menos de um
      minuto.
- [ ] O empreendimento confirma e conclui o pedido pelo celular.
- [ ] Itens de dois empreendimentos geram dois pedidos, e o comprador sabe disso
      antes de enviar.
- [ ] Nenhuma requisição para gateway de pagamento existe no código — revisão
      confirma.
- [ ] Nenhum campo de CPF, endereço completo ou data de nascimento existe no
      formulário.
- [ ] Ultrapassar a capacidade declarada gera aviso e **não** impede o pedido —
      teste prova.
- [ ] O preço registrado no pedido não muda quando o preço do produto muda —
      teste prova.
- [ ] A rotina de expurgo de dados de comprador roda e apaga — teste prova.
- [ ] A linha de base de vendas pré-plataforma está registrada.

---

## Depois deste epic: parar

Colocar no ar. Deixar rodar. Medir.

**Não iniciar o Epic 4 antes de ter resposta para: as famílias venderam mais do
que venderiam sem a plataforma?**

Se a resposta for não, o próximo trabalho é descobrir por quê — e provavelmente
é demanda, não produto. O Epic 4 (pedido coletivo, com demanda institucional de
USP, PUC e rede paroquial) é a hipótese principal de resposta, mas só faz
sentido construí-lo sabendo que o problema é esse.

---

## Ao final do epic

Responder: **quais decisões deste epic contradizem ou tensionam o `CLAUDE.md`?**
