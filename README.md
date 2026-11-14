# Claude Code, go live

**English** · [Português (Brasil)](README.pt-BR.md)

Add-on to the [`fabrica-de-asas`](https://github.com/fabricadeasas/claude-code-for-everyone) plugin for people who are about to put a website or system online. Part of the Fábrica de Asas publishing course.

The basic plugin keeps the project's versions on a single line. This one adds what changes once there is a server: a test environment, a protected production line and the checks to run before opening to the public.

| What it brings | In practice |
| --- | --- |
| **Test environment** | Claude works on a test line (`dev`) without being asked. If the project deploys `dev` automatically, you see the change at a test address before it goes live |
| **Publish without surprises** | Production (`main`) only receives changes after a warning and your OK (`/fabrica-de-asas-no-ar:versionamento-publicar-prod`). If the project has no server configured on GitHub yet, it tells you there is nothing to publish |
| **Production lock** | Commands that would change production without going through the test line and the publish request are blocked before they run |
| **Before going public** | Terms of use, privacy law (LGPD), security and the rest of what to check on the first release |

## How to install

It needs the `fabrica-de-asas` plugin, which is installed along with it if missing. In Claude Code:

```
/plugin marketplace add fabricadeasas/claude-code-for-everyone
/plugin install fabrica-de-asas-no-ar@fabricadeasas
```

The preferences take effect **from the second conversation on**: in the first one, the plugin only puts them in place.

To adjust or turn it off, talk to Claude: "turn off the Fábrica de Asas no Ar preferences" or "I want to work straight on main" (it explains the risk before turning the lock off).

For now, the plugin is available in Portuguese only.

## How it works

```
.claude-plugin/plugin.json   the plugin, which depends on fabrica-de-asas
rules/                       test environment, production and when to publish
skills/                      versionamento-publicar-dev, versionamento-publicar-prod, publicar-com-seguranca, preferences
hooks/hooks.json             triggers: session start and production lock
scripts/                     what the triggers run
```

## License

MIT
