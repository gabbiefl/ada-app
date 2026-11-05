# BACKLOG — ADA (Alerta, Defesa e Apoio)

> Lista viva do que precisa ser feito. Atualizada ao fim de cada etapa.
> Os planos detalhados de cada fase ficam em `docs/planejamento/`.

## Legenda

**Status:** ⬜ a fazer · 🔄 em andamento · ✅ concluído · ⏸️ bloqueado · ❌ descartado
**Prioridade:** M = Must (essencial para a mostra) · S = Should (importante) · C = Could (se der tempo) · W = Won't por ora
**Viabilidade:** `[?]` a validar · `[ok]` validada · `[plano B]` viável só com alternativa

---

## Fase atual

**Fase 7 — Modos** concluída no código (falta testar no Chrome, sentir a vibração no Android e escrever os resumos). As Fases 4 a 6 estão concluídas. A Fase 3 segue com telas pendentes (ver F3-07 a F3-14). Falta você escrever o "O que aprendi" das Fases 1 a 7. O passo 9 da Fase 1 (Android) segue adiado para antes da Fase 8.

---

> Próxima: **Fase 8 — Localização** (criar o plano antes; exige o ambiente Android, F1-04 e F1-05, e decidir F3-11, a aba Mapa; cada pacote novo pede a sua confirmação).

## Fase 0 — Entendimento e viabilidade

| ID | Item | Prio | Status |
|---|---|---|---|
| F0-01 | Validar envio de mensagens pelo WhatsApp (abrir com mensagem pronta x envio automático) `[plano B]` (automático inviável; `wa.me` com toque da usuária) | M | ✅ |
| F0-02 | Validar localização em tempo real em segundo plano no Android `[?]` (em aberto: abordagem definida após spike na Fase 8) | M | 🔄 |
| F0-03 | Validar acionamento rápido com o celular bloqueado `[plano B]` (exige código nativo; fora do MVP, ver IDEIA-01) | S | ✅ |
| F0-04 | Validar chamada telefônica rápida (`tel:`) `[ok]` (`tel:` abre o discador; ligação direta a testar na Fase 9) | M | ✅ |
| F0-05 | Levantar requisitos de privacidade e LGPD (contatos e localização) (ver seção 9.2 do plano) | S | ✅ |
| F0-06 | Definir o escopo do MVP da mostra e os planos B (Nível 1 garantido, Nível 2 meta; ver seções 6 e 7 do plano) | M | ✅ |
| F0-07 | Definir a stack tecnológica (base do Nível 1 aprovada; ver seção 9.1 do plano da Fase 0) | M | ✅ |

## Fase 1 — Fundamentos e estrutura

| ID | Item | Prio | Status |
|---|---|---|---|
| F1-01 | Organizar pastas conforme o CLAUDE.md | M | ✅ |
| F1-02 | Limpar o código de exemplo do `flutter create` | M | ✅ |
| F1-03 | Configurar Git e `.gitignore`, primeiro commit (conferido na Fase 1) | M | ✅ |
| F1-04 | Criar e configurar o emulador Android (AVD). Adiado: desenvolvimento no Chrome por enquanto; fazer antes da Fase 7 | M | ⏸️ |
| F1-05 | Definir o nome do app e o `applicationId` (hoje `com.example.ada_app`; escolhido `br.academico.cesuca.ada`, aplicar junto com o Android) | S | ⏸️ |

## Fase 2 — Tema e design system

| ID | Item | Prio | Status |
|---|---|---|---|
| F2-01 | Conectar o MCP do Figma e autenticar | M | ✅ |
| F2-02 | Extrair cores, tipografia e espaçamentos (Home e Modo perigo ativo lidas; estilos de botão e campo ficam para a Fase 3) | M | ✅ |
| F2-03 | Criar `app_theme.dart` (ThemeData, ColorScheme, TextTheme) | M | ✅ |
| F2-04 | Definir as cores dos modos 🔵🟡🔴 no tema | M | ✅ |

## Fase 3 — Telas estáticas

> Lista exata de telas a confirmar com o Figma.

| ID | Item | Prio | Status |
|---|---|---|---|
| F3-01 | Tela inicial (home) com o estado do modo atual | M | ✅ |
| F3-02 | Tela/controle de seleção de modo (Normal, Atenção, Perigo): cobertos pelos cards da Home | M | ✅ |
| F3-03 | Tela de rede de contatos de confiança | M | ✅ |
| F3-04 | Tela de cadastro/edição de contato | M | ✅ |
| F3-05 | Tela de mensagens pré-definidas (e edição da mensagem) | S | ✅ |
| F3-06 | Tela de configurações (menu) | S | ✅ |
| F3-07 | Tela de horário de cobertura (ler no Figma antes) | M | ⬜ |
| F3-08 | Tela de histórico de alertas (ler no Figma antes) | S | ⬜ |

### Telas que ainda faltam (a Fase 3 foi fechada sem elas)
| ID | Item | Prio | Status |
|---|---|---|---|
| F3-14 | Ler as variações dos estados Atenção e Perigo ativos no Figma e ligar os toques dos cards da Home. Toques ligados na Fase 7 (Atenção derivada da tela de Perigo); falta **conferir o visual com o Figma** | M | 🔄 |
| F3-09 | Splash e 3 telas de onboarding (já existem no Figma; ler antes) | M | ⬜ |
| F3-10 | Tela de permissões (localização, notificações; já existe no Figma) | M | ⬜ |
| F3-11 | Tela de mapa/localização (aba "Mapa"). Acompanhamento em tempo real é incerto (F0-02, F8-04): ideia da usuária de usar **checkpoints** da posição. Ler o Figma e decidir o conteúdo antes da Fase 8 | M | ⬜ |
| F3-12 | Rede cheia (5/5): estado sem espaços vazios e aviso de limite (derivar do design existente) | M | ✅ |
| F3-13 | Login/cadastro da usuária: **não foi desenhado no Figma**. Decidir antes se o MVP precisa de conta (o app guarda tudo no aparelho) | S | ⬜ |

