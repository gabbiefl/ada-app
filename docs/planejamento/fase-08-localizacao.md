# Fase 8 — Localização

> **Status:** 🔄 em execução (plano aprovado)
> **Itens do backlog:** F8-01, F8-02, F8-03 (e F3-11, versão simples da aba Mapa)

## 1. Objetivo
Obter a localização atual da usuária, com permissão e tratamento de erros, mostrá-la na aba **Mapa** e deixá-la pronta para entrar na mensagem de alerta como um link de mapa.

## 2. Resultado esperado
- Na aba **Mapa**, um botão pede a localização atual. Antes do diálogo do Android, o app explica por que precisa dela.
- Com permissão, a tela mostra a localização (coordenadas) e um link de mapa.
- Se faltar permissão, GPS ligado ou a busca demorar demais, aparece uma explicação clara e uma ação (tentar de novo, abrir as configurações), sem o app fechar.
- Existe uma função que monta o **texto do alerta**: a mensagem escolhida + o link de mapa (ou um aviso, se a localização não estiver disponível). Ainda **não envia** nada (Fase 9).

## 3. Conceitos que vamos aprender
- Permissões em tempo de execução no Android (o que é pedir, negar, negar para sempre)
- `AndroidManifest.xml` e as permissões declaradas
- Pacote de geolocalização e `Future` com tempo limite (`timeout`)
- Resultado com sucesso ou falha tipada (o mesmo padrão `null`/enum dos controladores)
- Interface + versão falsa para testar sem GPS (como o `Haptics`)
- Simular a localização no emulador
- Link de mapa (`https://maps.google.com/?q=lat,lng`) e montagem de texto

## 4. Escopo
**Dentro:**
- Pacote `geolocator` (com a sua confirmação)
- Permissões de localização aproximada e precisa no `AndroidManifest.xml`
- `GeoPoint` (latitude e longitude), `LocationService` (interface), versão real e versão falsa
- `LocationController` e `provider`
- Aba **Mapa** simples: botão, estados (carregando, sucesso, erro) e o link
- Função que monta o texto do alerta (mensagem + link) e testes
- Testes unitários, de widget e de fluxo; teste manual no emulador

**Fora (vai para o backlog):**
- **Mapa visual** dentro do app (ideal para a mostra, entra se sobrar tempo): F8-05, com `flutter_map` e OpenStreetMap, sem chave de API
- **Acompanhamento em tempo real** e página de rastreamento (F8-04, depois da Fase 9)
- Localização em segundo plano, serviço em primeiro plano e checkpoints (F0-02, F3-11)
- Enviar a mensagem com o link (Fase 9)
- Guardar a localização: **não guardamos**. Ela existe só na memória enquanto é usada

## 5. Pré-requisitos
- Ambiente Android pronto (F1-04 e F1-05 ✅)
- Fases 6 e 7 concluídas (mensagens e modos)
- Confirmação do pacote `geolocator` e das permissões do Android (seção 11)

## 6. Passos
| # | Passo | Tamanho | O que a usuária aprende |
|---|---|---|---|
| 1 ✅ | `geolocator` e permissões no manifesto; `GeoPoint`, `LocationService` (interface e versão falsa) e a função do link de mapa, com testes | M | Pacote novo, manifesto, interface para testar |
| 2 ✅ | Versão real do serviço: checar GPS e permissão, explicar antes de pedir, buscar a posição com tempo limite e devolver cada falha | M | Permissões em tempo de execução, `timeout` |
| 3 | `LocationController` (estados: parado, carregando, sucesso, falha) e `provider` | M | Reuso do padrão controlador |
| 4 | Aba **Mapa**: botão, explicação, resultado, link e erros com ação (tentar de novo, abrir configurações) | M | Estados de tela, tratamento de erro |
| 5 | Montar o texto do alerta: mensagem + link, ou mensagem + aviso se faltar localização | P | Template de texto (fecha a ideia da Fase 6) |
| 6 | Teste no emulador (localização simulada), testes de fluxo, `flutter analyze`, retrospectiva, resumos e backlog | P | Fechar a fase, simular GPS |

