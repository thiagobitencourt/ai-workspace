# Arquitetura

Mantida em sincronia com o código. Explica o **porquê** das decisões não óbvias.

## 1. Visão geral

<!-- Componentes, como se conectam e onde rodam. Um diagrama simples ajuda. -->

## 2. Fluxos principais

<!-- Passo a passo dos 2 ou 3 fluxos centrais, incluindo concorrência e falhas. -->

## 3. Modelo de dados

<!-- Tabelas/entidades principais e relacionamentos. Fonte da verdade. -->

## 4. Integrações externas

<!-- Cada serviço externo: para que serve, como falha (derruba ou degrada), fake usado em
teste, trava de produção. -->

## 5. Estratégia de testes

| Camada | O que cobre | Dependências | Quando roda |
|---|---|---|---|
| Unitário | regras puras | nenhuma | a cada mudança, no CI |
| e2e | fluxo ponta a ponta | reais as nossas, fake as externas | CI |
| Manual | aceite do dev | ambiente de preview | por fase |

## 6. Infra e operação

<!-- Deploy, backup (com restore testado), monitoramento, alertas (quem recebe), logs. -->

## 7. Segurança

<!-- Autenticação, papéis, segredos, defesa em profundidade, dados sensíveis. -->

## 8. Decisões

Uma entrada por decisão não óbvia. Não apague decisões substituídas: marque como
substituída e aponte a nova.

### AAAA-MM-DD — <título>

- **Contexto:** o problema.
- **Decisão:** o que escolhemos.
- **Por quê:** o motivo e as alternativas descartadas.
- **Consequências:** o que fica mais fácil/difícil; o que vigiar.
