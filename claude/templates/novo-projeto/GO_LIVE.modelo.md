# Checklist de go-live

Documento vivo: toda mudança que a produção precisa configurar (variável, conta, passo
no servidor, tela a preencher) entra aqui no mesmo PR.

## 1. Infra

- [ ] Servidor/conta de produção criado, separado do pré-produção.
- [ ] Acesso só por chave, usuário sem root, firewall.
- [ ] Domínio, DNS e HTTPS.

## 2. Configuração

- [ ] Variáveis de ambiente (lista e de onde vem cada valor).
- [ ] Contas e credenciais externas de produção (não reaproveitar as de teste).
- [ ] Usuário administrador inicial.
- [ ] Fakes/consoles de dev **desligados** (conferir as travas).

## 3. Deploy

- [ ] Deploy pelo CI configurado (secrets).
- [ ] **Ensaio:** um merge real passou pelo CI e chegou à produção.
- [ ] Migrations aplicadas.
- [ ] Como fazer rollback (passo a passo).

## 4. Dados e backup

- [ ] Backup automático ativo, com cópia fora do servidor e retenção.
- [ ] **Restore testado** num ambiente separado.

## 5. Monitoramento

- [ ] Alertas técnicos (indisponibilidade, falha de job, integração caída) indo só para o
      contato técnico.
- [ ] Tela/endpoint de saúde.
- [ ] **Métricas de saúde do negócio** (3 ou 4): o sistema está funcionando para o
      usuário, não só "no ar". Ex.: taxa de erro por fluxo, tempo até a etapa principal,
      itens parados.

## 6. Validação final

- [ ] Teste ponta a ponta em produção com dados de teste, depois limpos.
- [ ] Acompanhamento das primeiras horas/dias (logs, alertas, métricas).
