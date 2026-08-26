# ADR 0004 — Valor monetário: inteiro + unidade explícita, sem conversão

**Data:** 2026-08-25 · **Estado:** aceita

## Contexto

`CLAUDE.md` §3.1: valores monetários são inteiros na menor unidade, nunca `float`; Real e
Chiquinho são unidades distintas e não somáveis, e o tipo deve tornar a soma acidental
**impossível**, não improvável. Epic 0.4 pede objeto de valor, tipo customizado do
ActiveRecord e teste que percorre o schema.

`docs/REFERENCIAS.md` (seção D) registra que o Bacen exige lastro 1:1 em reais para moedas
sociais — logo existe *relação* entre as unidades. A revisão de agosto (item 2.13) apontou
que "não somável" não é o mesmo que "não conversível", e que a conversão precisa ser
modelada como lançamento, nunca como aritmética.

## Decisão

Objeto de valor `Amount` (`app/models/amount.rb`):

- `Amount.new(cents, unit)`; `unit ∈ %i[brl chiquinho]`. Construtores `Amount.brl(n)` e
  `Amount.chiquinho(n)`. Aceita apenas `Integer`; `Float`, `BigDecimal`, `Rational` e
  `String` levantam `ArgumentError`.
- `+` e `-` entre unidades diferentes levantam `Amount::UnitMismatch`. `*` só por `Integer`.
  `Comparable` só dentro da mesma unidade (comparar unidades diferentes levanta).
  Instâncias são congeladas.
- **Não existe** `convert`, `exchange`, `to_brl`, `to_chiquinho` nem taxa de câmbio como
  atributo do valor. A conversão entre Real e Chiquinho, quando existir (Epic 6), é um
  **lançamento** (`Entry`) que debita numa unidade e credita em outra, com a regra de
  conversão vinda de parâmetro de governança (Epic 5), registrada em evento.
- Formatação em `to_s` com aritmética inteira: `R$ 1.234,56`; `5 Chiquinhos`. Nunca dividir
  por `100.0`. Símbolo e grafia do Chiquinho serão confirmados com a feira antes do Epic 6.
- Tipo `Amount::Type` registrado no ActiveModel como `:amount`, com opção `unit:`:
  `attribute :price, :amount, unit: :brl`. Persiste em coluna `bigint`. **A unidade é
  declarada por atributo no código, não armazenada por linha.** Uma tabela que precise das
  duas unidades tem duas colunas — e a soma acidental continua impossível pelo tipo.

Teste de schema (`spec/schema/no_float_spec.rb`): percorre todas as tabelas e falha se
existir coluna `float`, `double precision`, `real`, `numeric` ou `decimal`. **Estrito de
propósito:** não há uso legítimo previsto de ponto flutuante neste domínio; relaxar o teste
exige tocar nele, e é isso que o torna útil.

## Alternativas consideradas

- **Gem `money`.** Madura, com registro de moedas customizadas. Recusada porque seu desenho
  central é conversão via `Money::Bank` — `Money#+` entre moedas diferentes tenta converter
  antes de falhar. É exatamente a semântica que o §3.1 proíbe: a soma seria improvável, não
  impossível.
- **Coluna `unit` por linha + coluna `cents`.** Mais flexível, mas permite que uma consulta
  agregue (`SUM(cents)`) linhas de unidades diferentes sem que o tipo impeça. Recusada.
- **`decimal(10,2)`.** Comum em e-commerce. Recusada pelo §3.1 e porque o Chiquinho pode não
  ter subdivisão decimal.

## Consequências

- Todo campo monetário em migrations futuras é `bigint` com sufixo `_cents` (reais) ou
  `_chiquinhos`; o nome carrega a unidade, e o modelo declara o tipo **sobre a coluna**
  (`attribute :price_cents, :amount, unit: :brl`), que passa a ler e escrever `Amount`.
  Um alias de domínio (`price`) dá o nome curto; o writer recusa `Amount` de outra unidade.
- O Epic 6 herda a proibição de aritmética entre unidades e deve modelar a conversão como
  lançamento explícito.

## Rastro teórico

Blanc (2011) e North (2007) sobre moedas complementares; alerta do trueque argentino em
`docs/REFERENCIAS.md` (seção D): regra de conversão e de emissão são decisões deliberáveis,
não constantes — daí não caberem no tipo.
