# CLAUDE.md

Orientação ao Claude Code neste repositório. O acordo de trabalho geral está em
`~/.claude/CLAUDE.md`; aqui fica só o que é específico deste projeto.

## Projeto

<!-- 3 a 5 linhas: o que o sistema faz, para quem, peças principais e onde roda. -->

Documentos (leia a ARQUITETURA antes de mudanças não triviais):

- [ARQUITETURA.md](ARQUITETURA.md) — desenho técnico e o porquê das decisões.
- [PLANO_FASES.md](PLANO_FASES.md) — roteiro em fases.
- [BACKLOG.md](BACKLOG.md) — próximos passos e pendências.
- [docs/GO_LIVE.md](docs/GO_LIVE.md) — checklist de produção. Mudou algo que a produção
  precisa configurar? Atualize.

Idioma do código, identificadores, commits e docs: <!-- ex.: português -->.

## Comandos

```bash
# instalar, rodar em dev, testes unitários, um único teste, e2e, migrations, build
```

## Estrutura

<!-- Pastas por responsabilidade e o que vive em cada uma. -->

## Invariantes

<!-- Regras curtas e verificáveis que não podem ser quebradas. Uma linha cada, com o
porquê em poucas palavras. Ex.:
- Todo efeito externo passa por `integracoes/` (é onde ficam fakes e travas).
- Toda ação sensível valida o estado no código, nunca só no prompt.
- Toda lista/contador novo exclui dados de teste/simulados.
-->

## Testes

<!-- Camadas, como rodar, o que usa fake e o que usa dependência real, e qualquer
cuidado (ex.: e2e precisam de concorrência 1 porque compartilham o banco). -->

## Ambientes

| Ambiente | Onde | Como atualiza | Observações |
|---|---|---|---|
| dev/teste | local | — | nome de projeto, banco e porta próprios |
| preview/pré-prod | | manual / CI | atualizar depois de cada mudança |
| produção | | CI no merge | qualquer ação manual só com confirmação |

## Configuração

<!-- Onde as variáveis são lidas, quais são obrigatórias (derrubam o boot) e quais são
opcionais (falham de forma suave). Flags de fake e suas travas. -->
