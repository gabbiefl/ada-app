# Fase 10 — Horário de cobertura

> **Status:** 🔄 em execução (plano aprovado)
> **Itens do backlog:** F10-01, F10-02, F10-03, F3-07

## 1. Objetivo
Deixar a usuária definir **quem o ADA liga em cada faixa de horário** e fazer o Modo Perigo ligar para o contato certo conforme a hora, no lugar da regra provisória "o primeiro da lista". A tela segue o Figma (lista de faixas com chave liga/desliga e barra de cobertura das 24 horas) e ganha o que o design não mostra: **criar, editar e remover faixas, vinculando cada uma a um contato**.

## 2. Resultado esperado
- Em **Configurações → Horário de cobertura** (print do Figma):
  - Um cartão **"Cobertura das 24 horas"** com uma barra do dia (00h a 24h): trechos cobertos em verde e **buracos** (horas sem faixa) destacados.
  - Uma lista de faixas, cada uma com **ícone do período** (sol, pôr do sol ou lua), o horário ("8:00 - 13:00"), "Ligar para <contato>" e uma **chave liga/desliga**.
- A usuária **adiciona uma faixa**, escolhendo o **contato** e o horário de início e de fim (além do Figma).
- **Tocar numa faixa abre a edição** (trocar contato e horário) e permite **remover** (além do Figma).
- Faixa desligada não vale. O app **recusa** faixa que se cruza com outra ligada, explicando com qual.
- A tela mostra **quem seria ligado agora** ("Agora, o ADA ligaria para Gabriela"). Serve para conferir a regra e para ensaiar a apresentação.
- Ao ativar o **Modo Perigo**, a ligação vai para o contato da faixa da hora atual. Fora de todas as faixas ligadas, vai para o **primeiro contato da lista** (como hoje).
- As faixas ficam salvas ao fechar e abrir o app.

## 3. Conceitos que vamos aprender
- Regra de negócio em **Dart puro**, isolada e testável
- Intervalo de horas que **atravessa a meia-noite** (23:00 às 4:00), repartido em trechos do mesmo dia
- Hora como "minutos desde a meia-noite" (um número simples de comparar)
- **Interseção e união de intervalos** (recusar cruzamentos e achar os buracos da cobertura)
- **Relógio injetável**: testar "às 23h" sem esperar as 23h
- `showTimePicker`, `DropdownMenu` e `Switch` em formulário e lista
- Barra proporcional feita com `Row` e `Expanded(flex: ...)`
- Reaproveitar o padrão controlador + repositório + provider (mais uma vez)
- Trocar uma regra pela outra sem mexer no resto (`CallTargetPolicy` já existe)

## 4. Escopo
**Dentro:**
- Modelo `CoverageRule` (contato, início, fim, ligada ou desligada) e as funções puras: escolher o contato pela hora, achar cruzamentos, achar os buracos e escolher o ícone do período
- `CoverageController` e repositório (armazenamento seguro, mesmo padrão dos contatos), com validação
- `CoverageCallTargetPolicy`, ligada ao alerta no lugar de `FirstContactPolicy`
- Tela **Horário de cobertura** (cartão das 24 horas, lista, chave, "quem seria ligado agora")
- Formulário de **nova faixa** e de **edição**, com remoção
- Testes unitários, de widget e de fluxo; teste manual no emulador

**Fora (vai para o backlog):**
- **Dias da semana** (ex.: fim de semana diferente): as faixas valem todos os dias
- **Reordenar** faixas (não precisa: não há sobreposição)
- Escolher um **contato padrão** diferente do primeiro da lista
- Várias pessoas por faixa, ou "ligar para o próximo se não atender"
- Fuso horário: usa a hora do celular

## 5. Pré-requisitos
- Fase 9 concluída (o alerta já usa uma `CallTargetPolicy`)
- Contatos cadastrados (sem contatos, a tela explica e não deixa criar faixa)
- Print do Figma da tela: **recebido** (07/11/2026). O formulário de criar e editar não existe no design.

