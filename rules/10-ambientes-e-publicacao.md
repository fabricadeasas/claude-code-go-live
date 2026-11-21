# Ambientes: `dev` para trabalhar, `main` para produção

Estas regras vêm do plugin Fábrica de Asas no Ar e valem por cima do que as preferências da Fábrica de Asas dizem sobre a linha de trabalho: o trabalho acontece na `dev`, e a `main` é produção.

## Duas linhas
- Trabalhe sempre na linha `dev`, sem a pessoa pedir e sem comentar. Se o projeto já usa `develop` em vez de `dev`, use a `develop`.
- A `main` (ou `master`) é produção. Ela só recebe versões por um pedido de junção (pull request) da `dev`, pela skill `fabrica-de-asas-no-ar:versionamento-publicar-prod`, só quando a pessoa pede para publicar em produção, sempre mostrando antes o que vai ao ar. Fora a primeira versão de um projeto novo, nunca salve, junte ou mande versões direto na `main`. O plugin bloqueia (trava de produção).
- Com a pessoa, fale em "ambiente de testes" e "produção" (ou "no ar"), não em `dev` e `main`.
- Se o CLAUDE.md da pessoa ou do projeto pedir outro jeito de trabalhar com as linhas, vale o dela. Se esse jeito for mexer direto na `main`, a trava de produção precisa ser desligada pela skill `fabrica-de-asas-no-ar:preferencias`, só quando a pessoa pedir.

## As skills de versionamento, com a `dev`
Continue usando as skills `fabrica-de-asas:versionamento-*`, com estes ajustes:
- **Salvar** (`versionamento-salvar`): salve na `dev`. Se estiver na `main`, passe para a `dev` antes (`git switch dev`, ou `git switch -c dev` se ela ainda não existe); as mudanças não salvas vêm junto. Projeto novo: `git init -b main`, a primeira versão na `main` e logo depois `git switch -c dev`.
- **Sincronizar** (`versionamento-sincronizar`):
  - Antes de trazer as novidades, garanta que está na `dev`. Se ela não existe aqui nem em `origin/dev`, crie a partir da `main` (`git switch -c dev`) e mande (`git push -u origin dev`), sem comentar com a pessoa.
  - Depois do pull, se a `main` da nuvem tem versões que a `dev` não tem (`git log --oneline dev..origin/main`), traga também: `git pull --no-rebase origin main`.
  - Mandar a `dev` não precisa de confirmação: ela não é produção. Se a `dev` publica sozinha no ambiente de testes, acompanhe como diz a skill `fabrica-de-asas-no-ar:versionamento-publicar-dev`.
  - Ao criar a cópia na nuvem, use `gh repo create <nome> --private --source=. --remote=origin` e mande a `main` primeiro e depois a `dev` (`git push -u origin main` e `git push -u origin dev`).
  - Nunca mande versões para a `main` por aqui.
- **Baixar** (`versionamento-baixar`): depois de baixar, entre na `dev` (`git switch dev`). Se ela não existir, crie como no sincronizar.
- **Fundir** (`versionamento-fundir`): rascunhos são juntados na `dev` (`git switch dev` e `git merge <rascunho>`, ou `gh pr create --base dev --head <rascunho>` se o projeto revisa por pull request). Nunca junte nada na `main` por aqui.

## Skills de publicação
| Operação | Skill |
| --- | --- |
| Publicar no ambiente de testes | `fabrica-de-asas-no-ar:versionamento-publicar-dev` |
| Publicar em produção (colocar no ar) | `fabrica-de-asas-no-ar:versionamento-publicar-prod` |

# Publicar é levar até o destino
A regra "Publicar é levar até o destino" das preferências da Fábrica de Asas vale aqui, com os dois destinos:
- **"Publica no ambiente de testes"** (ou "quero testar antes", "publica para eu ver"): salvar, mandar a `dev` e acompanhar até estar publicado e conferido no endereço de testes.
- **"Publica em produção"** (ou "coloca no ar", "manda para o ar", "libera para os clientes"): tudo que for preciso para chegar lá, inclusive passar pela `dev`, abrir o pedido de junção da `dev` para a `main`, juntar, acompanhar a publicação e conferir no ar. O pedido da pessoa **é** a autorização: mostre o que vai ao ar e siga, sem perguntar etapa por etapa.
- **"Publica" sem dizer onde**: se o projeto tem ambiente de testes e produção, pergunte só o destino, uma vez.
- Nunca leve nada para produção por iniciativa sua. Sem o pedido, a mudança fica na `dev` e entra em PENDÊNCIAS ("No ambiente de testes, ainda não publicado em produção").

# Quando algo vai ficar disponível para o público
Quando você identificar que algo será disponibilizado para acesso público (site no ar, sistema com usuários de fora, app publicado), siga a skill `fabrica-de-asas-no-ar:publicar-com-seguranca` e não deixe publicar antes de passar por ela.
