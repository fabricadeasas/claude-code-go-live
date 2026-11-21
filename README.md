# Claude Code no ar

Complemento do plugin [`fabrica-de-asas`](https://github.com/fabricadeasas/claude-code-for-everyone) para quem vai colocar um site ou sistema no ar. Faz parte do curso de publicação da Fábrica de Asas.

O plugin básico guarda as versões do projeto numa linha só. Este acrescenta o que muda quando existe um servidor: um ambiente de testes, a produção protegida e os cuidados antes de abrir para o público.

| O que ele traz | Na prática |
| --- | --- |
| **Ambiente de testes** | O Claude trabalha numa versão de testes (`dev`) sem você pedir. Se o projeto publica a `dev` sozinho, você vê a mudança num endereço de testes antes de ir ao ar |
| **Publicar sem susto** | Produção (`main`) só recebe mudanças quando você pede para publicar, e antes você vê o que vai ao ar (`/fabrica-de-asas-no-ar:versionamento-publicar-prod`). Pediu, ele leva até o fim, sem perguntar etapa por etapa. Se o projeto ainda não tem servidor configurado no GitHub, ele avisa que não há o que publicar |
| **Trava de produção** | Comandos que mudariam a produção sem passar pela versão de testes e pelo pedido de publicação são bloqueados antes de rodar |
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