## 6. Passos
| # | Passo | Tamanho | O que a usuária aprende |
|---|---|---|---|
| 1 ✅ | `CoverageRule` e as funções puras (contato pela hora, cruzamentos, buracos, ícone do período), com testes nas bordas | M | Regra pura, horas como minutos, interseção de intervalos |
| 2 ✅ | `CoverageController` e repositório seguro: adicionar, editar, ligar/desligar, remover, validar (início = fim, cruzamento), gravar, carregar (`ready`), com testes | M | Reuso do padrão dos contatos |
| 3 ✅ | `CoverageCallTargetPolicy` com **relógio injetável**; ligar ao alerta e à espera de carregamento da Home | P | Injeção de dependência, trocar a regra sem mexer no resto |
| 4 ✅ | Tela **Horário de cobertura**: cartão das 24 horas, lista com ícone e chave, "quem seria ligado agora", estados vazios; rota no lugar de "Em breve" | G | Tela de vários estados, barra proporcional |
| 5 | Formulário de **nova faixa e edição**: contato, início, fim, validação, remover com confirmação | M | `showTimePicker`, formulário com seletor |
| 6 | Teste de fluxo (o Perigo liga para quem a hora manda), emulador, `flutter analyze`, retrospectiva, resumos e backlog | P | Fechar a fase |

## 7. Decisões técnicas
| Decisão | Alternativas consideradas | Motivo |
|---|---|---|
| Faixas valem **todos os dias** (sem dias da semana) | Dias da semana por faixa | O Figma também não mostra dias, e o prazo é curto |
| Hora guardada como **minutos desde a meia-noite** (0 a 1439) | `TimeOfDay`, `DateTime` | Um número simples de comparar, gravar em JSON e testar. A tela converte de e para `TimeOfDay` |
| Intervalo **[início, fim)**: o início conta, o fim não | Fim incluído | O Figma tem faixas coladas (8:00 às 13:00 e 13:00 às 18:00): as 13:00 pertencem só à segunda |
| Faixa que **atravessa a meia-noite** é permitida (23:00 às 4:00 no Figma), repartida em dois trechos (23:00 a 24:00 e 0:00 a 4:00) | Obrigar a dividir em duas faixas | O Figma já usa. Repartir em trechos deixa a cobertura, o cruzamento e a barra com a mesma regra simples |
| `início == fim` é **recusado** | Tratar como 24 horas | Ambíguo. Para cobrir o dia todo, basta uma faixa de 0:00 às 23:59, ou não criar faixa (vale o contato padrão) |
| **Faixas ligadas não podem se cruzar** (a tela diz com qual) | Permitir sobreposição e valer a primeira da lista | Cada hora tem **uma** pessoa: é o que a barra das 24 horas do Figma mostra, e a regra fica fácil de entender. Para reorganizar, desliga-se uma faixa, edita-se e liga-se de novo. **Muda o que o plano anterior assumia** |
| Faixa **desligada** não vale e não entra na cobertura, mas continua salva | Apagar ao desligar | É a chave do Figma: dá para desligar sem perder a configuração |
| O mesmo contato pode ter **mais de uma faixa** (ex.: 8:00 às 13:00 e 20:00 às 22:00) | Uma faixa por contato | Mais flexível, sem custo extra |
| Fora de todas as faixas ligadas, liga para **o primeiro da lista**, e a barra mostra o buraco | Escolher um padrão; não ligar | É o comportamento de hoje, então nada quebra. A barra deixa claro quando há buraco. Escolher o padrão fica no backlog |
| Ícone do período pelo **início da faixa**: sol das 6h às 17h, pôr do sol das 18h às 22h, lua das 23h às 5h | Escolher o ícone na mão | Reproduz o Figma (8h e 13h sol, 18h pôr do sol, 23h e 4h lua), sem mais um campo no formulário |
| Faixa de um contato **removido** é ignorada na escolha e escondida na lista, e **apagada pelo app quando a rede muda** (um ouvinte em `app.dart`) | Apagar ao abrir a tela de cobertura | Apagar ao abrir a tela poderia **perder todas as faixas** se a leitura dos contatos falhasse (rede vazia por erro, e não por escolha). O ouvinte só reage a uma mudança de verdade: leitura que falha não avisa ninguém. Mantém os controladores independentes |
| Armazenamento seguro, mesmo padrão dos contatos | `shared_preferences` (pacote novo) | Nenhum pacote novo. As faixas guardam só o id do contato e as horas, sem telefone |
| Relógio **injetável** (`DateTime Function()`) | `DateTime.now()` dentro da regra | Os testes escolhem a hora. Sem isso, não dá para testar "às 23h" |
| O contato é escolhido **uma vez**, no começo do alerta | Reavaliar durante o alerta | Evita ligar para uma pessoa diferente da mostrada na tela se a hora virar |
| Sem pacote novo nesta fase | — | Tudo se resolve com Flutter e o que já está no projeto |

