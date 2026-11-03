# Fase 0 — Entendimento e viabilidade

> **Status:** 🔄 em execução (plano aprovado)
> **Itens do backlog:** F0-01 a F0-06

## 1. Objetivo
Entender tecnicamente cada funcionalidade do ADA, classificá-la (viável, viável com limitações, inviável) e fechar o escopo do MVP da mostra com planos B.

## 2. Resultado esperado
Um documento (este) com a classificação de cada funcionalidade, o MVP em dois níveis, as decisões já tomadas e os riscos. Nenhum código é escrito nesta fase.

## 3. Conceitos que vamos aprender
- Requisitos funcionais x não funcionais
- MVP (produto mínimo viável) e priorização MoSCoW (M/S/C/W)
- Spike técnico (teste rápido de viabilidade)
- Intent do Android, permissões em tempo de execução e foreground service
- Backend como peça de arquitetura (cliente x servidor)

## 4. Escopo
**Dentro:**
- Análise de viabilidade de WhatsApp, SMS, chamada, localização, acionamento com tela bloqueada e acompanhamento ao vivo
- Levantamento de requisitos de privacidade e LGPD
- Definição do MVP e dos planos B

**Fora (vai para o backlog):**
- Qualquer implementação ou spike com código (acontecem nas fases de cada funcionalidade)
- Acionamento com o celular bloqueado (IDEIA-01, fora do MVP por decisão da usuária)
- Envio automático de WhatsApp (inviável sem API Business e backend)

## 5. Pré-requisitos
- CLAUDE.md e BACKLOG.md lidos
- Decisões da usuária: mostra em emulador primeiro, com celular real possível; APK instalado manualmente (sem Play Store)

## 6. Classificação das funcionalidades

| # | Funcionalidade | Classificação | Plano B / observação |
|---|---|---|---|
| 1 | Limite de 5 contatos, mensagens pré-definidas, modos Normal/Atenção/Perigo | ✅ Viável | Lógica local |
| 2 | Regras por horário | ✅ Viável | Dart puro, testável |
| 3 | Chamada rápida | ✅ Viável | `tel:` abre o discador (1 toque extra); `CALL_PHONE` permite ligar direto |
| 4 | Localização atual como link de mapa | ✅ Viável | Permissão de localização + link `maps.google.com/?q=lat,lng`. **🔓 Em aberto:** a abordagem de compartilhamento (instantâneo x ao vivo) será definida após teste na Fase 8 (ver item 8) |
| 5 | Mensagem por SMS | ⚠️ Com limitações | **Decisão:** usar `sms:` (`url_launcher`), que abre o compositor e a usuária toca em enviar. SMS direto (`SEND_SMS`) fica fora por ser restrito pela Play Store. Funciona sem internet |
| 6 | WhatsApp | ⚠️ Com limitações | `wa.me` abre a conversa com texto pronto; a usuária toca em enviar; um contato por vez |
| 7 | Acionar a rede "simultaneamente" | ⚠️ Com limitações | Sem SMS direto, o acionamento é sequencial (SMS e WhatsApp). Spike na Fase 9: testar `sms:` com vários destinatários numa mensagem só |
| 8 | Acompanhamento ao vivo por link (estilo Uber) | ⚠️ Com limitações, **🔓 em aberto** | Exige backend (Firebase), internet e foreground service; plano B: link estático (item 4). A abordagem final será decidida após spike na Fase 8, conforme custo, prazo e estabilidade |
| 9 | Acionamento com celular bloqueado | ⚠️ Com limitações | Fora do MVP; ideia futura: notificação com botão, widget ou Quick Settings tile (código nativo) |
| 10 | Envio automático de WhatsApp sem toque | ❌ Inviável | Só via API Business + backend, ou gambiarra de acessibilidade que viola os termos |
| 11 | Privacidade e LGPD | ✅ Viável, obrigatório | Dados locais, consentimento, ID de sessão aleatório e encerrável |

## 7. Escopo do MVP da mostra

**Nível 1 — MVP garantido (sem backend):**
- Cadastro de até 5 contatos com validação
- Mensagens pré-definidas editáveis
- Modos Normal, Atenção e Perigo
- Localização atual enviada como link de mapa
- Chamada rápida
- WhatsApp com mensagem pronta e SMS como alternativa
- Regra de contato por horário

