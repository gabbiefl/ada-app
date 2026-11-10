# Fase 12D — Telas de permissões (pedido, concedidas e negadas)

> **Status:** ✅ concluída no código em 10/11/2026 (pendente: ver no emulador, inclusive negando de propósito)
> **Itens do backlog:** F3-10 (tela de permissões)

## 1. Objetivo
Na primeira abertura, depois do onboarding, o ADA **explica as permissões que usa e pede todas de uma vez**, mostrando o resultado: tudo concedido ("Tudo pronto!") ou o que faltou, com o que deixa de funcionar e como resolver.

## 2. Fluxo
```
Splash ─► Onboarding ─► Permissões ─► Home
                          │
                          ├─ "Permitir acesso" ─► (Android pergunta uma a uma) ─► Tudo pronto!  ─► Continuar ─► Home
                          │                                                     └► Faltam algumas ─► Tentar de novo / Abrir configurações / Continuar mesmo assim ─► Home
                          └─ "Agora não" ─► Home (o app pede cada permissão na hora do uso, como já fazia)
```

## 3. As 3 telas
| Tela | Origem |
|---|---|
| **Pedido** ("Precisamos de 3 permissões para proteger você") | Figma |
| **Concedidas** ("Tudo pronto!") | Figma |
| **Negadas** ("Faltam algumas permissões") | **Não existe no Figma**: criada a partir das duas, no mesmo estilo (a usuária pediu) |

## 4. O que NÃO bate com o Figma, e o que fiz
O Figma lista **Localização, Contatos e Telefone**. O ADA, na prática, precisa de **Localização, SMS e Telefone**:

| Permissão no Figma | Situação real do app | Decisão |
|---|---|---|
| Localização ("em tempo real") | Usada **uma vez**, no alerta (sem tempo real, que é a Fase 13) | Texto ajustado: "Para enviar onde você está junto com o alerta." |
| **Contatos** ("escolher pessoas da sua agenda") | O app **não lê a agenda**: o botão "Escolher da agenda" ainda não funciona (IDEIA-08) e a permissão nem está no manifesto. Pedir uma permissão que não se usa fere o princípio da necessidade (LGPD) | **Trocado por SMS** |
| (não existe no Figma) **SMS** | É a permissão **mais importante**: sem ela o SMS automático não sai | **Incluída**: "Para avisar a sua rede por SMS quando você ativar um alerta." |
| Telefone | Usada para ligar ao contato de plantão e ao 190/180 | Mantida |

Se um dia o "Escolher da agenda" for implementado, a permissão de Contatos entra junto.

## 5. Tela de negadas (desenho próprio)
- Ícone amarelo (atenção) no lugar do verde, título **"Faltam algumas permissões"**.
- Texto: "O ADA continua funcionando, mas de um jeito menos rápido. Você pode tentar de novo ou seguir assim."
- Cada permissão mostra o estado (✓ ou ✕) e, nas negadas, **o que acontece sem ela** (é o que o app faz de verdade, o plano B da Fase 9):
  - Localização: o alerta sai **sem o link do mapa**.
  - SMS: o ADA abre o app de mensagens e **a usuária toca em enviar**.
  - Telefone: o ADA abre o discador e **a usuária toca em ligar**.
- Botões: **Tentar de novo** (pede de novo) ou, se o Android bloqueou de vez ("não perguntar novamente"), **Abrir configurações**; e **Continuar mesmo assim**.
- Ao voltar das configurações do Android, a tela confere de novo sozinha.

## 6. Decisões técnicas
| Decisão | Motivo |
|---|---|
| Um `PermissionsService` (contrato, versão real e versão falsa) | Os testes não abrem o diálogo do Android. Mesmo padrão do `AlertActions` |
| Usa o `permission_handler` que já temos | Nenhum pacote novo |
| Sem chave nova no armazenamento | Depois do onboarding, "já viu" já está marcado. Fechar o app na tela de permissões só faz o app pedir na hora do uso |
| **"Agora não" leva à Home** | A usuária nunca fica presa; o app continua pedindo cada permissão quando precisa |
| Localização "em uso" (sem segundo plano) | É o que o alerta usa hoje |

## 7. Passos
| # | Passo |
|---|---|
| 1 ✅ | Serviço de permissões (contrato, real e falso) com testes |
| 2 ✅ | As 3 telas, o cartão de permissão e a rota; onboarding passa a levar a ela |
| 3 ✅ | Testes de fluxo, acessibilidade (alvos, nomes, texto em 2x) e compilar para Android |
| 4 | Privacidade, backlog e README |

## 8. Critérios de pronto
- [x] Pedido, concedidas e negadas implementadas, com os textos acima
- [x] "Permitir acesso" pede as 3 permissões; o resultado decide a tela seguinte
- [x] "Agora não" e "Continuar mesmo assim" levam à Home
- [x] Permissão bloqueada de vez leva a "Abrir configurações", e a tela confere de novo ao voltar
- [x] Auditoria de acessibilidade das 3 telas; `flutter analyze` limpo; testes passando; compilado para Android
- [ ] Visto no emulador (inclusive negando de propósito)
- [ ] Privacidade e backlog atualizados; commits pela usuária

## 9. Perguntas em aberto
1. **Contatos trocado por SMS**: concorda? (recomendo, pelos motivos acima)
2. Os textos da tela de negadas e a cor amarela do ícone estão bons?

---

## Retrospectiva

**O que aprendi:**
- (preencha com as suas palavras)
