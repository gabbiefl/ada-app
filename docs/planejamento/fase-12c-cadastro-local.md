# Fase 12C — Cadastro local (como podemos te chamar?)

> **Status:** 📝 plano aguardando aprovação
> **Itens do backlog:** F3-13 (login/cadastro). Decisão: **sem conta e sem servidor**, só um cadastro local do nome.

## 1. Objetivo
A usuária diz **como quer ser chamada** (opcional). O nome fica **só no celular**, cifrado, e a Home passa a cumprimentá-la por ele. Hoje a Home diz "Olá, Gabriela" **fixo no código**, para qualquer pessoa.

## 2. Resultado esperado
- Depois do onboarding (na primeira vez), uma tela **"Como podemos te chamar?"**, com um campo de nome e dois botões: **Continuar** e **Pular**.
- A Home mostra **"Olá, *nome*"**. Sem nome (pulou), mostra só **"Olá!"**.
- Em **Configurações**, um item para **editar o nome** (ou adicionar, se pulou).
- **"Apagar meus dados"** apaga o nome, e o app volta a perguntar.
- O nome fica no armazenamento seguro, como os outros dados, e entra no documento de privacidade.

## 3. Fluxo
```
Splash ─► (nunca viu o onboarding?) ─► Onboarding ─► Nome ─► Home
      └─► (já viu, mas nunca foi perguntado o nome?) ─► Nome ─► Home
      └─► (já viu tudo) ─► Home
```
"Perguntado" é lembrado mesmo se ela **pular**, para a tela não voltar toda vez. Guardamos o nome vazio como "já perguntei, ela não quis informar".

## 4. Conceitos que vamos aprender
- Formulário simples com `TextFormField` e validação (já usado no cadastro de contato)
- Dado pessoal mínimo: guardar, mostrar, editar e apagar (LGPD)
- Um repositório novo no mesmo padrão (contrato + cofre + memória)
- Estado derivado: a Home reage ao nome sem guardar cópia

## 5. Escopo
**Dentro:** a tela do nome, o repositório e o controlador, a saudação na Home, editar em Configurações, apagar com "Apagar meus dados", testes, acessibilidade, documentos.

**Fora:** foto, sobrenome, e-mail, telefone da usuária, PIN, qualquer conta ou servidor.

## 6. Decisões técnicas
| Decisão | Alternativas | Motivo |
|---|---|---|
| **Só o primeiro nome (ou apelido)**, até 30 letras, opcional | Nome completo | Menos dado pessoal (minimização). Serve só para a saudação |
| Guardar no **cofre cifrado** (`ada_profile_name`) | Preferências comuns | É um dado pessoal, então segue o padrão dos outros |
| **Vazio = "já perguntei"** | Uma segunda chave | Uma chave só e um estado a menos |
| **Pular** sempre disponível | Obrigar | O nome não é necessário para pedir ajuda |
| Saudação sem nome = "Olá!" | Manter um nome padrão | Não inventar uma identidade |
| Reaproveitar o formulário e o estilo do cadastro de contato | Desenho novo | Não há desenho no Figma; a usuária confere no emulador |

## 7. Passos
| # | Passo | Tamanho |
|---|---|---|
| 1 | Repositório e controlador do perfil (nome), com testes | P |
| 2 | Tela "Como podemos te chamar?" e a rota | M |
| 3 | Ligar o fluxo (splash → onboarding → nome → Home) e a saudação na Home | M |
| 4 | Editar o nome em Configurações e apagar em "Apagar meus dados" | P |
| 5 | Testes dos fluxos e da acessibilidade, privacidade, backlog e compilar para Android | M |

**Impacto nos testes:** vários testes procuram o texto "Olá, Gabriela". Eles passarão a injetar um perfil de teste (como já fazemos com os repositórios) e a procurar o nome combinado.

## 8. Riscos e plano B
| Risco | Plano B |
|---|---|
| Prazo (mostra em 12/11) | Cortar "editar em Configurações" e deixar só a tela inicial + saudação |
| Ler o nome falhar | A Home mostra "Olá!" e o app segue |
| A tela do nome atrasar quem precisa de ajuda | Só aparece uma vez e tem "Pular" |
| Nome aparecendo para quem olha o celular | É a Home do próprio app; o nome é opcional e dá para apagar |

## 9. Critérios de pronto
- [ ] Tela do nome após o onboarding, com Continuar e Pular
- [ ] Home com "Olá, nome" (ou "Olá!" sem nome)
- [ ] Editar o nome em Configurações
- [ ] "Apagar meus dados" apaga o nome e a pergunta volta
- [ ] Falha de leitura ou gravação não trava o app
- [ ] Auditoria de acessibilidade das telas novas, `flutter analyze` limpo, testes passando e compilado para Android
- [ ] Privacidade, backlog e README atualizados
- [ ] Visto no emulador; commits pela usuária

## 10. Perguntas em aberto (com o que assumi)
1. Só o **primeiro nome**, opcional (assumido)?
2. O texto da tela: **"Como podemos te chamar?"** e, embaixo, "Só para te cumprimentar. O nome fica só neste celular." (assumido)?
3. Sem nome, a Home diz **"Olá!"** (assumido)?
4. Existe desenho no Figma? Se não, derivo do cadastro de contato (assumido).

---

## Retrospectiva

**O que aprendi:**
- (preencha com as suas palavras)
