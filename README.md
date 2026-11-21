# Claude Code no ar

Complemento do plugin [`fabrica-de-asas`](https://github.com/fabricadeasas/claude-code-for-everyone) para quem vai colocar um site ou sistema no ar. Faz parte do curso de publicação da Fábrica de Asas.

O plugin básico guarda as versões do projeto numa linha só. Este acrescenta o que muda quando existe um servidor: um ambiente de testes, a produção protegida e os cuidados antes de abrir para o público.

| O que ele traz | Na prática |
| --- | --- |
| **Salvar não publica** | "Salva" guarda a mudança num rascunho, com cópia no GitHub, sem colocar nada no ar |
| **Ambiente de testes** | "Publica nos testes" leva o rascunho para a versão de testes (`dev`). Se o projeto publica a `dev` sozinho, o Claude confere a mudança no endereço de testes |
| **Publicar num pedido só** | "Publica em produção" faz o caminho inteiro até produção (`main`) e confere no site, sem pedir ok a cada etapa (`/fabrica-de-asas-no-ar:versionamento-publicar-prod`). Se a pessoa diz só "publica", o Claude pergunta se é nos testes ou no ar para todo mundo: nunca supõe produção. Se o projeto não tem para onde publicar, ele salva e avisa |
| **Trava de produção** | Comandos que mudariam a produção sem passar pela versão de testes e pelo pedido de publicação são bloqueados antes de rodar |
| **Só onde faz sentido** | Tudo isso vale nos projetos que têm a versão de testes (`dev`). Projeto que só guarda o código continua como no plugin básico, e a trava não bloqueia nada |
| **Antes de abrir para o público** | Termos de uso, LGPD, segurança e o resto do que conferir na primeira publicação |

## Como instalar

Precisa do plugin `fabrica-de-asas`; se ainda não tiver, ele vem junto. No Claude Code:

```
/plugin marketplace add fabricadeasas/claude-code-for-everyone
/plugin install fabrica-de-asas-no-ar@fabricadeasas
```

As preferências passam a valer **a partir da segunda conversa**: na primeira, o plugin só as coloca no lugar.

Para ajustar ou desligar, converse com o Claude: "desliga as preferências da Fábrica de Asas no Ar" ou "quero trabalhar direto na main" (ele explica o risco antes de desligar a trava).

## Como funciona por dentro

```
.claude-plugin/plugin.json   o plugin, que depende do fabrica-de-asas
rules/                       ambiente de testes, produção e quando publicar
skills/                      versionamento-publicar-dev, versionamento-publicar-prod, publicar-com-seguranca, preferências
hooks/hooks.json             gatilhos: início de conversa e trava de produção
scripts/                     o que os gatilhos executam
```

## Licença

MIT