**Nível 2 — Meta ambiciosa (depois da Fase 9):**
- Link de acompanhamento ao vivo com Firebase + página web de mapa
- Só começa se o Nível 1 estiver estável

**Fora:** acionamento com tela bloqueada, envio automático de WhatsApp, iOS.

## 8. Passos
| # | Passo | Tamanho | O que a usuária aprende |
|---|---|---|---|
| 1 | Revisar a classificação da seção 6 e fechar F0-01 a F0-04 | P | Diferença entre viável, com limitações e inviável |
| 2 | Levantar requisitos de privacidade e LGPD (F0-05) | M | Dados pessoais, consentimento, minimização |
| 3 | Escrever requisitos funcionais e não funcionais | M | Como separar "o que faz" de "como deve se comportar" |
| 4 | Fechar o MVP em dois níveis e atualizar o backlog (F0-06) | P | Priorização e controle de escopo |
| 5 | Retrospectiva e commit | P | Fechar uma fase com registro |

## 9. Decisões técnicas
| Decisão | Alternativas consideradas | Motivo |
|---|---|---|
| Plataforma de demonstração: emulador primeiro, celular real depois | Só celular real | Mais rápido para iterar; localização simulável por rota GPX |
| SMS apenas via `sms:` (`url_launcher`), sem SMS direto | SMS direto (`SEND_SMS`) | Evita funcionalidade que a Play Store restringe; o app continua publicável. Custo: a usuária toca em enviar |
| Acompanhamento ao vivo com Firebase (decisão na hora de implementar) | Supabase, backend próprio | Plano gratuito, escuta de mudanças em tempo real, hospedagem da página; comparar na época |
| Acionamento com tela bloqueada fora do MVP | Notificação, widget, tile | Exige código nativo e não é essencial para a mostra |

## 9.1 Stack tecnológica

> Base do Nível 1 **aprovada pela usuária**. Cada pacote é reconfirmado na fase em que entrar.

**Nível 1 (tudo no celular)**
| Necessidade | Escolha | Alternativas | Motivo |
|---|---|---|---|
| Linguagem e UI | Flutter + Dart, Material 3 | | Já definido |
| Navegação | `go_router` | `Navigator`, `auto_route` | Padrão recomendado e já previsto no CLAUDE.md |
| Estado | Provider (`ChangeNotifier`) | Riverpod, Bloc | Menos conceitos novos; suficiente para o tamanho do app |
| Dados locais | `shared_preferences` (preferências e mensagens) + `flutter_secure_storage` (contatos) | `sqflite`, `drift`, `Hive`, `Isar` | Poucos dados; sem necessidade de SQL; contatos de terceiros ficam criptografados (Keystore) |
| Localização | `geolocator` | `location` | Posição atual e stream contínuo com notificação de serviço |
| Permissões | `permission_handler` | Só o `geolocator` | Centraliza localização, telefone, SMS e notificações |
| Ligar, SMS, WhatsApp | `url_launcher` (`tel:`, `sms:`, `wa.me`) | | Padrão para abrir outros apps |
| Ligação direta | A decidir na Fase 9 com spike | `flutter_phone_direct_caller` | Manutenção do pacote muda; conferir na época. SMS direto está descartado |
| Háptico | `HapticFeedback` (nativo do Flutter) | | Sem pacote extra |
| Testes | `flutter_test` (e `mocktail` se necessário) | | |

**Nível 2 (acompanhamento ao vivo)**
| Necessidade | Escolha | Alternativas | Motivo |
|---|---|---|---|
| Banco em tempo real | Firebase (Realtime Database ou Firestore, decidir na época) | Supabase | Plano gratuito e atualização em tempo real |
| Escrita segura | Firebase Auth anônimo + regras de segurança | Sem autenticação | Só quem criou a sessão escreve; o link só lê |
| Página de rastreamento | HTML + JavaScript + Leaflet (OpenStreetMap) no Firebase Hosting | Google Maps API | Sem chave de API nem cartão |
| Deploy | Node.js + Firebase CLI | | Necessário para publicar a página |

**Fora de propósito:** servidor próprio, banco SQL e iOS.

**Ferramentas:** Git/GitHub, VS Code, Android Studio (emulador com rota GPX), Figma MCP (Fase 2) e `flutter analyze` antes de cada commit.

