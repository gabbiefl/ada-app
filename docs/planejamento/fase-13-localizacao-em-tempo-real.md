# Fase 13 — Localização em tempo real

> **Status:** 📝 plano aguardando aprovação. **A execução fica para depois da mostra (12/11/2026):** é um módulo de semanas, e a mostra pede o APK e o ensaio.
> **Itens do backlog:** F8-04 (acompanhamento ao vivo) e F8-05 (mapa visual, para a página do contato)

## 1. Objetivo
Durante um alerta, as pessoas de confiança **acompanham a posição da usuária se movendo**, abrindo um link no navegador do celular delas (sem precisar instalar nada), até a usuária parar ou o tempo acabar.

## 2. Por que é diferente de tudo o que já fizemos
Hoje a localização **nunca sai do celular** a não ser no SMS (um link para um ponto fixo). Acompanhar ao vivo exige um **servidor** que receba a posição da usuária e a entregue aos contatos. Isso muda a promessa "nada sai do celular", traz a permissão de **internet** e leva a localização para fora do aparelho. Por isso a **primeira etapa é de decisões e de privacidade, antes de código**.

## 3. Resultado esperado
- Ao ativar o Perigo (ou ao tocar em "Compartilhar ao vivo"), o SMS leva um **link de acompanhamento**.
- O app envia a posição a cada poucos segundos, mesmo com a tela apagada, com **notificação fixa** ("O ADA está compartilhando sua localização") e um botão **Parar**.
- O contato abre o link e vê um **mapa com a posição atualizando** e "última atualização há X segundos".
- O compartilhamento **acaba sozinho** no prazo (ex.: 1 hora), ao desativar o modo ou ao tocar em Parar. Depois disso, **nada fica guardado**.
- Sem internet, o alerta por SMS e ligação continua funcionando normalmente (o ao vivo é um **reforço**, não uma dependência).
- **Presença dos contatos** (passo 8): a usuária vê, na tela de alerta, quem está acompanhando agora, quem saiu e quem ainda não abriu o link.

## 4. Decisões que precisam ser tomadas ANTES de qualquer código
| # | Decisão | Opções | Minha sugestão |
|---|---|---|---|
| D1 | Quando começa | Automático com o Perigo / botão separado / os dois | **Automático no Perigo**, com Parar sempre visível. Na Atenção, só se a usuária pedir |
| D2 | Quanto dura | 30 min, 1 h, até parar | **1 hora**, com opção de prorrogar |
| D3 | Quem vê e como | Link no navegador / app para o contato | **Link no navegador**: o contato não instala nada |
| D4 | Identificação | Conta com e-mail / sessão anônima | **Sessão anônima**: um código aleatório e longo (impossível de adivinhar) por alerta, sem login |
| D5 | O que fica guardado | Histórico / só o último ponto | **Só o último ponto**, sobrescrito a cada envio, apagado ao final |
| D6 | Serviço de servidor | Firebase / Supabase / servidor próprio | **Firebase** (já previsto no backlog, nível gratuito, fácil) ou Supabase. Decidir por custo e país dos dados |
| D7 | Mapa da página | OpenStreetMap + Leaflet (sem chave de API) / Google Maps | **OpenStreetMap + Leaflet** |
| D9 | Presença dos contatos | Sem presença / só "abriu" / "acompanhando agora" | **"Acompanhando agora" por sinal de vida da página** (ver passo 8), com só o último horário por contato |
| D10 | Link por contato | Um link para todos / um link por contato | **Um link por contato** (o SMS já é um por contato): é o que permite saber quem abriu |
| D8 | Aviso à pessoa acompanhada | Só o link no SMS / texto explicando antes | O SMS explica quem está compartilhando e por quê; o link só funciona enquanto o compartilhamento está ativo |

