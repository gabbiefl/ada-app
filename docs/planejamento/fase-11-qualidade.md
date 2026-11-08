# Fase 11 — Qualidade, privacidade e acessibilidade (versão enxuta)

> **Status:** 📝 em planejamento (aguardando aprovação)
> **Itens do backlog:** F11-02, F11-03, F11-04, F11-05 (e F9-06). O F11-01 já está atendido (ver seção 4).

## 1. Objetivo
Deixar o app confiável para a mostra: a usuária consegue **apagar todos os seus dados**, o que o app guarda e faz com eles está **revisado e documentado**, e as telas passam numa **auditoria de acessibilidade** (alvos de toque, nomes para o leitor de tela, contraste e texto grande).

## 2. Resultado esperado
- Em **Configurações** existe **"Apagar meus dados"**. Com confirmação, apaga contatos, faixas de horário e mensagens editadas (as mensagens voltam ao texto padrão), desfaz qualquer alerta em andamento e volta o app ao estado de recém-instalado.
- Um documento **[docs/privacidade-e-dados.md](../privacidade-e-dados.md)** explica, em linguagem simples: o que o app guarda, onde, o que **nunca** guarda (localização), quais permissões pede e para quê, como apagar tudo e os limites (WhatsApp e SMS ficam no histórico do celular).
- O backup automático do Android **não leva** os dados do ADA para a nuvem.
- O texto do cadastro de contato deixa de prometer um aviso por WhatsApp que não existe (F9-06).
- A barra inferior e os ícones têm **nome para o leitor de tela**; toques pequenos ganham área mínima de 48; os ícones claros demais ganham contraste.
- Testes automáticos de acessibilidade nas telas principais, incluindo **texto em tamanho duplo sem estourar a tela**.

## 3. Conceitos que vamos aprender
- Privacidade por padrão: guardar pouco, proteger o que guarda e permitir apagar (LGPD)
- Backup do Android (`allowBackup`) e por que ele importa para dados sensíveis
- Acessibilidade no Flutter: `Semantics`, `tooltip`, alvo de toque de 48 dp e contraste
- **Guidelines de acessibilidade nos testes** (`meetsGuideline`, `androidTapTargetGuideline`, `labeledTapTargetGuideline`, `textContrastGuideline`)
- Texto ampliado (`TextScaler`) e como detectar tela que estoura (`overflow`)
- Limpar estado em memória **e** armazenamento de forma consistente

## 4. Escopo
**Dentro:**
- "Apagar meus dados" (F11-05, RF10): `clear` nos três controladores, tela de confirmação e testes
- Revisão de privacidade (F11-04) e o documento `privacidade-e-dados.md`
- Desligar o backup automático do Android
- Corrigir o texto do cadastro de contato (F9-06)
- Auditoria de acessibilidade (F11-02) com testes automáticos e as correções que ela achar
- F11-03 (erros e estados vazios): já existem rede vazia, sem contatos, sem localização, sem permissão, alerta sem contatos e cobertura sem faixas. Aqui só se confere e se anota o que faltar

**F11-01 (testes dos fluxos principais):** já atendido. Há mais de 430 testes (unitários, de widget e de fluxo no app inteiro). Nesta fase só entram os testes novos das próprias correções.

**Fora (vai para o backlog):**
- **Avisar na tela quando uma gravação falha** (hoje o app continua com os dados em memória e a falha passa em silêncio; é rara)
- Implementar de verdade o aviso por WhatsApp ao contato cadastrado
- Auditoria com leitor de tela real (TalkBack) e teste com pessoas
- Modo escuro, idiomas além do português
- Revisão jurídica formal de LGPD (a fase é uma revisão técnica)

## 5. Pré-requisitos
- Fases 5 a 10 concluídas (todos os dados que o app guarda já existem)
- Nenhum pacote novo

## 6. Passos
| # | Passo | Tamanho | O que a usuária aprende |
|---|---|---|---|
| 1 | **Apagar meus dados**: `clear` em contatos, mensagens e faixas, desfazer alerta e modo, item em Configurações com confirmação, testes | M | Limpar estado e armazenamento juntos |
| 2 | **Revisão de privacidade**: backup desligado, texto do cadastro (F9-06), checklist e `docs/privacidade-e-dados.md` | P | Privacidade por padrão, LGPD prática |
| 3 | **Auditoria de acessibilidade automática**: testes com as guidelines do Flutter e texto em 2x nas telas principais; lista dos achados | M | Guidelines nos testes, `TextScaler` |
| 4 | **Correções**: nomes na barra inferior e nas setas, áreas de toque pequenas, contraste dos ícones claros | M | `Semantics`, 48 dp, contraste |
| 5 | Fechamento: `flutter analyze`, testes, retrospectiva, resumos e backlog | P | Fechar a fase |

A ordem coloca **apagar dados e privacidade primeiro**: são requisitos (RF10) e ficam melhor para defender na banca. A acessibilidade vem depois, e o passo 4 é o que se corta se o prazo apertar.

