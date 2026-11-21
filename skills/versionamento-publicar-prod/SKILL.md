---
name: versionamento-publicar-prod
description: Publica o projeto em produção num pedido só (passa pelo ambiente de testes, leva a linha dev para a main, que dispara a publicação automática do GitHub Actions, acompanha e confere no ar) para quem não é programador, sem jargão. O pedido com o destino claro é a autorização para o caminho inteiro, sem confirmação a cada etapa. Use quando a pessoa quiser colocar no ar para todo mundo, lançar, subir para produção, atualizar o site ou o sistema de verdade, ou disser "publica em produção", "manda para o ar", "libera para os clientes", ou usar as palavras deploy, produção, prod, main ou master. Se ela disser só "publica" num projeto com ambiente de testes, use esta skill para perguntar o destino antes; nunca suponha produção.
---

# Publicar em produção

Produção é o que está no ar para todo mundo. Nesta forma de trabalhar, a linha `main` (ou `master`) é produção: só recebe versões por um pedido de junção (pull request) da `dev`, aberto por aqui, e quem coloca no ar é a automação do GitHub (GitHub Actions) quando a `main` recebe uma versão nova.

## Produção só com o destino dito com todas as letras
Produção pede cuidado redobrado. Siga por aqui só quando a pessoa disser produção sem margem de dúvida: "produção", "prod", "no ar para todo mundo", "para os clientes", "lançar". Se ela disse só "publica", "sobe" ou "manda" e o projeto tem ambiente de testes, pergunte o destino antes de mexer em qualquer coisa: "No ambiente de testes ou no ar para todo mundo?". Na dúvida, nunca suponha produção.

## Com o destino claro, o pedido é o ok
Quando a pessoa pede produção, ela já autorizou todas as etapas: salvar, passar pelo ambiente de testes, levar para produção e conferir. Faça tudo de uma vez. Não pergunte "posso publicar?" no meio e não fale em commit, push, merge ou pull request.

Pergunte só quando:
- Ela não pediu para publicar: foi você que percebeu que valeria. Ofereça em uma frase e espere.
- O destino não ficou claro (veja acima).
- A lista de segurança da primeira publicação encontrou algo crítico ou que só ela pode decidir.
- A publicação faria algo destrutivo que não estava no pedido (por exemplo, uma mudança que apaga dados do banco).

Pare também se algo impedir de verdade (teste falhando, conflito que pede uma decisão dela, login expirado) e diga em que ponto parou e por quê.

## 1. Existe publicação configurada?
Leia os arquivos de `.github/workflows/`. Há publicação em produção quando um deles roda ao receber versões na `main`/`master` (`on: push` com essa linha, ou `workflow_dispatch` usado para isso) e tem passos que mandam o projeto para um servidor (ssh, rsync, scp, script de deploy, CLI de hospedagem como Vercel, Netlify, Fly, Railway, Render, Cloudflare, AWS, Google Cloud, Azure, ou `environment: production`). Um workflow que só roda testes não publica nada.

Se não houver, **não leve nada para a `main`**: o que a pessoa quis, na prática, foi salvar. Salve o que estiver pendente (fica guardado no rascunho, com cópia na nuvem) e diga em linguagem simples:
"Este projeto ainda não tem onde ficar no ar, então salvei suas mudanças e a cópia no GitHub. Quando você tiver onde hospedar, eu monto a publicação automática, e aí publicar vira um pedido só."

## 2. Passe pelo ambiente de testes
1. Siga a skill `fabrica-de-asas-no-ar:versionamento-publicar-dev` inteira: ela salva, leva o rascunho para a `dev` e confere no endereço de testes, se houver. Se algo falhar ali, pare.
2. Veja o que vai ao ar: `git fetch` e `git log --oneline origin/main..origin/dev` (troque `main` por `master` se for o caso). Se não houver nada, diga que produção já está igual à versão de testes e pare.
3. Confira os testes na `dev`: o resultado da automação (`gh run list --branch dev --limit 3`). Teste falhando não vai para produção.
4. Se as mudanças mexem no banco de dados (migrations, scripts de banco), faça um backup do banco de produção antes, sem perguntar.
5. Se é a primeira publicação do projeto, passe antes pela skill `fabrica-de-asas-no-ar:publicar-com-seguranca`.

## 3. Publique
1. Abra o pedido de publicação e junte, pelo GitHub:
   `gh pr create --base main --head dev --title "<resumo do que vai ao ar>" --body "<lista das mudanças>"`
   `gh pr merge --merge` (use `--merge`, nunca `--squash` ou `--rebase`: eles fazem a `main` e a `dev` divergirem; e nunca `--delete-branch`: a `dev` fica).
   Se o GitHub exigir que os testes passem antes, espere com `gh pr checks --watch`.
2. Este é o único caminho para a `main`. Nunca junte nem mande nada direto nela (`git merge` ou `git push` na `main`): o plugin bloqueia. Se o `gh` não funcionar, resolva a causa (falta de login: peça para a pessoa rodar `gh auth login`) e tente de novo. Se a cópia das versões não está no GitHub, não há como publicar por aqui: explique e ofereça criar a cópia (skill `fabrica-de-asas:versionamento-sincronizar`).
3. Continue na `dev` e traga a versão de junção da `main`: `git pull --no-rebase origin main`.

## 4. Acompanhe e confira
1. Acompanhe a publicação: `gh run list --branch main --limit 1` e `gh run watch <id> --exit-status`.
2. Se passou, abra o endereço do site (está no workflow, no README ou pergunte) e confira que a mudança está lá.
3. Conte em linguagem simples o que foi ao ar: "Publiquei. Já está no ar em <endereço>:" seguido das mudanças, uma por linha.
4. Se a publicação falhou, diga com todas as letras o que quebrou, se o site continua no ar com a versão anterior, e o próximo passo. Para tirar do ar uma mudança que deu problema, desfaça num rascunho com uma versão nova (`git revert`) e publique de novo por esta skill.
