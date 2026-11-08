# Fase 9 — Comunicação: chamada, mensagem e WhatsApp

> **Status:** ✅ concluída no código (pendente: confirmar o SMS direto e a ligação em aparelho real; ver Dívidas)
> **Itens do backlog:** F9-01, F9-02, F9-03, F9-04

## 1. Objetivo
Ao ativar o Modo Perigo, o app **age sozinho**: busca a localização, manda a mensagem por SMS para a rede e liga para o contato de plantão, sem nenhuma confirmação extra além do "Ativar" que já existe.

## 2. Resultado esperado
- Confirmado o **Ativar** do Modo Perigo, sem mais nenhum toque:
  1. o app busca a localização (com tempo limite);
  2. envia o **SMS** com a mensagem e o link de mapa para **os outros contatos**;
  3. **liga** para o contato de plantão (o configurado no horário de cobertura).
- Uma tela **Alerta** mostra o que aconteceu com cada contato (enviado, falhou, ligando) e oferece **reenviar** e **WhatsApp** (este com um toque da usuária, ver seção 7).
- Sem permissão de SMS ou de ligação, sem contatos ou sem localização, o app explica, usa o plano B e **não fecha**.
- O Modo Atenção envia a mensagem de atenção com a localização, **sem ligar** (ver pergunta 3).

## 3. Conceitos que vamos aprender
- Permissões sensíveis do Android (`SEND_SMS`, `CALL_PHONE`) e pedir no momento certo
- Código nativo (Kotlin) chamado pelo Dart: `MethodChannel`
- `url_launcher`, esquemas de URL (`tel:`, `sms:`, `https://wa.me/`) e intents
- `<queries>` no manifesto (visibilidade de apps no Android 11 ou mais)
- Orquestrar vários passos em ordem e anotar o resultado de cada um
- Plano B quando a permissão é negada (abrir o discador ou o app de SMS)
- Interface + versão falsa para testar sem enviar mensagem nem ligar de verdade
- Honestidade sobre limites: o que é automático (SMS e ligação) e o que não é (WhatsApp)

## 4. Escopo
**Dentro:**
- Pacotes `url_launcher` e `permission_handler` (com a sua confirmação)
- Permissões `SEND_SMS` e `CALL_PHONE` e `<queries>` no manifesto
- Código nativo em Kotlin: enviar SMS direto e ligar direto (ver decisões)
- Funções puras que montam as URLs do WhatsApp e do discador, com testes
- `AlertActions` (interface), versão real e versão falsa
- Regra provisória de quem ligar: **o primeiro contato da lista**; a Fase 10 troca pela regra do horário
- `AlertController`: localização → texto → SMS aos outros → ligação, com o resultado de cada um
- Tela **Alerta** (resultado por contato, reenviar, WhatsApp manual)
- Ligar o **Ativar do Perigo** (e a Atenção) a esse fluxo
- Testes unitários, de widget e de fluxo; teste manual no emulador

**Fora (vai para o backlog ou outras fases):**
- **WhatsApp automático** (inviável, Fase 0: só com API Business e servidor)
- A **regra do horário de cobertura** (Fase 10): aqui entra a regra provisória
- Publicação na Play Store com envio de SMS (ver riscos)
- Acompanhamento em tempo real (F8-04) e mapa interativo (F8-05)
- Saber se o SMS foi **entregue** (o app só sabe que foi enviado)
- Histórico de alertas (continua "Em breve")

## 5. Pré-requisitos
- Fases 5 a 8 concluídas (contatos, mensagens, modos e localização)
- Ambiente Android pronto
- **Decisão revista:** a Fase 0 deixou o SMS direto de fora (Play Store). A usuária pediu envio automático, então ele **entra**. O APK da mostra é instalado direto no celular, sem a Play Store.
- Confirmação dos pacotes e do código nativo (seção 11)