## Fase 4 — Navegação e estado

| ID | Item | Prio | Status |
|---|---|---|---|
| F4-01 | Configurar rotas (`go_router`) e barra inferior | M | ✅ |
| F4-02 | Estado global do modo atual (`ModeController` com `provider`; toques nos cards dependem de F3-14) | M | ✅ |

## Fase 5 — Rede de contatos

| ID | Item | Prio | Status |
|---|---|---|---|
| F5-01 | Model de contato | M | ✅ |
| F5-02 | Cadastrar, editar e remover contatos | M | ✅ |
| F5-03 | Limite de 5 contatos | M | ✅ |
| F5-04 | Validação de nome e telefone | M | ✅ |
| F5-05 | Persistência local dos contatos | M | ✅ |

## Fase 6 — Mensagens e configurações

| ID | Item | Prio | Status |
|---|---|---|---|
| F6-01 | Mensagem de emergência pré-configurada | M | ✅ |
| F6-02 | Edição das mensagens pela usuária | S | ✅ |
| F6-03 | Persistência das preferências | S | ✅ |

## Fase 7 — Modos Atenção e Perigo

| ID | Item | Prio | Status |
|---|---|---|---|
| F7-01 | Lógica de transição entre os modos | M | ✅ |
| F7-02 | Ação rápida de ativação do Modo Perigo (meta: até 2 toques; limite aceitável: 3, ver RNF01) | M | ✅ |
| F7-03 | Desativação segura (evitar acionamento acidental) | S | ✅ |
| F7-04 | Feedback visual e háptico | C | ✅ |

## Fase 8 — Localização

| ID | Item | Prio | Status |
|---|---|---|---|
| F8-01 | Solicitar e tratar permissões de localização | M | ⬜ |
| F8-02 | Obter a localização atual | M | ⬜ |
| F8-03 | Compartilhar a localização na mensagem (link de mapa) | M | ⬜ |
| F8-04 | Link de acompanhamento ao vivo (Firebase + página web), Nível 2 do MVP, depois da Fase 9 `[plano B]` | S | ⬜ |

## Fase 9 — Comunicação

| ID | Item | Prio | Status |
|---|---|---|---|
| F9-01 | Chamada telefônica rápida | M | ⬜ |
| F9-02 | Envio da mensagem ao WhatsApp `[?]` | M | ⬜ |
| F9-03 | Acionar a rede de contatos de forma simultânea ou sequencial `[?]` | M | ⬜ |
| F9-04 | Alternativa por SMS via `sms:` (`url_launcher`), sem SMS direto; testar vários destinatários `[?]` | S | ⬜ |

## Fase 10 — Regras por horário

| ID | Item | Prio | Status |
|---|---|---|---|
| F10-01 | Configurar quem ligar por faixa de horário (promovido ao MVP: lógica simples em Dart) | M | ⬜ |
| F10-02 | Lógica de seleção do contato conforme o horário | M | ⬜ |
| F10-03 | Testes unitários da regra | M | ⬜ |

## Fase 11 — Qualidade, privacidade e acessibilidade

| ID | Item | Prio | Status |
|---|---|---|---|
| F11-01 | Testes unitários e de widget dos fluxos principais | S | ⬜ |
| F11-02 | Acessibilidade (contraste, alvos de toque, Semantics) | S | ⬜ |
| F11-03 | Tratamento de erros e estados vazios | S | ⬜ |
| F11-04 | Revisão de privacidade e armazenamento dos dados | S | ⬜ |

## Fase 12 — Build e apresentação

| ID | Item | Prio | Status |
|---|---|---|---|
| F12-01 | Gerar o APK de release | M | ⬜ |
| F12-02 | README do projeto (versão inicial criada na Fase 0; finalizar com instruções de execução e capturas de tela) | S | 🔄 |
| F12-03 | Roteiro de demonstração para a mostra | M | ⬜ |

---

## Ideias futuras (fora do escopo atual)

| ID | Ideia | Prio | Status |
|---|---|---|---|
| IDEIA-01 | Acionamento por atalho físico (ex.: botão de volume) e com celular bloqueado (notificação, widget, tile) | W | ⬜ |
| IDEIA-02 | Modo discreto (disfarce do app) | W | ⬜ |
| IDEIA-03 | Gravação de áudio durante o Modo Perigo | W | ⬜ |
| IDEIA-04 | Backend do acompanhamento ao vivo (promovido, ver F8-04). Envio automático de WhatsApp segue inviável | S | ⬜ |
| IDEIA-05 | Tela de apoio com telefones úteis | C | ⬜ |
| IDEIA-06 | Suporte a iOS | W | ⬜ |
| IDEIA-07 | Modo escuro (o design atual só tem tema claro) | W | ⬜ |
| IDEIA-08 | "Escolher da agenda" no cadastro de contato (pacote de contatos + permissão; escolher um a um, sem ler a agenda inteira) | C | ⬜ |

## Riscos e dúvidas em aberto

- Envio automático de mensagens pelo WhatsApp pode não ser viável sem backend (ver F0-01).
- Localização em segundo plano depende de permissões especiais e tem impacto em bateria (ver F0-02).
- Dados de contatos e localização são sensíveis e precisam de cuidado com privacidade (ver F0-05).