## 9.2 Privacidade e LGPD (F0-05)

> Levantamento educacional para orientar o projeto, não é parecer jurídico. Referência: Lei Geral de Proteção de Dados (Lei 13.709/2018).

**Conceitos**
- **Dado pessoal:** qualquer informação que identifique alguém. Aqui: nome e telefone dos contatos, localização da usuária.
- **Titular:** a pessoa a quem os dados se referem. A usuária é titular dos próprios dados, e cada contato cadastrado é titular do telefone dele.
- **Minimização:** guardar só o que é necessário para a finalidade.
- **Consentimento:** autorização livre, informada e para finalidade específica.

A localização não está na lista legal de "dados sensíveis", mas é dado pessoal de **alto risco**: revela onde a pessoa está, e o público do app é vulnerável. Tratamos com o cuidado de um dado sensível.

**Requisitos de privacidade**
| # | Requisito | Fase |
|---|---|---|
| P1 | Texto de consentimento simples na primeira abertura: quais dados são usados e para quê | 3 e 11 |
| P2 | Pedir cada permissão no momento de uso, com explicação antes do diálogo do Android | 8 e 9 |
| P3 | Guardar só nome e telefone de cada contato; não ler a agenda inteira | 5 |
| P4 | Contatos em armazenamento criptografado (`flutter_secure_storage`); Nível 1 não envia nada a servidor | 5 |
| P5 | Desativar o backup automático do Android (`allowBackup=false`) para os dados não irem para a nuvem | 11 |
| P6 | Não escrever telefones nem coordenadas em logs (`print`/`debugPrint`) | todas |
| P7 | Sem anúncios nem analytics de terceiros | todas |
| P8 | Opção "apagar todos os meus dados" | 6 e 11 |
| P9 | Dados de exemplo e testes sempre fictícios (ex.: `(11) 90000-0000`) | todas |
| P10 | Nível 2: ID de sessão aleatório e longo, regras de segurança do banco, encerrar e apagar a sessão ao desativar o modo, avisar que quem tem o link vê a localização | Nível 2 |

**Riscos específicos do público**
- A mensagem enviada fica no histórico do SMS e do WhatsApp do aparelho, e quem tiver acesso ao celular pode ver. O app não controla isso, mas deve **avisar**.
- Se alguém mexer no celular, vê que o app existe. O "modo discreto" fica como IDEIA-02 (W).

## 9.3 Requisitos

> **Requisito funcional (RF):** o que o app **faz**. **Requisito não funcional (RNF):** **como** ele deve se comportar (rapidez, segurança, acessibilidade...).

**Requisitos funcionais**
| ID | O app deve... | Nível |
|---|---|---|
| RF01 | Cadastrar, editar e remover contatos de confiança (nome e telefone), escolhendo-os um a um | 1 |
| RF02 | Limitar a rede a 5 contatos e validar nome e telefone | 1 |
| RF03 | Oferecer mensagens de emergência pré-definidas, editáveis pela usuária | 1 |
| RF04 | Alternar entre os modos Normal, Atenção e Perigo, mostrando o modo atual com clareza | 1 |
| RF05 | Ativar o Modo Perigo com uma ação rápida e desativá-lo de forma segura (evitando acionamento acidental) | 1 |
| RF06 | Obter a localização atual e incluir o link de mapa na mensagem | 1 |
| RF07 | Ligar rapidamente para um contato | 1 |
| RF08 | Enviar a mensagem por WhatsApp (`wa.me`) e por SMS (`sms:`) a cada contato | 1 |
| RF09 | Escolher quem ligar conforme o horário configurado | 1 |
| RF10 | Apagar todos os dados da usuária | 1 |
| RF11 | Gerar um link de acompanhamento ao vivo e encerrá-lo ao desativar o modo | 2 |

