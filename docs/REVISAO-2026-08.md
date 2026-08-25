# Revisão crítica da especificação — agosto de 2026

> Leitura de `CLAUDE.md`, `docs/epics/00–03` e `docs/REFERENCIAS.md`, feita
> antes do primeiro commit. O objetivo é nomear tensões que os documentos ainda
> não nomeiam — não reabrir decisões já tomadas.
>
> Estado do repositório na data: apenas documentação. Sem código, sem `.git`,
> coerente com a regra de licença antes do primeiro commit (`CLAUDE.md` §5.1).

---

## 1. O que se sustenta

Registrado para que não seja reaberto sem motivo.

- **`CLAUDE.md` como documento de restrições, não de funcionalidades.**
  Funcionalidades mudam; as restrições são a tese. A hierarquia de clientes com
  regra de desempate explícita (§2) é o que vai segurar o projeto quando a
  pesquisa pedir "só mais um campo".
- **Capacidade em vez de estoque** (Epic 2). O achado conceitual mais forte do
  projeto. Não é retórica: muda o schema, muda o Epic 3 (aviso, nunca bloqueio)
  e é pré-condição do Epic 4.
- **Log append-only desde o Epic 0**, com a justificativa correta: dado não
  registrado nos primeiros meses não existe.
- **Parar no Epic 3 e medir.**
- **Exportação como premissa política, não como obrigação de LGPD.**
- **Ordem dos epics**, em especial governança (5) antes da moeda (6).

---

## 2. Tensões a resolver

Ordenadas por custo-se-ignorado. Cada item indica onde a decisão aterrissa.

### 2.1 Append-only vs. expurgo de dados de comprador

**Aterrissa em:** Epic 0 (desenho da tabela `events`, ADR de append-only).

`order.created` (Epic 3.8) carregaria nome e WhatsApp do comprador no payload.
O evento é imutável e indeletável (`CLAUDE.md` §3.3). A rotina de expurgo (Epic
3.9) é obrigatória. As duas coisas não coexistem sem uma regra.

Opções:

1. **Payload de evento nunca contém PII de comprador** — apenas referência ao
   registro (`order_id`, `buyer_id`). O expurgo apaga o registro; o evento
   sobrevive sem identificar ninguém.
2. *Crypto-shredding*: PII cifrada com chave por comprador; expurgo apaga a
   chave.

Recomendação: opção 1, por simplicidade e auditabilidade. Deve constar do ADR
de append-only como regra de conteúdo, não só de imutabilidade.

### 2.2 Rateio automático vs. "nenhuma decisão automatizada sobre pessoas"

**Aterrissa em:** Epic 4 (a especificar); condiciona o modelo de capacidade do
Epic 2.

O rateio de pedido coletivo é um algoritmo decidindo quanto de trabalho e de
renda vai para cada família. Ser parametrizado por assembleia não resolve: a
*execução* continua automática, e `CLAUDE.md` §3.3 proíbe decisão automatizada
sobre pessoas.

Saída coerente com o §8: o sistema produz uma **proposta** de rateio, e alguém
— coordenação ou os próprios empreendimentos — a confirma. O que se registra é
a proposta, a confirmação e eventuais ajustes manuais. Isso é, inclusive, dado
de pesquisa melhor do que o rateio executado às cegas.

### 2.3 O buraco do roteamento por WhatsApp

**Aterrissa em:** Epic 3 (decisão explícita, possivelmente ADR).

`wa.me` abre o WhatsApp no celular **do comprador** com a mensagem
pré-preenchida. Se o comprador fechar a janela, o pedido existe no sistema e o
empreendimento nunca fica sabendo. Não há canal de notificação para o
empreendimento além da ação voluntária do comprador. O painel (3.5) só resolve
se a família abrir o site — o hábito que o próprio epic diz não querer exigir.

É o elo mais frágil da v1. Opções:

1. Aceitar, e modelar `order.routed` honestamente como "comprador clicou em
   enviar", com a página do pedido deixando claro que o envio depende dele.
2. Combinar com aviso por e-mail ao empreendimento (frágil neste público, mas
   é um segundo canal).
3. API oficial do WhatsApp — descartado para a v1 por custo e cadastro.

Detalhes práticos a testar cedo: limite de tamanho do texto pré-preenchido e
encoding de emoji/acentos na URL.

### 2.4 Login por e-mail é o maior risco ao Epic 1

**Aterrissa em:** Epic 0 (ADR de autenticação — não previsto, deveria ser).

O critério de pronto do Epic 1 é "uma pessoa com Android modesto, sem ajuda,
cria a página e publica". O ponto mais provável de quebra é criar a conta. O
Epic 0.3 adia a decisão. Recomendação: decidir agora.