## 7. Decisões técnicas
| Decisão | Alternativas consideradas | Motivo |
|---|---|---|
| "Apagar meus dados" limpa **os controladores** (que gravam o vazio no armazenamento) | Só chamar `deleteAll()` do armazenamento seguro | Se só o armazenamento fosse apagado, a tela continuaria mostrando os dados até fechar o app. Limpando pelos controladores, memória e armazenamento ficam iguais |
| Apaga contatos, faixas e mensagens editadas; **desfaz alerta e modo** | Apagar também o Modo de demonstração | O Modo de demonstração não é gravado. Um alerta em andamento seria enviado a contatos que acabaram de ser apagados, então é desfeito |
| Confirmação com **diálogo claro** ("Isso não pode ser desfeito") | Exigir digitar "APAGAR" | O diálogo já protege contra o toque acidental sem atrapalhar a demonstração. Digitar fica no backlog se a banca pedir mais rigor |
| **Desligar o backup automático** (`android:allowBackup="false"`) | Deixar como está; excluir só o arquivo do armazenamento | Dados de contatos e de localização não devem ir para a nuvem do Google sem a usuária saber. Os dados do ADA moram só no aparelho |
| O texto do cadastro de contato passa a dizer o que **de fato** acontece (SMS e ligação em caso de alerta) | Implementar o aviso por WhatsApp | Implementar é maior que o prazo. Corrigir o texto elimina a promessa falsa agora |
| Auditoria com **as guidelines do próprio Flutter** nos testes | Revisão só visual; ferramentas externas | Roda junto dos testes, avisa se alguém piorar a acessibilidade no futuro e não precisa de pacote novo |
| Ícones claros demais ficam **mais escuros, sem mudar o desenho** | Manter o cinza do Figma | O cinza `#D9D9D9` sobre branco tem contraste muito baixo (cerca de 1,4 para 1). O ajuste é só de tom |
| Nomes de leitor de tela com `Semantics` e `tooltip` | Rótulos em texto visível | A barra inferior é só de ícones por design; o nome só precisa existir para quem usa leitor de tela |
| Falha de gravação silenciosa **fica de fora** | Avisar a usuária | É rara (o armazenamento seguro do aparelho quase nunca falha) e pede uma interface nova. Vai para o backlog |

## 8. Riscos e plano B
| Risco | Impacto | Plano B |
|---|---|---|
| Prazo da mostra (12/11/2026): ainda falta a Fase 12 (APK e roteiro), obrigatória | Atrasar a entrega | A fase deve levar cerca de 1 dia. Se apertar: entregar os passos 1, 2 e 5 (apagar dados, privacidade e fechamento) e deixar a acessibilidade para depois |
| Apagar dados deixar a tela em estado estranho | Telas mostrando dados antigos | Os controladores avisam as telas ao limpar, e os testes conferem Rede, Mensagens, Cobertura e Home |
| Apagar durante um alerta em andamento | Mensagens indo para contatos apagados | O alerta é desfeito primeiro (o cancelamento já existe) |
| Desligar o backup ter efeito colateral | Nenhum esperado: o app não depende de backup | Só se aplica a quem reinstala ou troca de celular: os dados não voltam, e isso é o desejado |
| O teste de contraste automático dar falso alarme | Tempo perdido | Avaliar cada achado; o que for decoração fica registrado como aceito, com o motivo |
| Texto em 2x estourar telas com layout fixo | Telas quebradas para quem usa fonte grande | Corrigir com rolagem e `Flexible`/`Wrap`; se for muito, registrar as telas no backlog |
| Mexer em cores quebrar o visual do Figma | Design alterado | Mudar só o tom dos ícones claros, e a usuária confere no emulador |

## 9. Critérios de pronto
- [ ] "Apagar meus dados" apaga contatos, faixas e mensagens editadas, desfaz o alerta e o modo, e as telas refletem isso
- [ ] Depois de apagar e reabrir o app, nada volta (armazenamento vazio)
- [ ] O app tem o backup automático desligado
- [ ] O texto do cadastro de contato não promete mais o aviso por WhatsApp
- [ ] `docs/privacidade-e-dados.md` existe e está de acordo com o que o app faz
- [ ] Nenhum telefone, texto ou coordenada em `print`/`debugPrint`
- [ ] Testes de acessibilidade (alvo de toque, nome e contraste) passando nas telas principais
- [ ] As telas principais aguentam texto em 2x sem estourar
- [ ] A barra inferior e as setas têm nome para o leitor de tela
- [ ] `flutter analyze` sem avisos e testes passando
- [ ] Testado no emulador
- [ ] Backlog atualizado e commit feito

## 10. Como testar
`flutter run -d emulator-5554`: cadastrar contatos, uma faixa de horário e editar uma mensagem → Configurações → **Apagar meus dados** → conferir que Rede, Cobertura e Mensagens ficaram vazias/padrão → fechar e reabrir o app. Em Configurações do Android, ligar o **texto grande** e percorrer as telas. `flutter analyze` e `flutter test`.

## 11. Perguntas em aberto
1. **O que "Apagar meus dados" apaga:** contatos, faixas de horário e mensagens editadas (as mensagens voltam ao padrão), e desfaz o alerta e o modo. É isso (assumido)?
2. **Confirmação:** um diálogo claro (assumido), ou você quer que a usuária digite "APAGAR"?
3. **Backup do Android:** desligar (assumido). Pode ser?
4. **Texto do cadastro (F9-06):** corrigir para o que de fato acontece (assumido), por exemplo: "Combine com essa pessoa antes: em caso de alerta, ela receberá SMS e ligações do ADA." Ou prefere outro texto?
5. **Contraste:** escurecer só o tom do cinza dos ícones (setas, "+", chevrons), sem mexer no desenho (assumido). Pode ser?
6. **Falha ao gravar:** fica fora, no backlog (assumido). Pode ser?

---

## Retrospectiva (preencher ao concluir)

**O que aprendi:**
- <...>

**O que mudou em relação ao plano:**
- <...>

**Dívidas técnicas e novos itens para o backlog:**
- <...>
