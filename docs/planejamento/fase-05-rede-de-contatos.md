# Fase 5 — Rede de contatos

> **Status:** 🔄 em execução (plano aprovado)
> **Itens do backlog:** F5-01 a F5-05 (e F3-12, a rede cheia, que depende do limite)

## 1. Objetivo
Transformar as telas estáticas de contatos em funcionalidade real: cadastrar, editar e remover pessoas de confiança (até 5), com validação e dados que sobrevivem ao fechar o app.

## 2. Resultado esperado
- A Rede mostra os contatos cadastrados de verdade, com o contador (`2/5`) e os espaços vazios calculados.
- "Adicionar contato" abre o formulário; ao salvar, o contato aparece na lista.
- Nome e telefone são validados, com mensagem de erro clara em cada campo.
- Tocar no "x" remove (com confirmação); tocar no card abre a edição.
- Com 5 contatos, o botão de adicionar some e aparece o aviso de limite (F3-12).
- Fechar e abrir o app mantém os contatos.

## 3. Conceitos que vamos aprender
- Model em Dart (classe imutável, `copyWith`, `toJson`/`fromJson`)
- Listas e regras de negócio isoladas e testáveis (limite de 5, telefone duplicado)
- `Form`, `TextFormField`, `GlobalKey<FormState>`, `validator` e `TextEditingController`
- Reaproveitar o padrão da Fase 4: `ChangeNotifier` + `provider` para a lista
- `async`/`await` e `Future` (ler e gravar no armazenamento)
- Persistência local e separar "o que guardar" de "onde guardar" (repositório)

## 4. Escopo
**Dentro:**
- `Contact` (model) e `ContactsController` (lista, adicionar, editar, remover, limite)
- Validação de nome e telefone (função pura, com testes)
- Formulário ligado ao controlador (cadastro e edição pela mesma tela)
- Lista da Rede lendo o controlador; remoção com confirmação
- Estado de rede cheia (5/5)
- Persistência local dos contatos
- Testes unitários e de widget

**Fora (vai para o backlog):**
- "Escolher da agenda": exige permissão de contatos e um pacote novo, e a Fase 0 (P3) manda não ler a agenda inteira. O botão fica visível, mas sem ação, até decidirmos (nova ideia no backlog)
- Mensagens e preferências (Fase 6)
- Regra de contato por horário (Fase 10)
- Ligação, SMS e WhatsApp (Fase 9)
- Login/cadastro da usuária (F3-13)

## 5. Pré-requisitos
- Fase 4 concluída (controlador + provider já em uso)
- **Confirmação do pacote de armazenamento** (ver decisão abaixo): nenhum pacote entra sem a sua aprovação

## 6. Passos
| # | Passo | Tamanho | O que a usuária aprende |
|---|---|---|---|
| 1 ✅ | `Contact` (model) com `copyWith`, `toJson`/`fromJson` e teste | M | Classes, imutabilidade, JSON |
| 2 ✅ | Validação de nome e telefone (funções puras) e testes | P | Regras testáveis, `RegExp` |
| 3 ✅ | `ContactsController` em memória: adicionar, editar, remover, limite de 5, telefone repetido; testes | M | Reaproveitar `ChangeNotifier`, regras de negócio |
| 4 ✅ | Fornecer o controlador no app e a Rede ler a lista dele (contador e espaços vazios dinâmicos) | M | `context.watch` com lista |
| 5 ✅ | Formulário de verdade: `Form` + `validator`, salvar chama o controlador e volta | G | Formulários e validação |
| 6 | Remover (com confirmação) e editar (toque no card abre o formulário preenchido) | M | Diálogo, passar dado entre telas |
| 7 | Rede cheia (5/5): esconde "Adicionar" e mostra o aviso (F3-12) | P | Estado derivado da lista |
| 8 | Persistência: repositório + armazenamento escolhido; o controlador carrega ao iniciar e grava a cada mudança | G | `async`/`await`, `Future`, repositório |
| 9 | Testes de fluxo (cadastrar → aparece → remover), `flutter analyze`, retrospectiva, resumos e backlog | M | Fechar a fase |