## 5. Passos
| # | Passo | Tamanho | Depende de |
|---|---|---|---|
| 1 | **Decisões D1 a D8 e revisão de privacidade** (documento `privacidade-e-dados.md`, texto do onboarding e da tela 3, texto da permissão) | M | — |
| 2 | **Preparar o servidor:** projeto no serviço escolhido, regras de segurança (ninguém lista sessões; só quem tem o código lê; só a dona grava), expiração automática. **Chaves e arquivos de configuração NÃO entram no repositório público** | M | 1 |
| 3 | **Regras puras e testáveis:** sessão (código, início, validade), prazo, intervalo de envio, quando parar. Com o relógio injetável, como no horário de cobertura | M | 1 |
| 4 | **Rastreamento no app:** um `LocationTracker` (contrato, versão real e versão falsa) com fluxo contínuo de posições. O `geolocator` já usado tem serviço em primeiro plano com notificação. Permissões novas do Android (serviço em primeiro plano de localização) | G | 3 |
| 5 | **Envio ao servidor:** um `SessionPublisher` (contrato, versão real e falsa), com permissão de **internet** no APK de release, tentativa de novo se a rede falhar e só o último ponto | G | 2, 4 |
| 6 | **Integração com o alerta:** o link entra no SMS, o rastreamento começa com o Perigo, e há cartão de status na tela de alerta, chip na Home e botão **Parar** | G | 4, 5 |
| 7 | **Página web do contato:** HTML e JavaScript simples (Leaflet + OpenStreetMap), lê a sessão pelo código, mostra o ponto e "última atualização há X s", e uma mensagem clara quando acabou. Sem rastreadores nem análise de uso | G | 2 |
| 8 | **Presença dos contatos** (ver seção 5.1): a página do contato manda um sinal de vida enquanto está aberta e visível, o app escuta ao vivo e mostra o status de cada contato na tela de alerta | M | 6, 7 |
| 9 | **Segurança e privacidade, de ponta a ponta:** testar as regras do servidor (tentar ler sem o código, listar, escrever sem ser a dona), conferir a exclusão automática, atualizar a documentação e os textos do app | M | 5, 7, 8 |
| 10 | **Testes:** unitários (prazo, parada), de widget (Parar, status), com versões falsas; **teste real** em dois celulares, com rede ruim, tela apagada e medida de bateria | G | 6, 7, 8 |
| 11 | Fechamento: README, backlog, retrospectiva e roteiro | P | 10 |

**Estimativa honesta:** de **1 a 2 semanas de trabalho focado**. Os passos 4, 5, 6, 7 e 10 são os grandes; a presença (8) é pequena depois que o servidor e a página existem. Os passos 3 e 4 podem começar sem servidor, o que permite entregar primeiro um **marco intermediário** (ver seção 8).

## 5.1 Presença dos contatos (ideia da usuária, 09/11/2026)
A usuária vê se cada pessoa da rede está acompanhando. **Só funciona com servidor**: o SMS não tem confirmação de leitura.

| Status na tela de alerta | Quando |
|---|---|
| **Acompanhando** | A página do contato está aberta e visível, com sinal de vida nos últimos ~30 segundos |
| **Ausente · visto há X min** | Ela já abriu, mas fechou a página ou saiu dela (depois de cerca de 5 minutos sem sinal) |
| **Ainda não abriu** | Nunca abriu o link |

**Como funciona:**
- Cada contato recebe um **link próprio** (um código por contato).
- A página, enquanto estiver aberta **e visível**, manda um sinal ao servidor a cada poucos segundos (o navegador avisa quando a aba fica em segundo plano). **Tocar no mapa não é necessário**: quem acompanha um mapa não toca em nada.
- O app da usuária escuta essas mudanças ao vivo e atualiza os cartões de cada contato.

**Cuidados de privacidade:**
- Guarda **só o último horário** de cada contato, apagado ao final do alerta (nada de histórico de acessos).
- A página avisa quem abre: *"A usuária vê que você está acompanhando."*
- O status é **informativo**: não bloqueia nem decide nada, e o texto é neutro ("Ainda não abriu", e não "falhou").
- Vale só durante o ao vivo e depende de internet dos dois lados.

**Ideia que combina:** se **ninguém abrir em ~5 minutos**, o app **sugere ligar** para outro contato ou para o 190, com um toque (o 190 e o 180 já estão na Home).

