---
name: versionamento-publicar-dev
description: Publica o projeto no ambiente de testes num pedido só (salva, leva o rascunho para a linha dev, acompanha a publicação automática do GitHub Actions e confere no endereço de testes) para quem não é programador, sem jargão e sem pedir ok no meio. Use quando a pessoa quiser ver a mudança funcionando antes de ir para produção, colocar no ambiente de testes, em homologação ou em staging, ou disser "quero testar antes", "publica para eu ver", ou usar as palavras dev, develop, homolog ou staging. Também é a primeira parte de publicar em produção.
---

# Publicar no ambiente de testes

O ambiente de testes é uma cópia do site ou sistema num endereço só para conferir antes de ir para produção. Nesta forma de trabalhar, ele é a linha `dev`: toda versão nova que chega na `dev` do GitHub vai para lá sozinha, pela automação do GitHub (GitHub Actions).

O pedido da pessoa já é o ok para tudo abaixo. Não pergunte nada no meio e não fale em commit, push ou merge. Pare só se algo impedir de verdade (teste falhando, conflito que pede uma decisão dela, login expirado) e diga em que ponto parou.

## 0. O projeto tem ambiente de testes?
Veja se existe a linha `dev` (ou `develop`), aqui ou no GitHub: `git branch -a`.

Se não existe, o projeto não tem ambiente de testes. Não crie a `dev` por conta própria:
- Se o projeto também não publica em lugar nenhum, o que a pessoa quis, na prática, foi salvar. Salve (skill `fabrica-de-asas:versionamento-salvar`) e conte em uma linha: "Este projeto ainda não tem onde ficar no ar, então salvei a versão e a cópia no GitHub."
- Se o projeto publica direto em produção, não publique lá no lugar dos testes. Salve e diga: "Este projeto não tem ambiente de testes: ele vai direto para o ar. Salvei a versão. Quer que eu coloque no ar ou que eu monte um ambiente de testes antes?"

## 1. Leve o rascunho para a `dev`
1. Salve o que estiver pendente no rascunho, com a cópia na nuvem (skill `fabrica-de-asas:versionamento-salvar`, com os ajustes das regras da Fábrica de Asas no Ar).
2. Traga as novidades da `dev` para o rascunho: `git pull --no-rebase origin dev`. Se der conflito, siga a skill `fabrica-de-asas:versionamento-fundir`.
3. Rode os testes do projeto. Teste falhando não vai para o ambiente de testes: pare e diga o que quebrou.
4. Junte o rascunho na `dev`:
   - Com cópia no GitHub: `gh pr create --base dev --head <rascunho> --title "<resumo>" --body "<lista das mudanças>"` e `gh pr merge --merge --delete-branch`. Se o GitHub exigir que os testes passem antes, espere com `gh pr checks --watch`.
   - Sem cópia no GitHub: `git switch dev`, `git merge <rascunho>` e `git branch -d <rascunho>`.
5. Fique na `dev` atualizada: `git switch dev` e `git pull --no-rebase`. O próximo assunto começa num rascunho novo.

## 2. Existe ambiente de testes configurado?
Leia os arquivos de `.github/workflows/`. Há ambiente de testes quando um deles roda ao receber versões na `dev`/`develop` e tem passos que mandam o projeto para um servidor (ssh, rsync, scp, script de deploy, CLI de hospedagem, `environment: staging`/`dev`). Um workflow que só roda testes não publica nada.

Se não houver, diga em linguagem simples e pare:
"Juntei as mudanças na versão de testes, mas este projeto ainda não tem um servidor de testes para mostrar. Quando você tiver onde hospedar, eu monto a publicação automática pelo GitHub."

## 3. Acompanhe e confira
1. `gh run list --branch dev --limit 1` e `gh run watch <id> --exit-status`.
2. Se passou, abra o endereço de testes (está no workflow, no README ou pergunte) e confira que a mudança está lá.
3. Conte: "Publiquei no ambiente de testes: <endereço>. Confira por lá; quando estiver tudo certo, é só pedir para colocar no ar."
4. Se falhou, diga o que quebrou e o próximo passo, sem jargão.
