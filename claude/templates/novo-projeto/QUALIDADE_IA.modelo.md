# Qualidade da IA (projetos com LLM)

Use quando o produto tem um LLM conversando ou decidindo. O comportamento do modelo não é
determinístico, então os testes normais não bastam.

## Princípios

- **Regra crítica fica no código.** O LLM só age através de tools/funções, e cada handler
  valida de forma independente se a ação é permitida (estado, pré-requisitos). O prompt
  orienta; o código garante.
- **Defesa contra prompt injection:** o modelo nunca executa ação sensível só porque o
  texto do usuário pediu. Ter e2e de tentativas de manipulação.
- **e2e com LLM falso** para o pipeline (determinístico, barato, no CI). Qualidade da
  conversa se mede à parte, com o modelo real.

## Rodadas de qualidade

- **Plano:** cenários com roteiro, **gabarito** (o que deve acontecer) e **rubrica**
  (critérios e níveis: atende / parcial / não atende).
- **Execução cega:** banco limpo, julgar contra o gabarito sem olhar o backlog anterior.
- **Harness versionado no repo** (ex.: `scripts/qualidade/`), com resultado também em JSON
  para comparar rodadas.
- **Pontuação automática** do que dá para checar no código (tool chamada, estado final,
  guard disparado). Julgamento humano só para tom e naturalidade.
- **Duas suítes:**
  - rápida (~10 cenários críticos) a cada mudança de prompt ou tool;
  - completa antes de cada release.
- **Achado corrigido vira regressão:** teste com fixture ou validador no código. Ajuste
  só de prompt não segura uma correção.
- **Achados numerados** (ex.: R3-I2) com status, para acompanhar entre rodadas.
- Rodadas antigas viram um resumo de uma página com a evolução dos achados.

## Em produção

- Métricas a partir dos logs/auditoria: taxa de escalonamento para humano, guards
  disparados, conversas abandonadas, tempo até a etapa principal.