## 6. Passos
| # | Passo | Tamanho | O que a usuária aprende |
|---|---|---|---|
| 1 ✅ | Parte em Dart pura: `AlertActions` (interface e versão falsa), funções das URLs (`wa.me`, `tel:`), telefone no formato internacional, `url_launcher`; testes | M | Esquemas de URL, codificação de texto |
| 2 ✅ | Parte nativa: `MethodChannel` em Kotlin que envia SMS direto (mensagem longa em partes) e liga direto; permissões no manifesto e `permission_handler`; plano B (compositor de SMS e discador) | G | Código nativo, permissões sensíveis, intents |
| 3 ✅ | `AlertController`: busca a localização, monta o texto, **envia o SMS aos outros contatos e só depois liga** (a ligação toma a tela), guardando o resultado de cada um | G | Orquestrar passos em ordem |
| 4 ✅ | Tela **Alerta**: resultado por contato, reenviar, WhatsApp manual, rede vazia, avisos | M | Tela de vários estados |
| 5 ✅ | Ligar o **Ativar do Perigo** (e a Atenção, sem ligar) ao fluxo; botão para reabrir a tela | P | Disparar o fluxo a partir de uma ação |
| 6 ✅ | Testes de fluxo, teste no emulador, `flutter analyze`, retrospectiva, resumos e backlog | M | Fechar a fase |

## 7. Decisões técnicas
| Decisão | Alternativas consideradas | Motivo |
|---|---|---|
| **SMS direto** (`SEND_SMS` + `SmsManager`) | `sms:` (abre o app e exige o toque) | A usuária quer envio automático. Funciona sem internet. Custo: usa o plano de SMS do chip, e a Play Store restringe essa permissão (por isso o APK é instalado direto). O `sms:` fica como **plano B** se a permissão for negada |
| **Ligação direta** (`CALL_PHONE` + `ACTION_CALL`), com o **discador como plano B** | Só `tel:` | Pedido da usuária. Se a permissão for negada ou a ligação falhar, abre o discador com o número (um toque a mais) |
| **Código nativo em Kotlin** (um `MethodChannel` pequeno) | Pacotes de terceiros para SMS direto | Pacotes de SMS direto costumam estar sem manutenção. Poucas linhas, sem dependência frágil. Só dá para testar de verdade no emulador ou no celular |
| `permission_handler` para pedir `SEND_SMS` e `CALL_PHONE` | Pedir pelo Kotlin | Já previsto na Fase 0; trata "negada para sempre" e abre as configurações |
| **Ordem: SMS primeiro, ligação depois** | Ligar primeiro | A ligação abre o discador e toma a tela; o SMS direto é silencioso e rápido |
| **WhatsApp continua manual** (`wa.me`, um toque da usuária) | Automatizar | Inviável sem API Business e servidor (Fase 0). Fica na tela Alerta como reforço |
| Quem recebe SMS: **todos os contatos, menos o que será ligado** (conforme a usuária) | Todos, inclusive o ligado | Foi o pedido. Pode mudar para "todos" com uma linha (pergunta 4) |
| Quem ligar, por ora: **o primeiro da lista** | Escolher na hora | A regra de verdade vem do horário de cobertura (Fase 10). A parte de "quem ligar" fica atrás de uma interface para trocar sem mexer no resto |
| Mensagem longa vira SMS em partes (`divideMessage`) | Cortar o texto | O texto + link passa de 160 letras; sem isso o SMS falharia |
| `AlertActions` atrás de interface, com versão falsa | Chamar Kotlin direto nos testes | Os testes **nunca** enviam SMS nem ligam de verdade |
| **Uma vez por ativação:** o envio automático não se repete sozinho | Reenviar em laço | Evita enviar várias vezes e gastar o plano. Reenviar é um toque na tela Alerta |
| Nada de telefone, texto ou coordenada em `print`/`debugPrint` | Logs para depurar | Privacidade (P6) |
| **Tela de progresso como no print do Figma** (recebido em 06/11): fundo na cor do modo, símbolo menor com anéis, título, cartões escuros por etapa (localização, mensagens, ligação) e botão branco **Cancelar alerta** fixo embaixo. Atenção usa fundo amarelo com texto azul-marinho (contraste) | Manter a primeira versão (fundo claro) | Fidelidade ao design. O frame foi visto só pelo print, sem chamada ao Figma |
| **Quem foi avisado e quem falhou, em grupos** ("Avisados" e "Não foi possível avisar"), com *tentar de novo* e WhatsApp manual | Só os cartões de progresso | Pedido da usuária; o Figma não tem esse detalhe |
| Atenção também pede confirmação antes de enviar | Ativar com um toque | Com envio automático, um toque acidental avisaria toda a rede |
| Modo de demonstração em Configurações, desligado ao abrir o app | Gravar a escolha | Um esquecimento nunca deixa um alerta de verdade "de mentirinha" |