## 6. O que muda no app (e na promessa de privacidade)
| Hoje | Depois |
|---|---|
| "Nada sai do celular a não ser o SMS" | "A posição só sai **durante um alerta**, para quem a usuária escolheu, e é apagada ao final" |
| Sem permissão de internet | Com permissão de internet (só para o ao vivo) |
| Localização na memória, nunca guardada | Último ponto no servidor, com prazo e exclusão automática |
| Sem notificação do app | Notificação fixa enquanto compartilha |
| O ADA não sabe se alguém viu o alerta | O ADA mostra quem está acompanhando (só durante o ao vivo, com o último horário) |

## 7. Riscos e plano B
| Risco | Impacto | Plano B |
|---|---|---|
| O Android encerrar o serviço em segundo plano (economia de bateria dos fabricantes) | O ao vivo para no meio | Serviço em primeiro plano com notificação, testes em celulares reais e orientação ao usuário. **O SMS com a última posição continua** |
| Sem internet no momento do perigo | Não há ao vivo | O alerta por SMS e ligação independe disso (o ao vivo é reforço) |
| Vazamento de um link de acompanhamento | Alguém indevido vê a posição | Código longo e aleatório, validade curta, só o último ponto, e a usuária pode **Parar** a qualquer momento |
| Custo ou limite do plano gratuito | Interrupção | Número de sessões é baixo (um app acadêmico); acompanhar o uso |
| O contato não abrir o link | Sem acompanhamento | O SMS com o ponto fixo segue valendo |
| Gasto de bateria | A usuária fica sem carga | Intervalo de envio razoável (ex.: 10 a 15 s, ou por distância) e prazo máximo |
| Segredos no repositório público | Exposição de chaves | Arquivos de configuração fora do Git (`.gitignore`) e regras de segurança no servidor, e não no app |

## 8. Marco intermediário sugerido (sem servidor)
Antes do servidor, dá para entregar **checkpoints por SMS**: durante o alerta, o app manda um novo link da posição a cada N minutos. Aproveita os passos 3 e 4 (regras e serviço em primeiro plano), não exige internet nem servidor e mantém a promessa de privacidade. Se o tempo for curto, é o que entrega valor mais rápido.

## 9. Critérios de pronto (do módulo completo)
- [ ] D1 a D8 decididas e a documentação de privacidade atualizada **antes** do código
- [ ] O link chega no SMS e abre o mapa no navegador do contato, sem instalar nada
- [ ] A posição atualiza com a tela apagada, com notificação visível e botão Parar
- [ ] A tela de alerta mostra, por contato, "Acompanhando", "Ausente" ou "Ainda não abriu", e a página avisa quem abre que a usuária vê isso
- [ ] O compartilhamento acaba por prazo, por desativar o modo e por Parar; depois **nada** fica no servidor
- [ ] As regras do servidor foram testadas (não dá para listar nem ler sem o código)
- [ ] Sem internet, o alerta por SMS e ligação segue funcionando
- [ ] Nenhuma chave nem configuração sensível no repositório público
- [ ] `flutter analyze` limpo, testes passando, **compilado para Android** e testado em celular real
- [ ] Backlog e retrospectiva atualizados

## 10. Perguntas em aberto
1. **Prioridade:** começar pelos checkpoints por SMS (seção 8) ou ir direto ao servidor?
2. **Serviço:** Firebase ou Supabase? (Você já tem conta em algum deles?)
3. **Quando começar o ao vivo:** automático no Perigo (sugerido)?
4. **Duração padrão:** 1 hora?
5. **Quem acompanha:** só pelo link no navegador (sugerido)?
6. **Presença:** os rótulos "Acompanhando", "Ausente · visto há X min" e "Ainda não abriu" (em vez de online, ausente e offline) e o sinal de vida da página (em vez de "interagir")? Existe um desenho no Figma desses status?
7. **Quando executar:** a partir de 13/11, depois da mostra, certo?

---

## Retrospectiva

**O que aprendi:**
- (preencha com as suas palavras)
