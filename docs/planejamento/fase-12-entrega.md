# Fase 12 — APK de release, roteiro da demonstração e entrega final

> **Status:** 🔄 em andamento (passo 1). O **roteiro da demonstração fica por último**, só quando a usuária pedir (08/11)
> **Itens do backlog:** F12-01, F12-02, F12-03 (e fecha dois itens abertos do checklist de [privacidade-e-dados.md](../privacidade-e-dados.md))

## 1. Objetivo
Chegar à mostra de **12/11/2026** com um **APK instalável**, um **roteiro de demonstração ensaiado** (com plano B para o que pode dar errado ao vivo) e um **README final** que qualquer pessoa consegue seguir para rodar o projeto.

## 2. Resultado esperado
- Um arquivo `app-release.apk` gerado por `flutter build apk --release`, instalado e testado **no emulador e, se possível, num celular real**.
- As **permissões do APK de release conferidas** (internet **só para o mapa**, localização, SMS e ligação), e o resultado anotado em `docs/privacidade-e-dados.md`.
- Um **roteiro da demonstração** em `docs/roteiro-da-demonstracao.md`: ordem das telas, o que falar em cada uma, quanto tempo leva, o que preparar antes e o que fazer se algo falhar.
- O **README final**: status atualizado, como rodar no Android (emulador/celular), como gerar o APK, funcionalidades, capturas de tela, limites conhecidos.
- Backlog e documentos de fases fechados.

## 3. Conceitos que vamos aprender
- Modos de build do Flutter: **debug x profile x release** (o que muda em cada um)
- **Assinatura** do APK: por que todo APK precisa de uma assinatura, e a diferença entre a chave de debug e uma chave própria
- **Manifesto mesclado** (merged manifest): como as permissões dos pacotes se somam às do app, e como conferir
- Por que o APK de release pode se comportar diferente do debug (código reduzido pelo R8, sem internet de desenvolvimento)
- Instalar APK direto (`adb install`, "fontes desconhecidas") e por que a **Play Store restringe SMS e ligação**
- Escrever um **roteiro de demonstração** e um plano B

## 4. Escopo
**Dentro:**
- Gerar e testar o APK de release (F12-01)
- Conferir permissões do APK e atualizar o documento de privacidade
- Roteiro da demonstração com plano B (F12-03)
- README final com instruções de Android e capturas de tela (F12-02)
- Nome e versão do app conferidos (`ADA`, `1.0.0`)
- Retrospectiva e resumos de aprendizado das Fases 9, 10 e 11 (se você aprovar)

**Fora (vai para o backlog):**
- Publicar na Play Store (a permissão de SMS é restrita; o APK é instalado direto)
- Chave de assinatura própria e `key.properties`: o APK da mostra pode usar a chave de debug (ver decisões)
- Splash, onboarding e a tela de permissões do Figma (F3-xx)
- iOS, modo escuro, outros idiomas
- Qualquer funcionalidade nova. **Congelamento:** depois do passo 1, só entram correções de erro

## 5. Pré-requisitos
- Fases 1 a 11 concluídas (código completo e 516 testes passando)
- Android Studio, SDK, NDK e CMake instalados (já estão)
- **Emulador ligado por você** (eu não ligo nem desligo)
- Para o teste de verdade: um **celular Android** com cabo, ou o APK enviado a ele. Os números de teste devem ser **seus**: o alerta envia SMS e liga de verdade
- Nenhum pacote novo