## 7. Decisões técnicas
| Decisão | Alternativas consideradas | Motivo |
|---|---|---|
| `geolocator` para a posição (já escolhido na Fase 0) | `location` | Padrão do mercado, boa documentação, trata permissão e GPS desligado |
| **Sem** `permission_handler` | Adicionar o pacote | O `geolocator` já pede e consulta a permissão de localização. Um pacote a menos. Entra na Fase 9 se precisarmos de outras permissões |
| Só permissão em **primeiro plano** (aproximada e precisa) | Incluir localização em segundo plano | Em segundo plano exige permissão especial, serviço em primeiro plano e é revisada pela loja. Fora do escopo (F0-02) |
| Serviço atrás de interface (`LocationService`) | Chamar o `geolocator` direto na tela | Nos testes dá para simular posição e cada falha, sem GPS (mesma ideia do `Haptics` e dos repositórios) |
| Falha como valor tipado (`LocationFailure`) | Lançar exceções até a tela | Padrão do projeto: a tela só escolhe o texto de cada caso, e o app nunca fecha por falta de permissão (RNF04) |
| Tempo limite na busca (cerca de 10 s) | Esperar indefinidamente | RNF03: o alerta não pode travar esperando o GPS. Sem posição, segue sem ela, avisando |
| Link `https://maps.google.com/?q=lat,lng` | Link do OpenStreetMap; texto com coordenadas | Abre direto no app de mapas de qualquer celular; já definido na Fase 0 |
| **Não gravar** a localização | Guardar a última posição | Privacidade (P6): dado de alto risco. Nada vai para `print`/`debugPrint` |
| Pedir a permissão só no momento de uso, com explicação antes (P2) | Pedir ao abrir o app | O diálogo sem contexto é negado com mais frequência; a regra vem da Fase 0 |
| Aba Mapa **simples** agora, mapa visual depois (F8-05) | Mapa já na Fase 8 | Decisão da usuária: mapa é o ideal, mas fica como placeholder por causa do prazo |

## 8. Riscos e plano B
| Risco | Impacto | Plano B |
|---|---|---|
| Prazo da mostra (12/11/2026) | A Fase 9 (envio) é o que mais pesa na demonstração e vem depois desta | A Fase 8 deve ficar em cerca de 1 a 2 dias. Se apertar: entregar os passos 1 a 3 e 5 (localização + texto do alerta) e deixar a aba Mapa só com o botão e o link |
| O Figma da aba Mapa não foi lido (F3-11) | Visual diferente do design | Montar com os widgets e o tema que já existem; a usuária confere depois. Não gastamos chamada do Figma agora |
| Emulador sem localização | Não dá para ver sucesso | Definir a posição em **⋯ (Extended controls) → Location** do emulador; os testes usam o serviço falso |
| Permissão negada para sempre | Nunca mais aparece o diálogo | Mostrar como liberar nas configurações do app, com botão para abri-las |
| Localização ao vivo é o ideal, mas não cabe agora | Demonstração sem rastreamento | Link de localização no momento do alerta (placeholder). Ao vivo fica em F8-04 |
| Localização é dado de alto risco | Exposição | Não gravar, não imprimir, pedir só ao usar e explicar antes |

## 9. Critérios de pronto
- [ ] Botão da aba Mapa pede a localização, com explicação antes do diálogo do Android
- [ ] Com permissão e GPS, a tela mostra a localização e o link de mapa
- [ ] Permissão negada, negada para sempre, GPS desligado e tempo esgotado têm explicação e não fecham o app
- [ ] A função monta o texto do alerta com o link, e sem localização avisa isso
- [ ] Nenhuma coordenada em `print`/`debugPrint`, e nada guardado no aparelho
- [ ] Testes unitários, de widget e de fluxo passando (serviço falso)
- [ ] `flutter analyze` sem avisos
- [ ] Testado no emulador com localização simulada
- [ ] Backlog atualizado e commit feito

## 10. Como testar
`flutter run -d emulator-5554`: aba Mapa → tocar no botão → permitir. No emulador, ajustar a posição em **⋯ → Location**. Testar também negar a permissão, negar para sempre e desligar a localização do emulador. `flutter analyze` e `flutter test`.

## 11. Perguntas em aberto
1. **Pacote `geolocator`:** posso adicionar? (sem `permission_handler`, como explicado na seção 7)
2. **Permissões do Android:** posso declarar `ACCESS_COARSE_LOCATION` e `ACCESS_FINE_LOCATION` no manifesto? Não pedimos localização em segundo plano.
3. **Quando pedir a permissão:** ao tocar no botão da aba Mapa (assumido). Na Fase 9, ao ativar o Perigo, usaremos a mesma lógica. Pode ser assim?
4. **Aba Mapa:** manter o título "Em breve" e trocar pelo conteúdo simples (botão + localização + link)? É o que o plano assume.

---

## Retrospectiva (preencher ao concluir)

**O que aprendi:**
- <...>

**O que mudou em relação ao plano:**
- <...>

**Dívidas técnicas e novos itens para o backlog:**
- <...>