- Identificador de conta é **telefone**, não e-mail. E-mail opcional.
- Senha simples; sem verificação bloqueante.
- Contas podem ser **criadas pela coordenação em reunião presencial**, com a
  pessoa definindo a senha na hora. Encaixa no §8 (processo dialógico) e evita
  o fluxo de cadastro autônomo como pré-requisito.

### 2.5 "Coordenação" é um papel que não existe no modelo

**Aterrissa em:** Epic 1 (modelo de papéis) e Epic 5.

O Epic 2.5 dá à coordenação uma visão privilegiada (capacidade agregada da
rede). O Epic 1 só modela membros de empreendimento. Quem é a coordenação no
sistema? É o embrião do modelo de poder do Epic 5, e chega sem ser nomeado.

Pelo princípio de monitoramento de Ostrom (quem é afetado monitora), a
capacidade agregada deveria ser visível a **todos os membros** da rede, não só
à coordenação. Isso dissolve a necessidade de um papel privilegiado no Epic 2 e
adia a discussão de papéis para o Epic 5, onde ela pertence.

### 2.6 "Venderam mais" é, ele mesmo, uma métrica produtivista

**Aterrissa em:** `CLAUDE.md` §2 (critério de sucesso da v1) e Epic 3
(medição).

O Epic 3.5 recusa painel de metas por ser "dispositivo de intensificação do
trabalho" — e o projeto adota "vender mais" como critério de sucesso. Se as
famílias venderem mais trabalhando além do que aguentam, o projeto acertou a
métrica e falhou na tese.

O campo de capacidade declarada dá o corretivo de graça. Critério proposto:

> As famílias venderam mais **dentro da capacidade que elas mesmas declararam**.

Pedidos abertos vs. capacidade já é um dado que o Epic 3.6 calcula para o aviso.
É também a ponte real com o GT2 (saúde do trabalhador), sem instrumento novo.

### 2.7 Ética de pesquisa precisa vir antes da v1, não no Epic 7

**Aterrissa em:** processo, antes de o Epic 3 subir. Bloqueante para o uso
acadêmico dos dados.

`CLAUDE.md` §2 trata consentimento como assunto de "coleta ativa". Mas o
pesquisador é o desenvolvedor, e o log de eventos será dado de artigo.
Observação passiva de dado operacional por pesquisador ainda é pesquisa com
seres humanos (Res. CNS 510/2016). Se CEP e consentimento coletivo só entrarem
no Epic 7, os dados dos primeiros meses — justamente os que o §3.3 diz que "não
se reconstroem" — podem ficar academicamente inutilizáveis.

Ações: submissão ao CEP com o desenho da v1; termo de consentimento coletivo
discutido em assembleia antes do Epic 3 entrar no ar; registro disso como ADR.

### 2.8 O Epic 2 viola o §2 no próprio texto

**Aterrissa em:** Epic 2.2 (redação).

A justificativa de registrar `product.capacity_changed` é: "o histórico de
capacidade declarada é dado de pesquisa valioso e não custa nada guardar". É
exatamente o argumento que o §2 proíbe. A funcionalidade está certa; a
justificativa precisa ser de valor de uso: a família vê seu próprio histórico,
e ele faz parte do export. Num artigo que defende a regra do §2, um revisor
encontra isso.

### 2.9 Pageview por loja: decidir quem vê

**Aterrissa em:** Epic 0.7 (telemetria) — decisão a registrar.

- Se o empreendimento vê "quantas pessoas viram sua loja": é funcionalidade,
  serve ao cliente primário.
- Se vê o das outras lojas: é ranking por outro nome (§3.2).
- Se ninguém vê: serve só à pesquisa (§2).

Recomendação: contagem agregada por loja, visível **apenas ao próprio
empreendimento**, nunca comparativa. Contagem global visível a todos.

### 2.10 EditorJS vs. mobile-first para público de baixa familiaridade digital

**Aterrissa em:** Epic 1.3 — validar na primeira semana.

Editor de blocos em Android de baixo custo, para público de faixa etária alta,
escrevendo "três parágrafos". O EditorJS foi desenhado para desktop. Foi
validado em projeto anterior — mas não com este público.

Ação: teste em celular real na primeira semana do Epic 1, com allowlist mínima
(parágrafo, imagem). Plano B pronto: formulário simples (texto + fotos),
mantendo o JSON estruturado como formato de persistência para não perder a
reprocessabilidade.

### 2.11 Licença: ser honesto no ADR sobre o que ela protege

**Aterrissa em:** ADR de licença (Epic 0).

- **AGPL-3.0** não impede ninguém de subir um clone extrativista; só obriga a
  publicar o fonte. É compatível com a política de PI da USP e com publicação.