## 6. Passos
| # | Passo | Tamanho | O que a usuária aprende |
|---|---|---|---|
| 1 | **Gerar o APK de release** (`flutter build apk --release`), conferir tamanho, nome (`ADA`) e versão | P | Debug x release, onde fica o APK |
| 2 | **Conferir as permissões do APK** (manifesto mesclado, com `INTERNET` só para o mapa) e anotar em `privacidade-e-dados.md` | P | Manifesto mesclado, permissões que pacotes adicionam |
| 3 | **Testar o APK de release**: no emulador (você liga) o roteiro inteiro; no celular real, SMS e ligação (F9-05). Registrar o que aparecer | M | Release se comporta diferente do debug; teste em aparelho real |
| 4 (por último, sob pedido) | **Roteiro da demonstração** (`docs/roteiro-da-demonstracao.md`): sequência, falas, tempo, preparação, plano B | M | Preparar uma apresentação defensável |
| 5 | **README final** com instruções de Android, APK, funcionalidades, limites e capturas de tela (você envia os prints; **sem dados pessoais nem números reais**) | M | Documentação de projeto |
| 6 | **Fechamento**: `flutter analyze`, testes, retrospectiva, backlog, e os resumos de aprendizado das Fases 9, 10 e 11 (se aprovados) | M | Fechar o projeto |

**Ordem de corte se o prazo apertar** (hoje é 08/11; faltam 4 dias): os passos **1 e 2** são o mínimo (APK e permissões); o roteiro (4) só entra quando a usuária pedir. O 3 no celular real é muito desejável. O 5 pode ser enxuto (sem capturas). Os resumos de aprendizado do passo 6 são o que se corta primeiro.

**Sugestão de calendário:** 08/11 passos 1 e 2 · 09/11 passo 3 · 10/11 passo 5 · 11/11 roteiro (passo 4), ensaio e folga · 12/11 mostra.

## 7. Decisões técnicas
| Decisão | Alternativas consideradas | Motivo |
|---|---|---|
| **Assinar com a chave de debug** (o que o projeto já faz) | Criar uma chave própria (keystore) | O APK será instalado direto, não vai para a loja, então a chave de debug serve. Criar uma chave própria exige guardá-la com segurança **fora do repositório (que é público)**, e perder ou vazar a chave é pior que usar a de debug. Fica no backlog para uma publicação futura |
| **Congelar funcionalidades** depois do passo 1 | Continuar melhorando até a véspera | A uma semana da mostra, o maior risco é quebrar o que funciona. Só correção de erro |
| **Testar o APK de release**, não só o debug | Confiar nos 516 testes | Os testes e o debug não exercitam a redução de código (R8) nem o manifesto de produção. O risco é pequeno, mas é barato de conferir |
| **Demonstração com o Modo de demonstração ligado** como padrão | Enviar SMS de verdade na frente da banca | O Modo de demonstração ensaia o alerta **sem enviar nada**, evitando SMS e ligação acidentais e dependência de sinal. O envio real é mostrado só se a usuária quiser, com o número dela |
| **Roteiro com plano B por etapa** | Roteiro só do caminho feliz | Ao vivo, o que falha é o ambiente (emulador, sinal, permissão negada). Cada etapa tem o que fazer se falhar |
| **Capturas de tela sem dados pessoais** | Prints reais do celular | O repositório é público: só nomes e números fictícios |
| O APK **não** é colocado no repositório | Subir o `.apk` no Git | Arquivos binários grandes poluem o histórico. Fica fora do Git (a pasta `build/` já é ignorada); pode ir em "Releases" do GitHub se você quiser, **com a sua decisão** |