## 8. Riscos e plano B
| Risco | Impacto | Plano B |
|---|---|---|
| **Teste enviando SMS de verdade** para contatos reais | Mensagem de emergência chegando a pessoas por engano | Durante o desenvolvimento, cadastrar **só o seu próprio número** (ou o de outro emulador). Considerar uma chave "modo de demonstração" que não envia nada (pergunta 6) |
| **Toque acidental envia SMS à rede** | Pessoas alarmadas à toa | O Perigo tem a confirmação "Ativar". A Atenção hoje **não** tem; com envio automático isso pesa (pergunta 3) |
| Prazo da mostra (12/11/2026): esta fase ficou maior | Faltam as Fases 10 a 12; a 12 (APK e roteiro) é obrigatória | Meta de 2 a 3 dias. Cortes possíveis: Fase 10 só com "contato de ligação" escolhido por você, Fase 11 enxuta. Se apertar nesta fase: entregar SMS automático e ligação, deixar a tela Alerta mais simples |
| Android pede permissão a cada tipo de ação | Fluxo parado no meio do alerta | Pedir `SEND_SMS` e `CALL_PHONE` **antes**, com explicação (por exemplo, ao cadastrar o primeiro contato ou na primeira ativação). Se negadas: plano B (compositor e discador) |
| Limite de SMS do Android (muitos envios seguidos) | O sistema pode pedir confirmação | Máximo de 5 contatos, uma vez por ativação |
| O emulador não envia SMS de verdade | Não dá para ver a entrega | Testar entre dois emuladores (número 5554 e 5556) ou num celular real; os testes automáticos usam a versão falsa |
| Play Store restringe `SEND_SMS` | O app não pode ser publicado assim | Fora do escopo da mostra (APK direto). Registrar como limite conhecido no README e na apresentação |
| A ligação direta falha em alguns aparelhos | Sem ligação | Plano B: discador com o número |
| Figma da tela Alerta não lido | Visual diferente | Montar com o tema existente e conferir depois |

## 9. Critérios de pronto
- [x] Confirmado o Perigo, sem outro toque: localização, SMS aos outros contatos e ligação ao contato de plantão
- [x] Sem permissão de SMS ou de ligação, o plano B abre o compositor ou o discador (coberto por testes)
- [x] Sem localização, sem contatos ou com falha, o app explica e não fecha
- [x] A tela Alerta mostra o resultado por contato e permite reenviar e abrir o WhatsApp
- [x] O envio automático acontece uma vez por ativação
- [x] Nenhum telefone, texto ou coordenada em `print`/`debugPrint`
- [x] Testes passando com a versão falsa (nenhum teste envia ou liga de verdade)
- [x] `flutter analyze` sem avisos
- [x] Testado no emulador: fluxo completo, tela de progresso e ligação
- [ ] **SMS direto confirmado** no emulador ou num celular real (no emulador apareceu a falha genérica "Não foi possível enviar o SMS"; a causa ainda não foi descoberta)
- [x] Backlog atualizado
- [ ] Commit do fechamento (por você)

## 10. Como testar
Cadastrar **apenas números de teste**. `flutter run -d emulator-5554`, conceder as permissões e ativar o Perigo. Conferir o SMS no outro emulador (porta 5556) ou no seu celular, e a ligação. Repetir negando as permissões (plano B), sem localização e sem contatos. `flutter analyze` e `flutter test`.

