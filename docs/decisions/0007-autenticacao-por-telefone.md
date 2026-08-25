# ADR 0007 — Autenticação por telefone, sem e-mail, recuperação presencial

**Data:** 2026-08-25 · **Estado:** aceita

## Contexto

Epic 0.3: autenticação nativa do Rails, sem login social, sem verificação bloqueante; e um
alerta — login por e-mail é premissa frágil neste público, parte das pessoas usa apenas
WhatsApp. A revisão de agosto (item 2.4) apontou que o critério de pronto do Epic 1
("uma pessoa, com Android modesto e sem ajuda, cria a página e publica") quebra antes de
tudo na criação da conta, e recomendou decidir agora.

## Decisão

- **Identificador de conta é o telefone**, normalizado para E.164 (`+55DDDNÚMERO`), único.
  E-mail é opcional e não participa do login. Normalizador brasileiro próprio
  (`PhoneNumber`), sem gem.
- **Senha** via `has_secure_password`, mínimo 8 caracteres, **sem regra de complexidade**,
  espaços permitidos. Uma frase é mais fácil de lembrar e digitar num celular do que
  símbolo obrigatório.
- **Sem cadastro público.** Contas são criadas pela coordenação — por tarefa
  (`bin/rails contas:criar[telefone,nome]`) ou por seed — de preferência **em reunião
  presencial**, com a pessoa definindo a própria senha na hora. Isso é `CLAUDE.md` §8
  (processo, não só produto): a entrada na plataforma é um ato da rede, não um formulário.
- **Sem recuperação de senha por e-mail.** O gerador do Rails cria esse fluxo; ele é
  removido. Recuperação é presencial: `bin/rails contas:redefinir_senha[telefone]` gera senha
  temporária e **registra o evento `user.password_reset_by_coordination`**, para que o poder
  de redefinir a senha de qualquer pessoa seja observável.
- **Sessão** persistida em banco (gerador do Rails), **sem `ip_address` e `user_agent`**:
  minimização (`CLAUDE.md` §3.3). Se "suas sessões ativas" for útil um dia, reavaliar.
- Limite de tentativas de login (`rate_limit`, 10 em 3 minutos por IP) contra força bruta.
- Interface em português simples: "Entrar", "Seu telefone (o do WhatsApp)", "Sua senha",
  "Minha conta".

## Alternativas consideradas

- **E-mail como identificador (padrão Rails).** Recusado pelo contexto de uso: exige que a
  pessoa tenha e acesse e-mail no celular.
- **Código por SMS ou WhatsApp (OTP).** Melhor experiência, mas exige API de SMS (custo por
  mensagem, provedor terceiro) ou API oficial do WhatsApp (cadastro comercial). Contradiz
  o Epic 3.3 ("sem API oficial, sem custo") e adiciona um terceiro no caminho do login.
  Fica como possibilidade futura se o volume justificar.
- **Login social.** Recusado pelo Epic 0.3 (terceiro + telemetria).
- **Devise.** Dependência grande para o que o gerador nativo resolve.

## Tensões com o `CLAUDE.md`

- **Assimetria de poder:** quem roda as tarefas cria contas e redefine senhas. É inevitável
  sem canal de recuperação autônomo. Mitigação: evento registrado; pauta explícita para a
  assembleia (Epic 5) — quem pode fazer isso, e como se sabe que fez.
- O rito de "conta criada em reunião" é uma decisão do desenvolvedor sobre o processo da
  rede. Deve ser validado com a coordenação antes do Epic 1.

## Consequências

- `users(name, phone unique, email nullable, password_digest)`; `sessions(user_id, token)`.
- `Current.user` e `Current.session` vêm do gerador; `Current.enterprise` é adicionado (ADR
  0005) e preenchido no Epic 1.
- Identificação por telefone facilita o cruzamento com o WhatsApp do empreendimento no
  Epic 3 — mas isso não deve virar identificação de comprador, que permanece sem conta.
