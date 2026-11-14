---
name: versionamento-publicar-dev
description: Publica o projeto no ambiente de testes (a linha dev, que o GitHub Actions publica sozinho num endereço de testes) para quem não é programador, sem jargão. Use quando a pessoa quiser ver a mudança funcionando antes de ir para produção, colocar no ambiente de testes, em homologação ou em staging, ou disser "quero testar antes", "publica para eu ver", ou usar as palavras dev, develop, homolog ou staging.
---

# Publicar no ambiente de testes

O ambiente de testes é uma cópia do site ou sistema num endereço só para conferir antes de ir para produção. Nesta forma de trabalhar, ele é a linha `dev`: toda versão nova que chega na `dev` do GitHub vai para lá sozinha, pela automação do GitHub (GitHub Actions). Publicar aqui não precisa de confirmação.

## 1. Existe ambiente de testes configurado?
Leia os arquivos de `.github/workflows/`. Há ambiente de testes quando um deles roda ao receber versões na `dev`/`develop` e tem passos que mandam o projeto para um servidor (ssh, rsync, scp, script de deploy, CLI de hospedagem, `environment: staging`/`dev`). Um workflow que só roda testes não publica nada.

Se não houver, diga em linguagem simples e pare:
"Ainda não há ambiente de testes para publicar: este projeto não tem um servidor de testes configurado. Suas versões estão guardadas no GitHub. Quando você tiver onde hospedar, eu monto a publicação automática pelo GitHub."

## 2. Publique
1. Salve o que estiver pendente (skill `fabrica-de-asas:versionamento-salvar`).
2. Mande para a nuvem (skill `fabrica-de-asas:versionamento-sincronizar`). Esse envio da `dev` é o que dispara a publicação.

## 3. Acompanhe e confira
1. `gh run list --branch dev --limit 1` e `gh run watch <id> --exit-status`.
2. Se passou, abra o endereço de testes (está no workflow, no README ou pergunte) e confira que a mudança está lá.
3. Conte: "Publiquei no ambiente de testes: <endereço>. Confira por lá; quando estiver tudo certo, é só pedir para publicar em produção."
4. Se falhou, diga o que quebrou e o próximo passo, sem jargão.
