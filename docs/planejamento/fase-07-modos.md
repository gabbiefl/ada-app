# Fase 7 — Modos Atenção e Perigo

> **Status:** 📝 em planejamento (aguardando aprovação)
> **Itens do backlog:** F7-01, F7-02, F7-03, F7-04 (e F3-14, parte visual da Atenção)

## 1. Objetivo
Fazer os três níveis de segurança funcionarem: tocar nos cards da Home ativa o Modo Atenção ou o Modo Perigo, a tela reage, e desativar é seguro (sem toque acidental).

## 2. Resultado esperado
- Tocar em **MODO ATENÇÃO** ativa o modo, e a Home mostra o estado de atenção.
- Tocar em **MODO PERIGO** pede uma **confirmação** e, confirmada, ativa o modo (2 toques no total, dentro da meta do RNF01).
- Com um modo ativo, tocar no símbolo central pede confirmação para **desativar** e volta ao Normal.
- Ao ativar o Perigo, o celular **vibra** (no Android).
- Regras de transição ficam em um só lugar e são testadas sem tela.

## 3. Conceitos que vamos aprender
- Máquina de estados simples: quais mudanças de modo são permitidas
- `enum` com comportamento (o modo sabe a quais modos pode ir)
- Confirmação em dois toques (`showDialog` já visto na Fase 5, agora para segurança)
- Feedback háptico com `HapticFeedback` (vem no Flutter, sem pacote)
- Injeção de dependência básica: o controlador recebe o "vibrador" de fora, como recebeu o repositório
- Estados derivados da tela (a Home desenha a partir do modo, sem guardar nada a mais)

## 4. Escopo
**Dentro:**
- Regras de transição no `ModeController` (com retorno `null`/erro, como nos outros controladores) e testes
- Toque nos dois cards da Home; confirmação para o Perigo
- Desativação por toque no símbolo, com confirmação
- Visual do estado de Atenção na Home (ver riscos: o Figma ainda não foi lido)
- Vibração ao ativar o Perigo, atrás de uma interface para ser testável
- Testes unitários e de fluxo

**Fora (vai para o backlog ou outras fases):**
- Enviar mensagem, compartilhar localização e ligar (Fases 8 e 9): na Fase 7 o modo muda, mas nada é enviado ainda
- Manter o modo ativo ao fechar o app, e notificação/serviço em segundo plano (ver pergunta 3)
- Acionamento com o celular bloqueado ou por botão físico (IDEIA-01, fora do MVP)
- Histórico de alertas (continua "Em breve")
- Som de alarme

## 5. Pré-requisitos
- Fases 4 (`ModeController`, Home reativa), 5 e 6 concluídas
- **F3-14:** ler no Figma o estado de Atenção ativo e a confirmação do Perigo (decisão da usuária, ver seção 11). O estado de Perigo ativo já foi lido e está na Home
- **Android (F1-04 e F1-05):** só para sentir a vibração; todo o resto roda no Chrome. Não bloqueia os passos 1 a 4

## 6. Passos
| # | Passo | Tamanho | O que a usuária aprende |
|---|---|---|---|
| 1 | Regras de transição no `ModeController` (o que pode ir para onde) e testes | M | Máquina de estados, enum com comportamento |
| 2 | Ligar os cards da Home ao controlador; **Atenção** ativa direto | P | Eventos de toque, `context.read` |
| 3 | **Perigo** com confirmação (diálogo) e **desativar** tocando no símbolo, também com confirmação | M | Confirmação em dois toques, `showDialog` |
| 4 | Visual do estado de Atenção na Home (símbolo, anéis, chip e frase) | M | Estado derivado, reuso do que já existe |
| 5 | Vibração ao ativar o Perigo (`HapticFeedback`) atrás de uma interface, injetada no controlador | P | Injeção de dependência, recursos do aparelho |
| 6 | Testes de fluxo, `flutter analyze`, retrospectiva, resumos e backlog | P | Fechar a fase |