**Requisitos não funcionais**
| ID | Categoria | Requisito |
|---|---|---|
| RNF01 | Usabilidade | Acionar o Modo Perigo a partir da tela inicial em **até 2 toques (meta); 3 ainda é aceitável** (a validar na Fase 7). Um dos toques pode ser a confirmação que evita acionamento acidental |
| RNF02 | Acessibilidade | Alvos de toque de pelo menos 48 dp, contraste de texto adequado (WCAG AA) e rótulos `Semantics` |
| RNF03 | Desempenho | Resposta imediata aos toques; a busca de localização tem tempo limite e alternativa (enviar sem localização, avisando) |
| RNF04 | Confiabilidade | Nenhum fechamento inesperado quando faltar permissão, GPS, internet ou WhatsApp instalado: sempre uma mensagem clara |
| RNF05 | Privacidade | Cumprir P1 a P10 (seção 9.2) |
| RNF06 | Funcionamento sem internet | No Nível 1, ligação e SMS funcionam sem internet; WhatsApp e acompanhamento ao vivo exigem internet |
| RNF07 | Compatibilidade | Android, no emulador e em celular real (versão mínima definida na Fase 1) |
| RNF08 | Manutenibilidade | Estrutura de pastas do CLAUDE.md, tema centralizado e `flutter analyze` sem avisos |

## 10. Riscos e plano B
| Risco | Impacto | Plano B |
|---|---|---|
| Prazo curto (mostra em 12/11/2026) | Nível 2 não ficar pronto | Congelar o Nível 1 até ~02/11; se atrasar, o Nível 2 vira apenas demonstração parcial |
| Internet do local instável | Acompanhamento ao vivo falhar na apresentação | Demonstrar o Nível 1 (link estático) e ter um vídeo gravado do Nível 2 |
| Android encerra serviço em segundo plano (Xiaomi, Samsung) | Rastreamento para de enviar | Testar em aparelho real; orientar desativar otimização de bateria |
| Limites do plano gratuito do Firebase mudarem | Custo inesperado | Conferir os limites antes de implementar; alternativa Supabase |
| Link de rastreamento vazar | Exposição da localização | ID aleatório longo, encerrar sessão ao desativar o modo, apagar dados |
| Aprovação de permissões sensíveis | Fluxo quebrado se negadas | Tratar negação e mostrar explicação clara |

## 11. Critérios de pronto
- [x] Classificação revisada e aprovada pela usuária
- [x] Requisitos funcionais e não funcionais escritos
- [x] Requisitos de privacidade e LGPD levantados
- [x] MVP em dois níveis fechado
- [x] Backlog atualizado
- [ ] Commit feito

## 12. Como testar
Não há código. A validação é a usuária conseguir explicar, para cada funcionalidade, o que é automático, o que exige toque e qual é o plano B.

## 13. Perguntas em aberto
- ✅ Prazo: a mostra é em **12/11/2026** (cerca de 5 semanas a partir de 06/10/2026; antes era 23/11/2026). O Nível 2 só começa se o Nível 1 estiver estável por volta de 02/11, restando ~10 dias.
- ✅ Internet: **haverá internet** no local, então o acompanhamento ao vivo pode ser demonstrado. O link estático continua como plano B.

---

## Retrospectiva (preencher ao concluir)

**O que aprendi:**
- Viabilidade não é "dá ou não dá": é o que o app faz sozinho, o que exige toque da usuária e qual é o plano B.
- Requisito funcional (o que o app faz) x não funcional (como se comporta); MVP em níveis para controlar escopo.
- Escolher o que "pode ir para frente": o SMS direto foi descartado por ser restrito pela Play Store.
- Minimização de dados: guardar só os contatos escolhidos, sem ler a agenda inteira.
- Localização ao vivo exige um serviço intermediário (backend); o app sozinho coleta, mas não entrega a outra pessoa.

**O que mudou em relação ao plano:**
- SMS direto saiu do MVP; ficou só o `sms:`, e o acionamento "simultâneo" virou sequencial.
- O acompanhamento ao vivo (Nível 2) ficou como decisão em aberto até o spike da Fase 8.
- Acrescentadas as seções de stack (9.1), privacidade (9.2) e requisitos (9.3), que não estavam no plano inicial.
- Meta de acionamento do Modo Perigo: até 2 toques (limite 3).

**Dívidas técnicas e novos itens para o backlog:**
- Spike de ligação direta (`CALL_PHONE`) e de `sms:` com vários destinatários, na Fase 9.
- Spike de localização contínua e do Firebase, na Fase 8 e no Nível 2.
- Escolher a licença do repositório.
- Definir a versão mínima do Android (Fase 1).
