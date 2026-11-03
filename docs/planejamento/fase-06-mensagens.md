# Fase 6 — Mensagens e configurações

> **Status:** 📝 em planejamento (aguardando aprovação)
> **Itens do backlog:** F6-01, F6-02, F6-03

## 1. Objetivo
Fazer as três mensagens de emergência (Perigo, Atenção e "Cheguei bem") existirem de verdade: ter um texto padrão, poder ser editadas pela usuária e continuar salvas ao fechar o app.

## 2. Resultado esperado
- A tela **Mensagens** mostra o texto atual de cada uma das três mensagens.
- "Editar" abre a edição **da mensagem tocada** (hoje as três abrem o mesmo texto).
- Na edição, o contador funciona, "Resetar para padrão" volta ao texto original **daquela** mensagem e "Salvar mensagem" grava e volta.
- Texto vazio ou com mais de 200 letras não é salvo, e aparece uma explicação.
- Fechar e abrir o app mantém as mensagens editadas.

## 3. Conceitos que vamos aprender
- `enum` com propriedades (cada tipo de mensagem carrega o título e o texto padrão)
- `Map<MessageKind, String>`: um dado por chave
- Parâmetro de rota (`/settings/messages/edit/:kind`) e converter texto em `enum`
- Reaproveitar o padrão da Fase 5 (controlador + repositório + provider) em outro dado
- Template de texto: a mensagem guardada é um modelo; o link de localização será acrescentado na hora de enviar (Fases 8 e 9)

## 4. Escopo
**Dentro:**
- `MessageKind` (enum) com título e texto padrão de cada mensagem
- `MessagesController` (ler, salvar, resetar) com validação e testes
- Repositório das mensagens e persistência
- Tela Mensagens lendo o controlador; tela de edição recebendo qual mensagem editar

**Fora (vai para o backlog ou outras fases):**
- Montar a mensagem final com o link do mapa e enviar (Fases 8 e 9)
- Horário de cobertura e Histórico de alertas (Fases 10 e 7; continuam como "Em breve")
- Variáveis dentro do texto, como `{nome}` ou `{local}` (ideia, se sobrar tempo)
- Outras preferências: hoje não existe nenhuma além das mensagens, então F6-03 se cumpre guardando as mensagens

## 5. Pré-requisitos
- Fase 5 concluída (padrão de controlador + repositório já existe)
- Decisão sobre o armazenamento (ver seção 11): **nenhum pacote novo** se usarmos o que já temos

## 6. Passos
| # | Passo | Tamanho | O que a usuária aprende |
|---|---|---|---|
| 1 | `MessageKind` (enum com título e texto padrão) e `MessagesController` em memória: ler, salvar, resetar, validar; testes | M | Enum com propriedades, `Map` |
| 2 | Fornecer o controlador no app; a tela Mensagens mostra os textos atuais | P | Reuso do `provider` |
| 3 | Rota de edição com a mensagem escolhida; a edição carrega o texto, valida, salva e reseta o padrão **da mensagem certa** | M | Parâmetro de rota, enum a partir de texto |
| 4 | Persistência: repositório e gravação a cada mudança | M | Reuso do padrão repositório |
| 5 | Testes de fluxo, `flutter analyze`, retrospectiva, resumos e backlog | P | Fechar a fase |

## 7. Decisões técnicas
| Decisão | Alternativas consideradas | Motivo |
|---|---|---|
| Três mensagens identificadas por um `enum` (`MessageKind`) | Três variáveis soltas; strings | O compilador garante os três tipos; o título e o padrão ficam junto do tipo |
| Guardar só os textos **editados**; sem edição vale o padrão | Guardar sempre os três textos | "Resetar" vira apenas apagar a edição; mudar o padrão no app não é bloqueado por dado antigo |
| `MessagesController` + repositório + `provider` | Estado dentro da tela | Mesmo padrão da Fase 5; as mensagens serão lidas também pelo Modo Perigo (Fase 7) |
| Mensagem = modelo de texto; o link de localização entra no envio | Colocar o link no texto salvo | A localização muda a cada alerta; não pode ficar gravada na mensagem |
| Limite de 200 letras (já está no design) | Sem limite | SMS e WhatsApp ficam curtos e o design já prevê o contador |
| **Armazenamento: reaproveitar o `flutter_secure_storage`** (recomendado) | `shared_preferences` (sugerido na Fase 0 para mensagens) | Nenhum pacote novo. A usuária pode escrever dados pessoais no texto (ex.: "estou na casa da…"), então proteger é mais seguro. O repositório isola a escolha: trocar depois é simples |

## 8. Riscos e plano B
| Risco | Impacto | Plano B |
|---|---|---|
| Prazo da mostra (12/11/2026) | A fase consome tempo das Fases 7 a 9, que são o coração do app | A fase é curta e reaproveita padrões. Se apertar: entregar os passos 1 a 3 (editar em memória) e deixar a persistência por último |
| A edição dos Modos Atenção e "Cheguei bem" não foi lida no Figma | Visual diferente do esperado | Usar a tela de edição existente (a mesma estrutura); só muda o texto. Confirmar com a usuária |
| Texto com dado pessoal fica no aparelho | Privacidade | Armazenamento seguro; sem logs do texto (P6 da Fase 0) |

## 9. Critérios de pronto
- [ ] As três mensagens aparecem com o texto atual e abrem a edição correta
- [ ] Editar, salvar e resetar funcionam para cada mensagem
- [ ] Texto vazio ou acima de 200 letras é recusado com explicação
- [ ] As mensagens continuam ao fechar e abrir o app
- [ ] Nenhum texto de mensagem em `print`/`debugPrint`
- [ ] Testes unitários (controlador, repositório) e de fluxo passando
- [ ] `flutter analyze` sem avisos
- [ ] Testado no Chrome
- [ ] Backlog atualizado e commit feito

## 10. Como testar
`flutter run -d chrome`: Configurações → Mensagens → Editar cada uma, salvar, resetar, tentar salvar vazio, reiniciar com `R`. `flutter analyze` e `flutter test`.

## 11. Perguntas em aberto
1. **Armazenamento:** reaproveitar o `flutter_secure_storage` (sem pacote novo, recomendado) ou usar o `shared_preferences` (mais simples, sem criptografia, pacote novo)?
2. **Texto da tela Configurações:** o subtítulo "Cadastre a sua rede de confiança." parece cópia da tela Rede (nota antiga no código). Troco por algo como "Ajuste o app do seu jeito."?
3. **Tela de edição:** o título deve mostrar **qual** mensagem está sendo editada (ex.: "Mensagem — Modo perigo")? Hoje ele só diz "Mensagens".
4. **Salvar:** ao salvar com sucesso, só voltar para a lista ou mostrar também um aviso rápido ("Mensagem salva")?

---

## Retrospectiva (preencher ao concluir)

**O que aprendi:**
- <...>

**O que mudou em relação ao plano:**
- <...>

**Dívidas técnicas e novos itens para o backlog:**
- <...>