## 11. Perguntas em aberto
1. **Pacotes e código nativo:** posso adicionar `url_launcher` e `permission_handler` e escrever o canal em Kotlin (SMS direto e ligação direta)?
2. **Permissões:** posso declarar `SEND_SMS` e `CALL_PHONE` no manifesto? Elas são sensíveis e o Android pede a autorização da usuária em tempo de uso.
3. **Atenção:** envia o SMS com a localização **automaticamente**, sem confirmação, como o Perigo? Hoje o card da Atenção ativa com um toque só, então um toque acidental avisaria toda a rede. Sugestão: adicionar uma confirmação simples também à Atenção.
4. **Quem recebe o SMS:** todos **menos** o contato que será ligado (conforme você pediu), ou todos, inclusive ele?
5. **Quem ligar até a Fase 10:** o primeiro contato da lista serve como regra provisória?
6. **Testes seguros:** quer uma chave de "modo de demonstração" que simule o envio sem mandar nada (útil para ensaiar a apresentação)? Sugestão: sim.

---

## Retrospectiva

**O que aprendi:**
- (preencha com as suas palavras)

**O que mudou em relação ao plano:**
- **Decisão revista da Fase 0:** o SMS direto (`SEND_SMS`) e a ligação direta (`CALL_PHONE`) **entraram**, a pedido da usuária, porque o APK da mostra é instalado direto. O WhatsApp continua manual (um toque), pois o envio automático é inviável.
- A tela de progresso passou a **seguir o print do Figma** (fundo na cor do modo, símbolo menor, cartões escuros por etapa e botão "Cancelar alerta"), com **grupos "Avisados" e "Não foi possível avisar"** por pedido da usuária.
- A **Atenção ganhou confirmação**, porque agora o envio é automático e um toque acidental avisaria a rede inteira.
- **Modo de demonstração** em Configurações (sugestão do plano): ensaia o alerta sem mandar SMS nem ligar. Desligado ao abrir o app, de propósito.
- Os SMS saem **antes** da ligação (ela toma a tela), e **desativar o modo cancela** os envios que faltam.
- `permission_handler` ficou na **versão 12.0.1**: a 13 exige compilar contra o Android 37, que o plugin de build atual não suporta.
- **Defeito encontrado nos testes manuais:** o alerta disparado direto da Home via a rede vazia, porque os controladores eram criados só quando uma tela os lia e carregavam de forma assíncrona. Corrigido com `lazy: false`, com o alerta esperando o carregamento (`ready`) e com um **prazo de 2 s**, para o alerta nunca ficar preso numa leitura que trava.
- Fora do plano: **ícone adaptativo do app**, registro do **tipo** do erro de SMS e ligação (sem dados pessoais) e o diálogo de confirmação compartilhado.
- O travamento do emulador ("isn't responding") veio de **pouca memória no computador**, e não do app.

**Dívidas técnicas e novos itens para o backlog:**
- **F9-05:** confirmar o SMS direto e a ligação num **celular real**; no emulador o SMS falhou com a mensagem genérica. Ligar o emulador e procurar a linha `AdaAlert: Falha ao enviar SMS: <tipo>` no `adb logcat`.
- **F9-06:** o texto da tela de cadastro de contato promete um **aviso por WhatsApp ao contato cadastrado**, que não existe. Ajustar o texto ou implementar (é questão de consentimento, LGPD).
- O contato de plantão é **o primeiro da lista** até a Fase 10.
- Conferir a tela Alerta e a da Atenção com o Figma; o menu do canto direito do Figma não foi implementado.
- `SEND_SMS` é restrito pela Play Store: serve para o APK da mostra, e não para publicar.
- Voltar ao `permission_handler` 13 quando o plugin de build aceitar o Android 37.
- O envio por `sms:` com vários destinatários (F9-04) não foi testado.
