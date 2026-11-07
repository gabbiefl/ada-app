# Fase 9 — Comunicação: chamada, mensagem e WhatsApp

> **Status:** 📝 em planejamento (aguardando aprovação)
> **Itens do backlog:** F9-01, F9-02, F9-03, F9-04

## 1. Objetivo
Fazer o alerta chegar à rede de confiança: ao ativar o Modo Perigo (ou Atenção), o app busca a localização, monta a mensagem com o link e deixa a usuária **enviar por WhatsApp ou SMS** e **ligar** para cada contato, com poucos toques.

## 2. Resultado esperado
- Ao confirmar o **Modo Perigo**, abre a tela **Enviar alerta**: o app já está buscando a localização e, quando ela chega (ou não chega), o texto fica pronto.
- A tela lista os contatos da rede. Cada um tem **WhatsApp**, **SMS** e **Ligar**.
- Tocar em WhatsApp ou SMS abre o app correspondente **com a mensagem pronta**. A usuária só toca em enviar, porque o envio 100% automático não é possível (Fase 0).
- **Ligar** abre o discador já com o número.
- No **Modo Atenção**, a mesma tela aparece só com a mensagem de atenção e a localização, **sem ligar** (decisão da usuária: a Atenção só compartilha a localização).
- Sem contatos, sem WhatsApp instalado ou sem localização, o app explica e oferece o que dá para fazer, sem fechar.

## 3. Conceitos que vamos aprender
- Esquemas de URL (`tel:`, `sms:`, `https://wa.me/`) e como o Android abre outros apps (intents)
- `url_launcher` e `LaunchMode.externalApplication`
- Codificação de texto em URL (`Uri.encodeComponent`) e número no formato internacional
- `<queries>` no `AndroidManifest.xml` (visibilidade de apps no Android 11 ou mais)
- Orquestrar vários serviços: localização + texto + contatos (um controlador que junta tudo)
- Interface + versão falsa (mais uma vez), para testar sem abrir app nenhum
- Honestidade sobre limites: o que é automático e o que exige o toque da usuária

## 4. Escopo
**Dentro:**
- Pacote `url_launcher` (com a sua confirmação) e `<queries>` no manifesto
- Funções puras que montam as URLs (WhatsApp, SMS, ligação) a partir de telefone e texto, com testes
- `AlertLauncher` (interface), versão real e versão falsa
- `AlertController`: busca a localização, monta o texto (`buildAlertText`) e guarda o estado do alerta
- Tela **Enviar alerta**: lista de contatos com WhatsApp, SMS e Ligar; estados de localização; rede vazia
- Ligar a ativação do Perigo e da Atenção a essa tela, e um jeito de reabri-la enquanto o modo está ativo
- Testes unitários, de widget e de fluxo; teste manual no emulador

**Fora (vai para o backlog ou outras fases):**
- **Envio automático** de WhatsApp e SMS sem toque (inviável, Fase 0)
- **Ligação direta** com `CALL_PHONE` (decidido: só abre o discador; ver seção 7)
- Escolher **quem ligar por horário** (Fase 10): aqui a usuária escolhe o contato na lista
- Acompanhamento em tempo real (F8-04) e mapa interativo (F8-05)
- Histórico de alertas (continua "Em breve")
- Saber se a mensagem foi mesmo enviada (o app não consegue ver o que acontece dentro do WhatsApp ou do SMS)

## 5. Pré-requisitos
- Fases 5 a 8 concluídas (contatos, mensagens, modos e localização)
- Ambiente Android pronto (emulador ou celular)
- Confirmação do pacote `url_launcher` e das mudanças no manifesto (seção 11)

## 6. Passos
| # | Passo | Tamanho | O que a usuária aprende |
|---|---|---|---|
| 1 | `url_launcher` e `<queries>` no manifesto; funções puras das URLs (`wa.me`, `sms:`, `tel:`) com telefone no formato internacional; `AlertLauncher` (interface e versão falsa); testes | M | Esquemas de URL, codificação de texto |
| 2 | Versão real do `AlertLauncher` com `url_launcher`: abrir WhatsApp, SMS e discador, devolvendo falhas tipadas (app não instalado, não abriu) | M | Intents, falha como valor |
| 3 | `AlertController`: ao iniciar, busca a localização (com tempo limite), monta o texto com a mensagem do modo e guarda o estado (preparando, pronto, sem localização) | M | Orquestrar serviços, reuso do que já existe |
| 4 | Tela **Enviar alerta**: contatos com WhatsApp, SMS e Ligar; aviso de localização; rede vazia; erros claros | G | Tela composta de vários estados |
| 5 | Ligar a tela à ativação do Perigo e da Atenção (Atenção sem "Ligar") e a um botão na Home para reabri-la | P | Navegação a partir de uma ação |
| 6 | Testes de fluxo, teste no emulador, `flutter analyze`, retrospectiva, resumos e backlog | P | Fechar a fase |

