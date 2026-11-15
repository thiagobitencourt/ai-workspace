# Kit de início de projeto

Arquivos-modelo para o dia 0 de um projeto novo. O "como trabalhar comigo" está em
`~/.claude/CLAUDE.md` e vale sozinho em todo projeto; este kit é o que se copia para
dentro do repo.

## Como usar

1. Converse sobre o produto antes de qualquer código (problema, usuários, escopo do MVP).
2. Copie os modelos para o repo, tirando o `.modelo` do nome, e preencha juntos:

   | Modelo | Vira | Para quê |
   |---|---|---|
   | `CLAUDE.modelo.md` | `CLAUDE.md` | Manual da IA no projeto: comandos, estrutura, invariantes, ambientes |
   | `ARQUITETURA.modelo.md` | `ARQUITETURA.md` | Desenho técnico e o porquê das decisões |
   | `PLANO_FASES.modelo.md` | `PLANO_FASES.md` | Roteiro em fases, cada uma entregando algo utilizável |
   | `BACKLOG.modelo.md` | `BACKLOG.md` | Próximos passos fora da conversa |
   | `GO_LIVE.modelo.md` | `docs/GO_LIVE.md` | Checklist vivo de produção |
   | `QUALIDADE_IA.modelo.md` | `docs/testes/QUALIDADE_IA.md` | Só se o produto usa LLM |

3. Rode o checklist do dia 0 abaixo antes da Fase 1.

## Checklist do dia 0

- [ ] **Docs de base:** produto (problema, público, escopo, fora de escopo), ARQUITETURA,
      PLANO_FASES e BACKLOG criados e revisados por mim.
- [ ] **CLAUDE.md do projeto** com comandos, estrutura, invariantes e ambientes.
- [ ] **Estratégia de testes em camadas**, decidida e escrita na ARQUITETURA:
  - unitários para regras puras;
  - e2e com as dependências reais que são nossas (banco, filas) e **fakes** só para
    serviços externos (APIs pagas, e-mail, mensageria);
  - roteiro manual curto por fase, para o meu aceite.
- [ ] **CI rodando os testes desde o primeiro PR.**
- [ ] **Ambientes separados:** dev/teste isolado (nome de projeto, banco e porta
      próprios), preview/pré-produção para eu ver as mudanças, e produção. Deploy de
      produção pelo CI.
- [ ] **Ferramenta para testar sem dependências externas** (console de testes, fakes
      ligados por flag), com trava para nunca ligar em produção.
- [ ] **Padrão visual cedo** (se tiver interface): tokens (cores, espaçamentos, tipografia)
      e componentes base (botão, campo, select, modal, tabela, estados vazio/erro/
      carregando) antes da primeira tela de verdade. As telas usam os componentes; não
      reinventam estilo.
- [ ] **Segredos** fora do repo (`.env` no `.gitignore`, `.env.example` versionado).
- [ ] **Memória do projeto** com os limites: o que é produção, o que exige confirmação.