- **Coopyleft** (CoopCycle) restringe o uso a cooperativas, mas **não é
  licença livre segundo a OSI/FSF**, o que pode atritar com a USP, com
  financiadores e com a própria comunidade de software livre.

A proteção real contra o clone é a comunidade e os dados, não o código. A
decisão é política e legítima — o ADR deve dizer isso para o artigo não vender
mais do que a licença entrega.

### 2.12 Export com "links das imagens" não é portabilidade

**Aterrissa em:** Epic 1.5.

Quando a plataforma sair do ar, os links morrem. O export tem que ser um
arquivo único (zip) contendo dados + JSON da vitrine + **os arquivos de
imagem**.

### 2.13 Chiquinho: não somável ≠ não conversível

**Aterrissa em:** Epic 0.4 (primitiva monetária) e Epic 6.

`REFERENCIAS.md` registra que o Bacen exige lastro 1:1 em reais para moedas
sociais. Logo existe conversão — ela só não pode ser aritmética. Deve ser um
**lançamento explícito** (troca), com registro. A primitiva monetária do Epic 0
deve proibir conversão implícita e não prever taxa de câmbio como atributo do
valor.

Alerta maior: digitalizar a moeda pode mudar seu status regulatório. Papel
circulando na feira e ledger com contas nominais são coisas diferentes aos
olhos do regulador. O PL 4476/2023 precisa de responsável nomeado pelo
acompanhamento.

---

## 3. Adições baratas que servem ao cliente primário

- **"Próxima feira" no hub** (Epic 1.2). Data e local da feira presencial é
  possivelmente a informação mais valiosa para o comprador, não está em nenhum
  epic e custa um campo. Também permite medir se a plataforma aumenta venda
  **presencial**, não só pedido roteado — o critério do §2 não distingue os
  dois.

---

## 4. Ajustes menores

- Epic 0 "pronto significa" pede 5 ADRs; o próprio epic exige um sexto (0.6,
  append-only), esta revisão um sétimo (autenticação) e o Epic 3 um oitavo
  (retenção). Trocar o número por "todos os ADRs exigidos neste epic".
- Escopo por empreendimento (`CLAUDE.md` §3.5): preferir **query object
  explícito** a `default_scope` do Rails, que é armadilha conhecida (vaza em
  associações, `unscoped` silencioso). Escrever o teste que falha se algum
  modelo escopável não tiver o escopo aplicado.
- Seeds (Epic 0.9): nomes plausíveis, **nunca reais**. Seed nunca deve conter
  dado de membro real da feira.
- Ordenação rotativa (Epic 1.2): a semente diária deve ser **determinística e
  publicável** (mesma ordem para todos no mesmo dia), para que a regra seja
  observável pela assembleia — o que é o ponto do Epic 5.

---

## 5. Decisões pendentes

| # | Decisão | Onde | Bloqueia |
|---|---|---|---|
| 2.1 | PII fora do payload de eventos | ADR append-only, Epic 0 | Epic 0 |
| 2.4 | Telefone como identificador; conta criada presencialmente | ADR autenticação, Epic 0 | Epic 0 |
| 2.13 | Conversão só por lançamento explícito | ADR valor monetário, Epic 0 | Epic 0 |
| 2.11 | AGPL vs. coopyleft, com limites explícitos | ADR licença, Epic 0 | Primeiro commit |
| 2.9 | Quem vê pageview | Epic 0.7 | Epic 0 |
| 2.7 | CEP e consentimento coletivo | Processo | Epic 3 subir |
| 2.5 | Capacidade agregada visível a todos os membros | Epic 2.5 | Epic 2 |
| 2.12 | Export em zip com imagens | Epic 1.5 | Epic 1 |
| 2.10 | Validar EditorJS em celular real | Epic 1.3 | Epic 1 (semana 1) |
| 2.3 | Modelar `order.routed` honestamente | Epic 3 | Epic 3 |
| 2.6 | Critério de sucesso: "mais, dentro da capacidade" | `CLAUDE.md` §2 | Medição da v1 |
| 2.8 | Reescrever justificativa de `capacity_changed` | Epic 2.2 | — |
| 2.2 | Rateio como proposta, não execução | Epic 4 | Epic 4 |
| 3 | "Próxima feira" no hub | Epic 1.2 | — |

---

## 6. Resumo

A tese é sólida e a documentação está acima do usual em projeto acadêmico. Os
pontos que mudam desenho **agora** são 2.1 (PII no log), 2.4 (login) e 2.7
(ética antes da v1). Os demais aterrissam em ADRs do Epic 0 ou nos epics 4–6
quando forem especificados.