## 7. Decisões técnicas
| Decisão | Alternativas consideradas | Motivo |
|---|---|---|
| `url_launcher` para abrir WhatsApp, SMS e discador (já escolhido na Fase 0) | Intents nativas em Kotlin; `flutter_phone_direct_caller` | Padrão do Flutter, sem código nativo. Os três usam esquemas de URL |
| **Ligar abre o discador** (`tel:`), sem ligar direto | `CALL_PHONE` (liga sem o toque extra) | Custa 1 toque extra, mas não precisa de permissão sensível nem de pacote novo. Menos risco para o app e para a usuária |
| WhatsApp por `https://wa.me/55DDDNÚMERO?text=…` | `whatsapp://send` | `wa.me` é o link oficial; abre o app e, sem ele, o navegador. Número no formato internacional |
| SMS por `sms:` com `?body=`, um contato por vez | SMS direto (`SEND_SMS`) | Já decidido na Fase 0: SMS direto é restrito pela Play Store. A usuária toca em enviar |
| "Acionar a rede" = **sequencial**: a usuária toca contato por contato | Envio simultâneo | Sem SMS direto não há simultâneo (Fase 0). O spike do `sms:` com vários destinatários fica como opcional (ver seção 8) |
| URLs montadas por **funções puras** | Montar a URL na tela | Testáveis sem abrir app. Toda a formatação (55, DDD, codificação) fica num lugar só |
| `AlertLauncher` atrás de interface | `url_launcher` direto nas telas | Os testes confirmam o que seria aberto, sem abrir nada. Mesma ideia do `Haptics` e do `LocationService` |
| `AlertController` junta localização + mensagem + contatos | Lógica dentro da tela | A tela só desenha estados; as regras ficam testáveis |
| Alerta sai **mesmo sem localização**, avisando (`buildAlertText`) | Bloquear o envio sem GPS | RNF03: pedir ajuda não pode depender do GPS |
| Aviso de que a mensagem fica no histórico do WhatsApp e do SMS | Não avisar | Já previsto na Fase 0 (privacidade): quem tem acesso ao celular pode ver |
| Nada de telefone, texto ou coordenada em `print`/`debugPrint` | Logs para depurar | Privacidade (P6): são dados pessoais de alto risco |

## 8. Riscos e plano B
| Risco | Impacto | Plano B |
|---|---|---|
| Prazo da mostra (12/11/2026) | É a fase que mais pesa na demonstração, e as Fases 10, 11 e 12 vêm depois | Meta de 2 dias. Se apertar: entregar os passos 1 a 5 só com **WhatsApp e Ligar**, e SMS em seguida |
| O emulador pode não ter WhatsApp instalado | Não dá para ver o WhatsApp abrir | `wa.me` cai no navegador e mostra o mesmo link; os testes confirmam a URL montada. No celular real vale conferir |
| Android 11 ou mais esconde outros apps do nosso | `canLaunchUrl` dá "não" mesmo com WhatsApp | Declarar `<queries>` (passo 1) e tratar a falha sem depender só do `canLaunchUrl` |
| Número do contato em formato errado | O app de destino não abre a conversa | Número guardado só com dígitos (Fase 5); a função acrescenta `55` e é testada |
| Texto longo no SMS ou no link | Mensagem cortada | Limite de 200 letras na mensagem (Fase 6) + link curto; testar o tamanho final |
| `sms:` com vários destinatários varia por aparelho | "SMS para todos" pode não funcionar | Opcional, só se sobrar tempo; o envio individual é o caminho garantido |
| A usuária esquece de tocar em enviar | Alerta não sai | Deixar claro na tela: "Toque em enviar no WhatsApp/SMS". Explicar na apresentação que o envio exige o toque |
| Figma da tela de alerta não lido | Visual diferente do design | Montar com widgets e tema que já existem (plano B combinado nas fases anteriores); a usuária confere depois |

## 9. Critérios de pronto
- [ ] Confirmar o Perigo abre a tela **Enviar alerta**; a Atenção abre a mesma tela sem "Ligar"
- [ ] WhatsApp e SMS abrem com a mensagem e o link prontos; Ligar abre o discador com o número
- [ ] Sem localização, sem contatos ou sem WhatsApp, o app explica e não fecha
- [ ] A tela avisa que é preciso tocar em enviar e que a mensagem fica no histórico
- [ ] Nenhum telefone, texto ou coordenada em `print`/`debugPrint`
- [ ] Testes unitários, de widget e de fluxo passando (launcher falso)
- [ ] `flutter analyze` sem avisos
- [ ] Testado no emulador (discador e SMS; WhatsApp se houver)
- [ ] Backlog atualizado e commit feito

## 10. Como testar
`flutter run -d emulator-5554`: cadastrar 1 ou 2 contatos → Home → **MODO PERIGO** → Ativar → conferir a tela Enviar alerta → tocar em Ligar (abre o discador), SMS (abre o app de mensagens com o texto) e WhatsApp (abre o app ou o navegador). Repetir com o **MODO ATENÇÃO** (sem Ligar), com a rede vazia e com a localização do emulador desligada. `flutter analyze` e `flutter test`.

## 11. Perguntas em aberto
1. **Pacote `url_launcher`:** posso adicionar, junto com o `<queries>` (tel, sms, https e WhatsApp) no manifesto?
2. **Ligar:** abrir só o discador (assumido, sem permissão nova), ou quer tentar a ligação direta com `CALL_PHONE`? Eu recomendo o discador, por causa do prazo e da permissão sensível.
3. **Depois de ativar:** abrir a tela **Enviar alerta** automaticamente (assumido), ou só mostrar um botão na Home?
4. **Acionar a rede:** a usuária toca em cada contato, um por vez (assumido). O "SMS para todos de uma vez" fica como opcional. Pode ser assim?
5. **Atenção:** abre a mesma tela, com a mensagem de atenção e a localização, sem o botão de ligar. É isso que você quer?

---

## Retrospectiva (preencher ao concluir)

**O que aprendi:**
- <...>

**O que mudou em relação ao plano:**
- <...>

**Dívidas técnicas e novos itens para o backlog:**
- <...>
