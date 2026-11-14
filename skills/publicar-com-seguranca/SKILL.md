---
name: publicar-com-seguranca
description: Lista do que conferir antes de algo ficar disponível para o público. Use quando um site, sistema, app ou API for ao ar, receber usuários de fora, aceitar cadastro ou pagamento, ou quando a pessoa disser "publicar", "colocar no ar", "lançar", "mandar para produção" ou "deixar o pessoal usar".
---

# Antes de ficar público

Algo que vai para o público precisa de cuidados que a pessoa não sabe que existem. Passe por esta lista antes da primeira publicação e de novo quando o sistema mudar muito. Resolva sozinho o que for técnico; leve para a pessoa só o que for decisão dela (textos legais, serviço de pagamento, custos), em linguagem simples.

## A lista
- Criar termos de uso e política de privacidade;
- Estar de acordo com a LGPD;
- Não deixar portas desnecessárias abertas;
- Usar HTTPS/SSL;
- Tudo o que é privado precisa autenticação, controle de acesso;
- Modo de depuração desligado;
- Backup automático;
- Ambiente de produção separado;
- Monitoramento de uptime;
- Limite de requisições;
- Zero downtime deployment;
- Possibilidade de reversão fácil de versão, caso der problema;
- Quer cobrar ou receber pagamento? Nunca guarde dados de cartão. Use um serviço de
  pagamento;
- Sessão com expiração e cookie seguro;
- O sistema está lento ou vai receber muita gente? índices, cache, limites;
- Crie índices quando o volume crescer;
- Se o banco tem regra de acesso por linha, ligue e teste de verdade que um usuário não consegue ver o dado de outro. ISSO É CRÍTICO, esquecer isso é o erro mais comum em sistema feito com IA;
- Não deixe o usuário publicar antes de ter passado em todos os testes automatizados/validações;

## Como conduzir
- Mostre a lista como cartões curtos: o que já está ok, o que falta e o que precisa de decisão dela. Sem jargão: "o site abre com cadeado (HTTPS)", não "TLS configurado".
- O que falta e é técnico, proponha fazer. O que é dela (termos de uso, política de privacidade, escolha do serviço de pagamento), explique por que importa em uma frase.
- Publicar é ação com consequência: só publique com o ok explícito da pessoa, depois da lista.
