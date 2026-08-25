# ADR 0001 — Licença: AGPL-3.0

**Data:** 2026-08-25 · **Estado:** aceita, provisória até checagem com a política de PI da USP

## Contexto

`CLAUDE.md` §5.1 exige decidir a licença antes do primeiro commit e propõe AGPL-3.0 ou
uma licença no espírito *coopyleft* (CoopCycle). A motivação é política: uma licença
permissiva permitiria que o código fosse apropriado para montar exatamente a versão
extrativista de marketplace que o projeto critica (Bauwens & Kostakis, 2014, sobre a
insuficiência do cooperativismo de plataforma sob copyright fechado).

O projeto é iniciativa do GT7 (IEA/USP) e o código será produzido em contexto de extensão
universitária, o que sujeita a decisão à política de propriedade intelectual da USP.

## Decisão

**AGPL-3.0-only** desde o primeiro commit. O arquivo `LICENSE` contém o texto integral.

A decisão é **provisória**: o *coopyleft* fica registrado como alternativa a reavaliar após
consulta formal à USP. Trocar de AGPL para uma licença mais restritiva exige acordo de todos
os titulares de direito sobre o código — viável enquanto houver um único contribuidor, e
progressivamente mais difícil depois. Por isso a consulta à USP deve acontecer **antes** de
haver um segundo contribuidor.

## Alternativas consideradas

- **MIT / Apache-2.0 (permissivas).** Recusadas: permitem apropriação fechada, o oposto da
  tese do projeto.
- **Coopyleft (CoopCycle).** Restringe o uso do software a cooperativas e organizações da
  economia social. É a alternativa mais coerente com a tese, mas **não é licença livre**
  segundo OSI e FSF (discrimina por campo de atuação). Isso pode atritar com a política de PI
  da USP, com financiadores e com a comunidade de software livre da qual o projeto depende
  (Rails, PostgreSQL). Mantida como alternativa a reavaliar.
- **GPL-3.0.** Copyleft forte, mas sem a cláusula de rede: quem roda o software como serviço
  sem distribuí-lo não é obrigado a abrir o fonte. Para uma plataforma web, isso esvazia o
  copyleft. AGPL fecha essa brecha.

## O que esta licença protege — e o que não protege

Registrar com honestidade, para que o artigo não venda mais do que a licença entrega:

- AGPL **não impede** que alguém suba um clone extrativista da plataforma. Obriga apenas que
  quem o fizer publique o código-fonte modificado.
- A proteção real contra a apropriação não está no código: está na comunidade que o usa, nos
  dados que pertencem aos empreendimentos (`CLAUDE.md` §3.3) e nas regras de governança que
  a assembleia define (Epic 5). O código sozinho não é o diferencial.
- O valor da AGPL aqui é simbólico e prático ao mesmo tempo: sinaliza a posição do projeto e
  garante que melhorias feitas por terceiros voltem para o comum.

## Consequências

- Todo arquivo de código pode receber cabeçalho SPDX `AGPL-3.0-only`; o `README` declara a
  licença.
- Dependências devem ser compatíveis com AGPL (Rails e o ecossistema Ruby, em geral MIT, são).
- Contribuições externas, quando houver, entram sob a mesma licença. Sem CLA por enquanto;
  se a consulta à USP indicar mudança futura para coopyleft, um CLA pode ser necessário — e
  isso deve ser decidido antes do segundo contribuidor.

## Rastro teórico

Bauwens & Kostakis (2014); Scholz (2016), sobre propriedade e portabilidade; CoopCycle como
caso de licença coopyleft (`docs/REFERENCIAS.md`, seção C).
