# Fase 12B — Segurança pública (190 e 180) na Home

> **Status:** ✅ concluída no código (pendente: ver no emulador e ligar de verdade em celular real)
> **Itens do backlog:** F12-04

## 1. Objetivo
A usuária liga direto para a **Polícia Militar (190)** ou para a **Central de Atendimento à Mulher (180)** a partir da Home, sem acionar a sua rede de contatos.

## 2. Decisões (da usuária, 09/11/2026)
- Seção **abaixo dos cartões de modo**, com título ("Segurança pública") e subtítulo.
- **Ligação direta** (não só abrir o discador), **com confirmação**.
- Liga **só para o contato tocado**: não ativa modo, não manda SMS, não avisa a rede.

## 3. Como funciona
| Etapa | O que acontece |
|---|---|
| Toque no cartão | Diálogo "Ligar para o 190?" com o que o serviço atende e a frase de que a rede não é avisada |
| Confirmar | `AlertActions.call('190')` (mesma ligação direta do alerta; pede a permissão de ligar se faltar) |
| Falhou (sem permissão ou sem chip) | Plano B: abre o discador com o número digitado |
| Nem o discador abriu | Aviso: "Não foi possível ligar. Disque 190 pelo telefone." |

## 4. Decisões técnicas
| Decisão | Motivo |
|---|---|
| Números de **serviço** (até 3 dígitos) não levam `+55` | `+55190` não existe. `internationalPhone('190')` devolve `190` |
| `AlertActions` virou um **provider** compartilhado | O alerta e a seção usam a mesma instância; os testes injetam a versão falsa |
| Números **fixos no código** | Não são dados da usuária: nada é guardado |
| Cartão branco com borda | Diferente dos cartões coloridos dos modos: aqui a ação é ligar para fora, não ativar o ADA |

## 5. Critérios de pronto
- [x] Seção na Home com título, subtítulo e dois cartões
- [x] Sempre confirma antes de ligar
- [x] Liga só para o serviço tocado (testado: sem SMS, modo continua Normal)
- [x] Plano B (discador) e aviso final testados
- [x] Auditoria de acessibilidade da Home passa (alvos, nomes e texto em 2x)
- [x] `flutter analyze` limpo, testes passando, compilado para Android
- [ ] Visto no emulador
- [ ] Ligação direta confirmada em celular real
- [ ] Commits feitos pela usuária

## 6. Perguntas em aberto
- Incluir também o 192 (SAMU) e o 193 (Bombeiros)? Mantido só 190 e 180, como pedido.
