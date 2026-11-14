---
name: preferencias
description: Controla as preferências do plugin Fábrica de Asas no Ar (ambiente de testes, publicação em produção e trava de produção). Use quando a pessoa quiser ver, desligar ou religar as preferências de publicação da Fábrica de Asas no Ar, escolher como elas recebem atualizações, trazer ou recusar uma atualização delas, ligar ou desligar a trava de produção (quando a pessoa pedir para trabalhar direto na main) ou remover este plugin. Use também quando o começo da conversa avisar que há uma atualização das preferências da Fábrica de Asas no Ar. Para as preferências gerais da Fábrica de Asas (linguagem, versões), a skill é fabrica-de-asas:preferencias.
---

# Preferências da Fábrica de Asas no Ar

Este plugin complementa o plugin Fábrica de Asas e funciona do mesmo jeito: guarda as preferências de publicação em `~/.claude/rules/fabrica-de-asas-no-ar/`, uma pasta que o Claude Code lê sozinho no começo de cada conversa. O que muda aqui vale **a partir da próxima conversa** (a trava de produção é a exceção: vale na hora). Diga isso à pessoa sempre que mudar algo.

Rode com a ferramenta Bash, exatamente assim, trocando só o final:

```bash
CLAUDE_PLUGIN_DATA="${CLAUDE_PLUGIN_DATA}" bash "${CLAUDE_PLUGIN_ROOT}/scripts/preferences.sh" status
```

| Final do comando | Para que serve |
| --- | --- |
| `status` | Mostra se está ligado, o modo de atualização e se há versão nova |
| `diff` | Mostra o que muda entre a versão instalada e a nova |
| `apply` | Traz a versão nova agora |
| `decline` | Não perguntar mais sobre esta versão nova (pergunta de novo na próxima) |
| `on` / `off` | Liga ou desliga as preferências de publicação |
| `updates auto` / `ask` / `manual` | Atualiza sozinho (padrão), pergunta antes, ou só quando a pessoa pedir |

O script responde em linhas técnicas (`state=update-available`). Não mostre isso: traduza em uma frase. Para perguntar sobre uma atualização e para mudar uma preferência específica (no CLAUDE.md da pessoa), siga o mesmo caminho da skill `fabrica-de-asas:preferencias`.

## Atualização do plugin
Os dois plugins vêm do mesmo catálogo `fabricadeasas`, então a atualização automática é uma só: confira e ligue como explica a seção "Atualização do plugin" da skill `fabrica-de-asas:preferencias`.

## Trava de produção
Com as preferências ligadas, o plugin impede que a `main`/`master` (produção) mude por outro caminho que não um pedido de junção (pull request) da `dev`. Fica bloqueado salvar ou juntar versões direto na `main` e mandar versões para a `main` do GitHub.

```bash
CLAUDE_PLUGIN_DATA="${CLAUDE_PLUGIN_DATA}" bash "${CLAUDE_PLUGIN_ROOT}/scripts/production-lock.sh" status
```

Troque `status` por `off` para desligar ou `on` para religar. Vale na hora.

Só desligue quando a própria pessoa pedir para trabalhar direto na `main`, com essas palavras. Nunca desligue por conta própria para destravar um comando bloqueado. Antes, explique em uma frase o risco: "Sem a trava, uma mudança pode ir para o ar sem passar pelo ambiente de testes nem pelo seu ok."

## Desligar
`off` tira as preferências de publicação e a trava de produção, e voltam a valer só as preferências gerais da Fábrica de Asas (trabalho direto na linha principal). As skills de publicação continuam disponíveis. Para voltar: `on`.

## Remover o plugin
1. Rode `off` primeiro, para a pasta de preferências sair junto.
2. Depois: `claude plugin uninstall fabrica-de-asas-no-ar@fabricadeasas` (ou `/plugin` → Installed → fabrica-de-asas-no-ar → Uninstall). O plugin Fábrica de Asas continua instalado.
