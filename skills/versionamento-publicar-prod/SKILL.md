---
name: versionamento-publicar-prod
description: Publica o projeto em produção (leva a linha dev para a main, que dispara a publicação automática do GitHub Actions) para quem não é programador, sem jargão, mostrando antes o que vai ao ar. O pedido da pessoa para publicar é a autorização. Use quando a pessoa quiser colocar no ar, publicar, lançar, subir para produção, atualizar o site ou o sistema de verdade, ou disser "pode publicar", "manda para o ar", "libera para os clientes", ou usar as palavras deploy, produção, prod, main ou master.
---

# Publicar em produção

Produção é o que está no ar para todo mundo. Nesta forma de trabalhar, a linha `main` (ou `master`) é produção: só recebe versões por um pedido de junção (pull request) da `dev`, aberto por aqui, e quem coloca no ar é a automação do GitHub (GitHub Actions) quando a `main` recebe uma versão nova.

## 1. Existe publicação configurada?
Leia os arquivos de `.github/workflows/`. Há publicação em produção quando um deles roda ao receber versões na `main`/`master` (`on: push` com essa linha, ou `workflow_dispatch` usado para isso) e tem passos que mandam o projeto para um servidor (ssh, rsync, scp, script de deploy, CLI de hospedagem como Vercel, Netlify, Fly, Railway, Render, Cloudflare, AWS, Google Cloud, Azure, ou `environment: production`). Um workflow que só roda testes não publica nada.

Se não houver, **não publique e não leve nada para a `main`**. Diga em linguagem simples:
"Ainda não há nada para publicar: este projeto não tem um servidor configurado para ir ao ar. Suas versões estão guardadas no GitHub. Quando você tiver onde hospedar, eu monto a publicação automática pelo GitHub, e aí publicar vira um pedido só."

## 2. Prepare
1. Salve e sincronize o que estiver pendente na `dev` (skills `fabrica-de-asas:versionamento-salvar` e `fabrica-de-asas:versionamento-sincronizar`).
2. Veja o que vai ao ar: `git fetch` e `git log --oneline origin/main..origin/dev` (troque `main` por `master` se for o caso). Se não houver nada, diga que produção já está igual à versão de testes e pare.
3. Confira que os testes passam: rode os testes do projeto e, se a `dev` tiver automação no GitHub, veja o último resultado (`gh run list --branch dev --limit 3`). Teste falhando não vai para produção.
4. Se as mudanças mexem no banco de dados (migrations, scripts de banco), garanta um backup do banco de produção antes.
5. Se é a primeira publicação do projeto, siga antes a skill `fabrica-de-asas-no-ar:publicar-com-seguranca`.

## 3. Mostre o que vai ao ar e siga
Publicar em produção só acontece porque a pessoa pediu. Esse pedido ("publica em produção", "coloca no ar", "manda para o ar") **é** a autorização para o caminho inteiro: não pergunte "posso publicar?", "abro o pedido?", "posso juntar?".

Antes de publicar, mostre em uma mensagem o que vai ao ar, para ela saber o que está indo:

"⚠️ Publicando em <o site/sistema>, para todo mundo que usa, estas mudanças:
- <mudança 1, em linguagem simples>
- <mudança 2>"

E siga direto para o passo 4.

Pare e pergunte só quando:
- Ela **não** pediu produção: pediu só "publica", e o projeto tem ambiente de testes e produção. Pergunte só o destino, uma vez.
- Vai ao ar algo que ela não sabe que estava na `dev` (por exemplo, mudanças de outra conversa ou de outra pessoa). Mostre a lista e pergunte se publica tudo junto.
- Algo impede de verdade: teste falhando, conflito que pede decisão, login expirado, ou uma ação destrutiva que não estava no pedido (apagar dados).

## 4. Publique
1. Abra o pedido de publicação e junte, pelo GitHub:
   `gh pr create --base main --head dev --title "<resumo do que vai ao ar>" --body "<lista das mudanças>"`
   `gh pr merge --merge` (use `--merge`, nunca `--squash` ou `--rebase`: eles fazem a `main` e a `dev` divergirem).
   Se o GitHub exigir que os testes passem antes, espere com `gh pr checks --watch`.
2. Este é o único caminho para a `main`. Nunca junte nem mande nada direto nela (`git merge` ou `git push` na `main`): o plugin bloqueia. Se o `gh` não funcionar, resolva a causa (falta de login: peça para a pessoa rodar `gh auth login`) e tente de novo. Se a cópia das versões não está no GitHub, não há como publicar por aqui: explique e ofereça criar a cópia (skill `fabrica-de-asas:versionamento-sincronizar`).
3. Continue na `dev` e traga a versão de junção da `main`: `git pull --no-rebase origin main`.

## 5. Acompanhe e confira
1. Acompanhe a publicação: `gh run list --branch main --limit 1` e `gh run watch <id> --exit-status`.
2. Se passou, abra o endereço do site (está no workflow, no README ou pergunte) e confira que a mudança está lá.
3. Conte em linguagem simples: "Publiquei. <O que mudou> já está no ar em <endereço>."
4. Se a publicação falhou, diga com todas as letras o que quebrou, se o site continua no ar com a versão anterior, e o próximo passo. Para tirar do ar uma mudança que deu problema, desfaça na `dev` com uma versão nova (`git revert`) e publique de novo por esta skill, com o mesmo alerta.
