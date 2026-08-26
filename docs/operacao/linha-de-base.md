# Linha de base — vendas antes da plataforma

> **Pendente: preencher com a coordenação antes de o Epic 3 entrar no ar com famílias
> reais.** Sem isso não há comparação possível e a pergunta central do projeto
> (`CLAUDE.md` §2) fica sem resposta. Não é pesquisa: é medição de produto, feita com a
> coordenação, e serve primeiro às famílias (Epic 3).

## Como preencher

Uma linha por empreendimento. Valores aproximados, em reais, informados pela própria
família ou pela coordenação. Registrar a data do levantamento e quem informou (papel, não
nome). Guardar este arquivo no repositório **sem** nomes de pessoas — só o nome do
empreendimento, que é público na plataforma.

| Empreendimento | Vende por feira (R$, aprox.) | Feiras por mês | Vende por mês fora da feira (R$, aprox.) | Capacidade que diz ter (por semana) | Data | Informado por |
|---|---|---|---|---|---|---|
| _exemplo: Doces da Cida_ | _120_ | _2_ | _200_ | _10 bolos_ | _2026-09-05_ | _coordenação_ |
| | | | | | | |

## O que comparar depois

`bin/rails medicao:v1` imprime, por mês: pedidos criados, WhatsApp aberto, confirmados,
concluídos (com desfecho pago/entregue), total em reais concluído e quantos produtos
tiveram pedidos abertos acima da capacidade declarada.

A pergunta é dupla (revisão 2.6): **venderam mais** — e **dentro da capacidade que
declararam**? Vender mais trabalhando além do que aguentam é falha da tese, não sucesso.

## Observações do levantamento

_(vazio)_
