# Ambientes: rascunho para trabalhar, `dev` para testes, `main` para produção

Estas regras vêm do plugin Fábrica de Asas no Ar e valem por cima do que as preferências da Fábrica de Asas dizem sobre a linha de trabalho.

## Quando valem
Só em projetos que têm a linha `dev` (ou `develop`), aqui ou no GitHub (`git branch -a`). Ela é o sinal de que o projeto tem ambiente de testes e produção.

Sem a `dev`, o projeto só guarda o código, ou publica direto da linha principal. Aí estas regras não se aplicam: valem só as preferências da Fábrica de Asas (trabalho na linha principal), e a trava de produção não bloqueia nada. Não crie a `dev` só porque ela não existe.

A `dev` nasce quando o projeto ganha um ambiente de testes: ao montar a publicação automática com ambiente de testes, crie a `dev` a partir da `main` (`git switch -c dev` e `git push -u origin dev`) e passe a trabalhar como abaixo.

## Três lugares
- **Rascunho**: uma linha por assunto, com nome curto (ex.: `formulario-contato`). É onde o trabalho acontece. Salvar guarda a versão aqui e a cópia na nuvem, e não coloca nada em lugar nenhum.
- **`dev`** (ou `develop`): o ambiente de testes. Só recebe um rascunho quando a pessoa pede para publicar.
- **`main`** (ou `master`): produção. Só recebe versões por um pedido de junção (pull request) da `dev`, pela skill `fabrica-de-asas-no-ar:versionamento-publicar-prod`. Nunca salve, junte ou mande versões direto na `main`. O plugin bloqueia (trava de produção).
- Com a pessoa, fale em "rascunho", "ambiente de testes" e "produção" (ou "no ar"), não em branch, `dev` e `main`.
- Se o CLAUDE.md da pessoa ou do projeto pedir outro jeito de trabalhar com as linhas, vale o dela. Se esse jeito for mexer direto na `main`, a trava de produção precisa ser desligada pela skill `fabrica-de-asas-no-ar:preferencias`, só quando a pessoa pedir.

## Salvar e publicar: um pedido, o caminho inteiro
| A pessoa diz | O que você faz, do começo ao fim |
| --- | --- |
| "salva", "guarda", "salva para eu ver depois" | Versão no rascunho e cópia na nuvem. Nada vai para o ambiente de testes nem para produção |
| "publica nos testes", "em homologação", "quero ver funcionando antes" | Salva, leva o rascunho para a `dev`, acompanha a publicação e confere no endereço de testes (`fabrica-de-asas-no-ar:versionamento-publicar-dev`) |
| "publica em produção", "coloca no ar para todo mundo", "libera para os clientes" | Tudo o que o ambiente de testes pede e, em seguida, leva a `dev` para a `main`, acompanha e confere no ar (`fabrica-de-asas-no-ar:versionamento-publicar-prod`) |
| Só "publica", "sobe", "manda", sem dizer onde | Pergunte o destino, uma vez: "No ambiente de testes ou no ar para todo mundo?" |

- Produção pede cuidado redobrado: só vá para lá quando a pessoa disser produção com todas as letras ("produção", "no ar para todo mundo", "para os clientes"). Na dúvida sobre o destino, pergunte; nunca suponha produção.
- Com o destino claro, o pedido já é a autorização para todas as etapas até lá. Não pare para perguntar "posso salvar?", "posso juntar?", "posso publicar?" no meio do caminho, e não fale em commit, push ou merge.
- Pare no meio só quando algo impedir de verdade: teste falhando, conflito que pede uma decisão dela, login expirado, algo crítico na lista de segurança da primeira publicação, ou uma ação destrutiva que não estava no pedido (por exemplo, uma mudança que apaga dados do banco). Diga em que ponto parou e por quê.
- Nada de ponta solta: se algo ficou salvo num rascunho e ainda não foi publicado, diga isso no fim da resposta, em uma linha.

## As skills de versionamento, com o rascunho
Continue usando as skills `fabrica-de-asas:versionamento-*`, com estes ajustes:
- **Salvar** (`versionamento-salvar`):
  - Salve no rascunho do assunto. Se estiver na `dev` ou na `main`, crie o rascunho antes (`git switch -c <assunto>`); as mudanças não salvas vêm junto.
  - Salvar termina sempre com a cópia na nuvem (`git push -u origin <rascunho>`), sem perguntar: mandar um rascunho não publica nada.
- **Sincronizar** (`versionamento-sincronizar`):
  - Assunto novo começa da `dev` atualizada: `git switch dev`, `git pull --no-rebase`, depois `git switch -c <assunto>`.
  - Se a `dev` só existe no GitHub, traga para cá: `git switch dev` (o git cria a linha local a partir da nuvem).
  - Num rascunho, depois de trazer as novidades dele, traga também as da `dev`: `git pull --no-rebase origin dev`.
  - Na `dev`, se a `main` da nuvem tem versões que a `dev` não tem (`git log --oneline dev..origin/main`), traga também: `git pull --no-rebase origin main`.
  - Por aqui, mande só rascunhos. A `dev` e a `main` recebem versões pelas skills de publicação.
- **Baixar** (`versionamento-baixar`): depois de baixar, se o projeto tem `dev`, entre nela (`git switch dev`). O trabalho começa num rascunho.
- **Fundir** (`versionamento-fundir`): juntar um rascunho na `dev` é publicar no ambiente de testes, então acontece pela skill `fabrica-de-asas-no-ar:versionamento-publicar-dev`, quando a pessoa pede para publicar. Nunca junte nada na `main` por aqui.

## Skills de publicação
| Operação | Skill |
| --- | --- |
| Publicar no ambiente de testes | `fabrica-de-asas-no-ar:versionamento-publicar-dev` |
| Publicar em produção (colocar no ar) | `fabrica-de-asas-no-ar:versionamento-publicar-prod` |

# Quando algo vai ficar disponível para o público
Quando você identificar que algo será disponibilizado para acesso público (site no ar, sistema com usuários de fora, app publicado), siga a skill `fabrica-de-asas-no-ar:publicar-com-seguranca` e não deixe publicar antes de passar por ela.