## 8. Riscos e plano B
| Risco | Impacto | Plano B |
|---|---|---|
| O build de release **falhar** (R8, memória, Gradle) | Sem APK | Ver o erro; se for o R8, ajustar regras ou desligar a redução; liberar memória (`./gradlew --stop`, fechar navegadores). Se nada resolver, levar o **APK de debug** (funciona do mesmo jeito) |
| O APK de release se **comportar diferente** (erro só em release) | Demonstração quebrada | O passo 3 existe para achar isso cedo; corrigir ou usar o APK de debug |
| **SMS direto não funcionar** no emulador (já visto) ou no celular | O ponto principal da demonstração falha | O Modo de demonstração mostra o fluxo todo sem enviar; o app já tem o plano B de abrir o app de SMS (F9). No celular, olhar o `adb logcat` com o filtro `AdaAlert` para saber o motivo |
| **Sem sinal** de operadora no dia | SMS e ligação não saem | Mostrar no Modo de demonstração e explicar. A localização usa o GPS, que não depende de sinal de operadora |
| O **emulador travar** (memória, já aconteceu) | Perde-se tempo ao vivo | Levar o **celular real** com o app instalado como principal ou reserva, e **prints/vídeo gravado** do fluxo como último recurso |
| **Permissão negada** ao vivo | Alerta sem localização ou sem SMS | O alerta sai mesmo sem localização; a tela mostra o que não foi possível. Conferir as permissões **antes** da mostra |
| O **celular real não ter o cartão SIM com crédito** | Sem SMS/ligação | Ensaiar com o Modo de demonstração; testar o envio real antes, com o seu próprio número |
| **Prazo** (4 dias) | Entrega incompleta | Ordem de corte na seção 6 |
| Dados pessoais nas capturas de tela do README | Exposição num repositório público | Usar só contatos fictícios (ex.: "Maria", número de exemplo) e conferir cada imagem antes do commit |

## 9. Critérios de pronto
- [ ] `flutter build apk --release` gera o APK sem erro
- [ ] O app instalado se chama **ADA**, com o ícone do ADA, versão 1.0.0
- [ ] O manifesto do APK **não** tem `INTERNET`; as permissões são só localização, SMS e ligação (e as dos pacotes, anotadas)
- [ ] O checklist de [privacidade-e-dados.md](../privacidade-e-dados.md) está com o item do APK marcado
- [ ] O roteiro da demonstração existe, foi **ensaiado ao menos uma vez** e tem plano B por etapa
- [ ] O APK de release foi testado no emulador (fluxo completo) e, se possível, no celular real (SMS e ligação, F9-05)
- [ ] O README tem: o que é, como rodar (Chrome, Android), como gerar o APK, funcionalidades, limites e capturas de tela sem dados pessoais
- [ ] `flutter analyze` sem avisos e testes passando
- [ ] Backlog e plano fechados, com retrospectiva
- [ ] Commits feitos por você

## 10. Como testar
`flutter build apk --release` → o arquivo fica em `build/app/outputs/flutter-apk/app-release.apk`. Instalar com `adb install -r build/app/outputs/flutter-apk/app-release.apk` (ou copiar para o celular e abrir). Para ver as permissões: `aapt dump permissions app-release.apk` (nas build-tools do SDK) ou o menu **Build → Analyze APK** do Android Studio. Depois seguir o roteiro da demonstração do começo ao fim, uma vez com o Modo de demonstração e uma vez com envio real para o **seu** número.

## 11. Perguntas em aberto
1. **Chave de assinatura:** usar a de debug no APK da mostra (assumido). Pode ser?
2. **Celular real:** você tem um Android para o teste de SMS e ligação (F9-05) e para levar à mostra? E um chip com crédito e um número seu para receber?
3. **Como a demonstração será feita:** no **emulador** (projetado/na tela do notebook), no **celular** (espelhado), ou nos dois? Isso muda o plano B.
4. **Modo de demonstração como padrão** no roteiro, com o envio real só se sobrar tempo (assumido). Pode ser?
5. **Duração** da apresentação: quantos minutos você tem? (o roteiro será montado para esse tempo; sugiro 5 a 7 minutos)
6. **Capturas de tela do README:** você envia os prints (com contatos fictícios) ou prefere que o README fique só com texto?
7. **Resumos de aprendizado das Fases 9, 10 e 11:** escrevo no passo 6 (assumido) ou fica para depois da mostra?
8. **APK no GitHub:** quer publicá-lo em "Releases" do repositório ou só levar o arquivo?

---

## Retrospectiva

**O que aprendi:**
- (preencha com as suas palavras)

**O que mudou em relação ao plano:**
- (a preencher no fechamento)

**Dívidas técnicas e novos itens para o backlog:**
- (a preencher no fechamento)