## 7. Decisões técnicas
| Decisão | Alternativas consideradas | Motivo |
|---|---|---|
| Regras de transição dentro do `ModeController` | Regras nas telas | As telas só pedem; o controlador decide e devolve o motivo da recusa. Testável sem tela, como os outros controladores |
| Perigo exige confirmação; Atenção ativa direto | Os dois com confirmação; nenhum | Perigo dispara o fluxo de emergência (Fases 8 e 9), então um toque acidental custa caro. Atenção é só acompanhamento. Total de 2 toques no Perigo, dentro do RNF01 |
| Desativar sempre pede confirmação | Desativar com 1 toque | Evita encerrar um alerta por engano, que é o pior erro neste app (F7-03) |
| De Perigo não se vai direto para Atenção: é preciso desativar antes | Permitir qualquer troca | Rebaixar o alerta sem querer é arriscado. Atenção → Perigo é permitido (a situação piorou) |
| Vibração com `HapticFeedback` (já vem no Flutter) | Pacote `vibration` | Nenhum pacote novo. Basta para a demonstração; no Chrome não faz nada |
| "Vibrador" recebido de fora (interface + versão de teste) | Chamar `HapticFeedback` direto no controlador | Nos testes dá para conferir que vibrou sem depender do aparelho |
| O modo **não** é gravado no aparelho nesta fase | Gravar com repositório | Menos escopo para o prazo. Decisão em aberto, ver pergunta 3 |

## 8. Riscos e plano B
| Risco | Impacto | Plano B |
|---|---|---|
| **F3-14:** o Figma não foi lido para a Atenção ativa e a confirmação do Perigo (plano gratuito, poucas chamadas) | Visual diferente do design | Derivar da Home de Perigo já pronta, trocando cor e textos (cor, símbolo e chip da Atenção seguem as cores do tema). Confirmar com a usuária no fim |
| Prazo da mostra (12/11/2026) | A Fase 7 é a mais visível na demonstração | É a prioridade. Se apertar: passos 1 a 3 já entregam o fluxo completo; o passo 5 (vibração) é opcional |
| Vibração só aparece no Android | Não dá para ver no Chrome | Testar a lógica com o "vibrador" falso; sentir no aparelho quando o ambiente Android estiver pronto |
| Usuária fica sem saber se o alerta "foi enviado" | Falsa sensação de segurança | Deixar claro na interface e na apresentação que o envio vem nas Fases 8 e 9; nesta fase o modo só muda |
| Toque acidental no símbolo desativa o alerta | Alerta encerrado sem querer | Confirmação ao desativar (passo 3) |

## 9. Critérios de pronto
- [ ] Atenção ativa por um toque; Perigo ativa após confirmação (2 toques)
- [ ] Desativar pede confirmação e volta ao Normal
- [ ] De Perigo não se vai direto para Atenção (regra testada)
- [ ] A Home mostra os três estados com chip e frase corretos
- [ ] Vibra ao ativar o Perigo (conferido com o vibrador falso; no aparelho quando possível)
- [ ] Nenhum dado pessoal em `print`/`debugPrint`
- [ ] Testes unitários e de fluxo passando
- [ ] `flutter analyze` sem avisos
- [ ] Testado no Chrome
- [ ] Backlog atualizado e commit feito

## 10. Como testar
`flutter run -d chrome`: na Home, tocar em MODO ATENÇÃO; tocar em MODO PERIGO e confirmar; tocar no símbolo e confirmar a desativação; tentar cancelar cada confirmação. `flutter analyze` e `flutter test`. A vibração: num emulador ou celular Android.

## 11. Perguntas em aberto
1. **Figma (F3-14):** você quer gastar uma chamada para ler a Atenção ativa e a confirmação do Perigo, ou seguimos com o plano B (derivar da tela de Perigo) e você confere o resultado?
2. **Atenção → Perigo:** podemos permitir a subida direta, mas bloquear a descida de Perigo para Atenção (precisa desativar antes)? É o que o plano assume.
3. **Fechar o app com o alerta ativo:** o modo deve voltar a Normal (assumido, mais simples) ou permanecer ativo ao reabrir? Permanecer exige gravar o modo, e faz mais sentido junto com o envio (Fase 9).
4. **Confirmação do Perigo:** diálogo simples ("Ativar Modo Perigo?" com Cancelar/Ativar), como o de remover contato? É o que o plano assume.

---

## Retrospectiva (preencher ao concluir)

**O que aprendi:**
- <...>

**O que mudou em relação ao plano:**
- <...>

**Dívidas técnicas e novos itens para o backlog:**
- <...>