## 8. Riscos e plano B
| Risco | Impacto | Plano B |
|---|---|---|
| Prazo da mostra (12/11/2026): a fase cresceu com o formulário e a barra | Faltam a Fase 12 (APK e roteiro, obrigatória) e a Fase 11 | Meta de 1,5 a 2 dias. Se apertar: entregar os passos 1 a 3 e a lista simples (sem a barra das 24 horas e sem editar: só adicionar e remover) |
| Faixa que atravessa a meia-noite com erro de borda | Liga para a pessoa errada de madrugada | Testes nas bordas: 22:59, 23:00, 3:59, 4:00 e 0:00, e o cruzamento entre uma faixa de madrugada e uma da manhã |
| O horário do emulador não bate com o seu | A demonstração parece errada | A regra usa a hora do aparelho. A frase "quem seria ligado agora" mostra o efeito; para a apresentação, criar uma faixa que cubra a hora atual |
| Cruzamento recusado atrapalha quem quer reorganizar | Frustração ao mudar horários | A mensagem diz com qual faixa cruza, e a chave permite desligar a outra antes de editar |
| Faixas de contatos que a usuária removeu | Ligar para quem não existe | Faixa órfã é ignorada na escolha, e apagada ao abrir a tela |
| Relógio mudando durante o alerta | Contato diferente do mostrado | O contato é escolhido **uma vez**, no começo do alerta |
| Barra proporcional estreita demais para faixas curtas | Trecho invisível | Largura mínima do trecho e a lista logo abaixo mostrando todas as faixas |

## 9. Critérios de pronto
- [ ] A regra escolhe o contato certo, incluindo faixas que atravessam a meia-noite e as bordas
- [ ] Faixas desligadas não valem, e faixas que se cruzam são recusadas com explicação
- [ ] Sem faixa ligada que cubra a hora, liga para o primeiro da lista
- [ ] A usuária adiciona, edita, liga, desliga e remove faixas, e elas ficam salvas ao reabrir o app
- [ ] A tela mostra o cartão "Cobertura das 24 horas" (com os buracos, quando houver), os ícones do período e "quem seria ligado agora"
- [ ] O Perigo liga para o contato da faixa da hora atual (conferido por teste com relógio falso)
- [ ] Faixa de contato removido é ignorada e não quebra nada
- [ ] Início igual ao fim e rede vazia são tratados com explicação
- [ ] `flutter analyze` sem avisos e testes passando
- [ ] Testado no emulador
- [ ] Backlog atualizado e commit feito

## 10. Como testar
`flutter run -d emulator-5554`: cadastrar 2 contatos de teste → Configurações → Horário de cobertura → criar uma faixa que cubra a hora atual para o **segundo** contato → conferir o cartão das 24 horas, o ícone e a frase "Agora, o ADA ligaria para…" → com o **Modo de demonstração ligado**, ativar o Perigo e ver "Ligando para <segundo contato>" → desligar a faixa pela chave e conferir que volta ao primeiro → tentar criar uma faixa que cruza com outra e ver a recusa. `flutter analyze` e `flutter test`.

## 11. Perguntas em aberto
1. **Dias da semana:** ficam fora, e as faixas valem todos os dias? (assumido)
2. **Contato padrão:** fora das faixas, liga para o **primeiro da lista** (assumido), ou você quer escolher um?
3. **Faixas que se cruzam:** o plano agora **recusa** o cruzamento entre faixas ligadas (assumido, e diferente da primeira versão do plano). Pode ser assim?
4. **Hora:** usar a do celular (assumido).
5. **Remover uma faixa:** botão **"Remover faixa"** dentro da tela de edição, com confirmação (assumido). Prefere deslizar o cartão ou ter um X no cartão?
6. **Cobertura parcial:** quando houver buracos, o cartão diz algo como "Cobertura de 20 horas" e lista os buracos, em vez de "Cobertura das 24 horas" (assumido). Pode ser?

---

## Retrospectiva (preencher ao concluir)

**O que aprendi:**
- <...>

**O que mudou em relação ao plano:**
- <...>

**Dívidas técnicas e novos itens para o backlog:**
- <...>