Ordem pensada para sempre ter algo funcionando: primeiro tudo em memória (passos 1 a 7), e só então a persistência (passo 8). Se o prazo apertar, o app já funciona na demonstração, só sem guardar ao fechar.

## 7. Decisões técnicas
| Decisão | Alternativas consideradas | Motivo |
|---|---|---|
| Contato = nome + telefone (e `id`) | Guardar também e-mail, foto | Minimização de dados (P3 da Fase 0) |
| Telefone guardado só com dígitos, exibido formatado | Guardar com máscara | Fica fácil validar, comparar duplicados e usar em `tel:` e `wa.me` na Fase 9 |
| `ContactsController` com `ChangeNotifier` + `provider` | Riverpod; `setState` na tela | Mesmo padrão da Fase 4; a lista é usada por Rede, formulário e (depois) alertas |
| Repositório (classe que lê e grava) separado do controlador | Controlador gravando direto | Trocar o armazenamento sem mexer na lógica, e testar o controlador com um repositório falso |
| **Armazenamento: `flutter_secure_storage`** (aprovado na base da Fase 0 por guardar dados de terceiros criptografados) | `shared_preferences` (mais simples, sem criptografia); `sqflite`/`drift` (exagero para 5 itens) | Telefones de terceiros são dado pessoal sensível (LGPD). **Pede a sua confirmação** |
| Validar telefone BR de forma simples (10 ou 11 dígitos, DDD) | Pacote de validação | Regra pequena; evita pacote novo |
| "Escolher da agenda" fora da fase | Implementar com pacote de contatos | Pacote + permissão + risco de ler a agenda inteira; o cadastro manual atende RF01 |

## 8. Riscos e plano B
| Risco | Impacto | Plano B |
|---|---|---|
| `flutter_secure_storage` no Chrome não é seguro de verdade e pode se comportar diferente do Android | Dá para testar o fluxo, mas não a criptografia; só o Android real valida | Usar o Chrome para o fluxo; confirmar a criptografia quando o Android for configurado (F1-04, antes da Fase 7). Se der problema, `shared_preferences` por trás do mesmo repositório |
| Prazo da mostra (23/11/2026) | Passo 8 e 9 não cabem | Passos 1 a 7 já entregam o cadastro funcionando; persistência e testes de fluxo entram depois |
| Não há design da edição de contato nem do aviso de limite no Figma | Visual improvisado | Reaproveitar o formulário existente (título "Editar contato") e derivar o aviso do `InfoBox` já existente; mostrar a você antes de fechar |
| Contato repetido ou telefone inválido | Dado ruim na rede de emergência | Validação + bloqueio de telefone duplicado, com testes |

## 9. Critérios de pronto
- [ ] Cadastrar, editar e remover contatos funcionando na interface
- [ ] Limite de 5 respeitado (botão some e há aviso)
- [ ] Nome e telefone validados com mensagens claras
- [ ] Contatos continuam ao fechar e abrir o app
- [ ] Nenhum telefone em `print`/`debugPrint` (P6 da Fase 0)
- [ ] Testes unitários (model, validação, controlador) e de fluxo passando
- [ ] `flutter analyze` sem avisos
- [ ] Testado no Chrome
- [ ] Backlog atualizado e commit feito

## 10. Como testar
`flutter run -d chrome`: cadastrar 5 contatos, ver o limite, editar, remover, fechar a aba e reabrir. `flutter analyze` e `flutter test`.

## 11. Perguntas em aberto
- **Armazenamento** (`flutter_secure_storage` x `shared_preferences`): decidir e confirmar o pacote antes do passo 8.
- ✅ **Editar:** mesmo formulário, título "Editar contato" e **sem** o card "Escolher da agenda" (decisão da usuária).
- ✅ **"Escolher da agenda":** fica para depois (vai para o backlog como ideia).
- ✅ **Remover:** modal simples de confirmação.
- ✅ **Lista inicial:** vazia (precisa de um estado vazio na Rede).

---

## Retrospectiva (preencher ao concluir)

**O que aprendi:**
- <...>

**O que mudou em relação ao plano:**
- <...>

**Dívidas técnicas e novos itens para o backlog:**
- <...>
