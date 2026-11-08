# Fase 11 — Qualidade, privacidade e acessibilidade (versão enxuta)

> **Status:** ✅ concluída no código (pendente: ver as telas e o texto grande no emulador)
> **Itens do backlog:** F11-02, F11-03, F11-04, F11-05 (e F9-06). O F11-01 já está atendido (ver seção 4).

## 1. Objetivo
Deixar o app confiável para a mostra: a usuária consegue **apagar todos os seus dados**, o que o app guarda e faz com eles está **revisado e documentado**, e as telas passam numa **auditoria de acessibilidade** (alvos de toque, nomes para o leitor de tela, contraste e texto grande).

## 2. Resultado esperado
- Em **Configurações** existe **"Apagar meus dados"**. Com confirmação, apaga contatos, faixas de horário e mensagens editadas (as mensagens voltam ao texto padrão), desfaz qualquer alerta em andamento e volta o app ao estado de recém-instalado.
- Um documento **[docs/privacidade-e-dados.md](../privacidade-e-dados.md)** explica, em linguagem simples: o que o app guarda, onde, o que **nunca** guarda (localização), quais permissões pede e para quê, como apagar tudo e os limites (WhatsApp e SMS ficam no histórico do celular).
- A decisão sobre o **backup** do Android está explicada no documento (não foi alterado: o que iria para a nuvem é texto cifrado).
- O texto do cadastro de contato deixa de prometer um aviso por WhatsApp que não existe (F9-06).
- A barra inferior e os ícones têm **nome para o leitor de tela**; toques pequenos ganham área mínima de 48; os ícones claros demais ganham contraste.
- Testes automáticos de acessibilidade nas telas principais, incluindo **texto em tamanho duplo sem estourar a tela**.

## 3. Conceitos que vamos aprender
- Privacidade por padrão: guardar pouco, proteger o que guarda e permitir apagar (LGPD)
- Backup do Android (`allowBackup`) e por que ele importa para dados sensíveis
- Acessibilidade no Flutter: `Semantics`, `tooltip`, alvo de toque de 48 dp e contraste
- **Guidelines de acessibilidade nos testes** (`meetsGuideline`, `androidTapTargetGuideline`, `labeledTapTargetGuideline`, `textContrastGuideline`)
- Texto ampliado (`TextScaler`) e como detectar tela que estoura (`overflow`)
- Limpar estado em memória **e** armazenamento de forma consistente

## 4. Escopo
**Dentro:**
- "Apagar meus dados" (F11-05, RF10): `clear` nos três controladores, tela de confirmação e testes
- Revisão de privacidade (F11-04) e o documento `privacidade-e-dados.md`
- Desligar o backup automático do Android
- Corrigir o texto do cadastro de contato (F9-06)
- Auditoria de acessibilidade (F11-02) com testes automáticos e as correções que ela achar
- F11-03 (erros e estados vazios): já existem rede vazia, sem contatos, sem localização, sem permissão, alerta sem contatos e cobertura sem faixas. Aqui só se confere e se anota o que faltar

**F11-01 (testes dos fluxos principais):** já atendido. Há mais de 430 testes (unitários, de widget e de fluxo no app inteiro). Nesta fase só entram os testes novos das próprias correções.

**Fora (vai para o backlog):**
- **Avisar na tela quando uma gravação falha** (hoje o app continua com os dados em memória e a falha passa em silêncio; é rara)
- Implementar de verdade o aviso por WhatsApp ao contato cadastrado
- Auditoria com leitor de tela real (TalkBack) e teste com pessoas
- Modo escuro, idiomas além do português
- Revisão jurídica formal de LGPD (a fase é uma revisão técnica)

## 5. Pré-requisitos
- Fases 5 a 10 concluídas (todos os dados que o app guarda já existem)
- Nenhum pacote novo

## 6. Passos
| # | Passo | Tamanho | O que a usuária aprende |
|---|---|---|---|
| 1 ✅ | **Apagar meus dados**: `clear` em contatos, mensagens e faixas, desfazer alerta e modo, item em Configurações com confirmação, testes | M | Limpar estado e armazenamento juntos |
| 2 ✅ | **Revisão de privacidade**: backup desligado, texto do cadastro (F9-06), checklist e `docs/privacidade-e-dados.md` | P | Privacidade por padrão, LGPD prática |
| 3 ✅ | **Auditoria de acessibilidade automática**: testes com as guidelines do Flutter e texto em 2x nas telas principais; lista dos achados | M | Guidelines nos testes, `TextScaler` |
| 4 ✅ | **Correções**: nomes na barra inferior e nas setas, áreas de toque pequenas, contraste dos ícones claros | M | `Semantics`, 48 dp, contraste |
| 5 ✅ | Fechamento: `flutter analyze`, testes, retrospectiva, resumos e backlog | P | Fechar a fase |

A ordem coloca **apagar dados e privacidade primeiro**: são requisitos (RF10) e ficam melhor para defender na banca. A acessibilidade vem depois, e o passo 4 é o que se corta se o prazo apertar.

## 6.1 Achados da auditoria (passo 3)
A auditoria roda em [test/accessibility/](../../test/accessibility/): `accessibility_test.dart` (alvo de toque, nome e texto em 2x, em 12 telas, num celular de 393 px) e `contrast_test.dart` (contraste exato dos pares de cores). Cada achado foi registrado nos testes como "problema conhecido" (o teste era pulado) e **todos foram corrigidos no passo 4**: a lista está vazia e nenhum teste da auditoria é pulado.

| ID | Achado | Onde | Correção |
|---|---|---|---|
| AC-1 | A **barra inferior** só tem ícones: o leitor de tela não diz "Início", "Rede", "Mapa" nem "Ajustes" | Todas as telas com a barra (7) | ✅ Cada item tem nome ("Início", "Rede", "Mapa", "Configurações") e o estado de selecionado |
| AC-2 | O **símbolo central** da Home é tocável (gesto) mesmo no modo Normal, sem nome e sem ação | Home | ✅ O símbolo só é tocável quando há alerta ativo |
| AC-3 | A **seta de voltar** não tem nome (falta o `tooltip`) | Mensagens e Editar mensagem | ✅ `tooltip: 'Voltar'` nas duas setas |
| AC-4 | Textos tocáveis menores que 48 x 48 | "Editar" (Mensagens) e "Resetar para padrão" | ✅ Área de toque de 48 x 48; o "Editar" diz qual mensagem edita ("Editar Modo perigo") |
| AC-5 | Com **texto em 2x** a tela estoura | Cartões dos modos (Início), cartões de contato e "Adicionar contato" (Rede), título "Novo contato" | ✅ Os cartões e o título passaram a quebrar linha e a crescer, em vez de estourar |
| AC-6 | **Ícones claros** (`#D9D9D9`) sobre o fundo: contraste **1,35 e 1,41** (mínimo 3) | Setas de voltar, "+", setinhas dos menus | ✅ Novo `AppColors.iconMuted` (`#7C8389`, contraste 3,5 a 3,8) nos ícones; o cinza claro ficou só para bordas |
| AC-7 | **Azul das caixas informativas** sobre o tom azul de 14%: **4,25** (mínimo 4,5) | Mapa e cadastro de contato | ✅ `AppColors.info` de `#2F6BB8` para `#2A62AB` (contraste 4,8) |

**Verificado e aprovado:** os outros 18 pares de cores (texto cinza, vermelho, marrom, branco sobre o vermelho do Perigo, azul-marinho sobre o amarelo da Atenção etc.) passam o contraste do WCAG AA. Os alvos de toque dos demais botões, cartões e chaves passam. A tela **Mapa**, **Configurações**, **Cobertura** e as de **Alerta** aguentam o texto em 2x (a de Alerta só ficou mascarada pelo estouro da Home, de onde é aberta).

**Observação para a usuária (não é um achado):** o texto do ADA usa a fonte **fina** (peso 300) nos parágrafos. A cor passa o contraste, mas traços finos cansam mais a leitura. É uma escolha do design do Figma; fica a critério de vocês.

**A guideline de contraste do Flutter foi trocada pelo cálculo exato:** ela mede por captura de tela e acusava 1,9 para uma cor que calculada tem 4,6, por causa do texto fino. Os testes de fonte usam a `Nunito` de verdade (sem isso o Flutter desenha com uma fonte de quadrados e cria estouros que não existem).

## 7. Decisões técnicas
| Decisão | Alternativas consideradas | Motivo |
|---|---|---|
| "Apagar meus dados" limpa **os controladores** (que gravam o vazio no armazenamento) | Só chamar `deleteAll()` do armazenamento seguro | Se só o armazenamento fosse apagado, a tela continuaria mostrando os dados até fechar o app. Limpando pelos controladores, memória e armazenamento ficam iguais |
| Apaga contatos, faixas e mensagens editadas; **desfaz alerta e modo** | Apagar também o Modo de demonstração | O Modo de demonstração não é gravado. Um alerta em andamento seria enviado a contatos que acabaram de ser apagados, então é desfeito |
| Confirmação com **diálogo claro** ("Isso não pode ser desfeito") | Exigir digitar "APAGAR" | O diálogo já protege contra o toque acidental sem atrapalhar a demonstração. Digitar fica no backlog se a banca pedir mais rigor |
| **Não alterar o backup** do Android (decidido pela usuária: "se não for necessário, não precisa") | Desligar com `android:allowBackup="false"` | Conferido no pacote: os dados são gravados **cifrados**, então um backup levaria só texto cifrado, sem a chave (que fica no aparelho). O efeito prático seria o app abrir vazio em outro celular, sem quebrar. A decisão está em `docs/privacidade-e-dados.md`, com a opção de desligar se a banca pedir |
| O texto do cadastro de contato passa a dizer o que **de fato** acontece (SMS e ligação em caso de alerta) | Implementar o aviso por WhatsApp | Implementar é maior que o prazo. Corrigir o texto elimina a promessa falsa agora |
| Auditoria com **as guidelines do próprio Flutter** nos testes | Revisão só visual; ferramentas externas | Roda junto dos testes, avisa se alguém piorar a acessibilidade no futuro e não precisa de pacote novo |
| Ícones claros demais ficam **mais escuros, sem mudar o desenho** | Manter o cinza do Figma | O cinza `#D9D9D9` sobre branco tem contraste muito baixo (cerca de 1,4 para 1). O ajuste é só de tom |
| Nomes de leitor de tela com `Semantics` e `tooltip` | Rótulos em texto visível | A barra inferior é só de ícones por design; o nome só precisa existir para quem usa leitor de tela |
| Falha de gravação silenciosa **fica de fora** | Avisar a usuária | É rara (o armazenamento seguro do aparelho quase nunca falha) e pede uma interface nova. Vai para o backlog |

## 8. Riscos e plano B
| Risco | Impacto | Plano B |
|---|---|---|
| Prazo da mostra (12/11/2026): ainda falta a Fase 12 (APK e roteiro), obrigatória | Atrasar a entrega | A fase deve levar cerca de 1 dia. Se apertar: entregar os passos 1, 2 e 5 (apagar dados, privacidade e fechamento) e deixar a acessibilidade para depois |
| Apagar dados deixar a tela em estado estranho | Telas mostrando dados antigos | Os controladores avisam as telas ao limpar, e os testes conferem Rede, Mensagens, Cobertura e Home |
| Apagar durante um alerta em andamento | Mensagens indo para contatos apagados | O alerta é desfeito primeiro (o cancelamento já existe) |
| Desligar o backup ter efeito colateral | Nenhum esperado: o app não depende de backup | Só se aplica a quem reinstala ou troca de celular: os dados não voltam, e isso é o desejado |
| O teste de contraste automático dar falso alarme | Tempo perdido | Avaliar cada achado; o que for decoração fica registrado como aceito, com o motivo |
| Texto em 2x estourar telas com layout fixo | Telas quebradas para quem usa fonte grande | Corrigir com rolagem e `Flexible`/`Wrap`; se for muito, registrar as telas no backlog |
| Mexer em cores quebrar o visual do Figma | Design alterado | Mudar só o tom dos ícones claros, e a usuária confere no emulador |

## 9. Critérios de pronto
- [x] "Apagar meus dados" apaga contatos, faixas e mensagens editadas, desfaz o alerta e o modo, e as telas refletem isso
- [x] Depois de apagar e reabrir o app, nada volta (armazenamento vazio)
- [x] A decisão sobre o backup está documentada (sem alterar o manifesto)
- [x] O texto do cadastro de contato não promete mais o aviso por WhatsApp
- [x] `docs/privacidade-e-dados.md` existe e está de acordo com o que o app faz
- [x] Nenhum telefone, texto ou coordenada em `print`/`debugPrint`
- [x] Testes de acessibilidade (alvo de toque, nome e contraste) passando nas telas principais
- [x] As telas principais aguentam texto em 2x sem estourar
- [x] A barra inferior e as setas têm nome para o leitor de tela
- [x] `flutter analyze` sem avisos e testes passando (516)
- [ ] **Testado no emulador:** ver "Apagar meus dados", o texto grande e a barra com nomes (o emulador estava fechado)
- [x] Backlog atualizado
- [ ] Commit do fechamento (por você)

## 10. Como testar
`flutter run -d emulator-5554`: cadastrar contatos, uma faixa de horário e editar uma mensagem → Configurações → **Apagar meus dados** → conferir que Rede, Cobertura e Mensagens ficaram vazias/padrão → fechar e reabrir o app. Em Configurações do Android, ligar o **texto grande** e percorrer as telas. `flutter analyze` e `flutter test`.

## 11. Perguntas em aberto
1. **O que "Apagar meus dados" apaga:** contatos, faixas de horário e mensagens editadas (as mensagens voltam ao padrão), e desfaz o alerta e o modo. É isso (assumido)?
2. **Confirmação:** um diálogo claro (assumido), ou você quer que a usuária digite "APAGAR"?
3. **Backup do Android:** desligar (assumido). Pode ser?
4. **Texto do cadastro (F9-06):** corrigir para o que de fato acontece (assumido), por exemplo: "Combine com essa pessoa antes: em caso de alerta, ela receberá SMS e ligações do ADA." Ou prefere outro texto?
5. **Contraste:** escurecer só o tom do cinza dos ícones (setas, "+", chevrons), sem mexer no desenho (assumido). Pode ser?
6. **Falha ao gravar:** fica fora, no backlog (assumido). Pode ser?

---

## Retrospectiva

**O que aprendi:**
- (preencha com as suas palavras)

**O que mudou em relação ao plano:**
- **Backup do Android:** o plano previa desligar. Pela decisão da usuária ("se não for necessário, não precisa") e depois de conferir que os dados são gravados cifrados, **não foi alterado**. A decisão e a opção de desligar estão em `docs/privacidade-e-dados.md`.
- **Faixas de contato removido:** o plano previa apagar ao abrir a tela. Na Fase 10 isso virou um ouvinte no `app.dart`, para uma leitura que falha nunca apagar faixas por engano.
- **Contraste:** a guideline do Flutter (por captura de tela) acusava falhas onde a cor, calculada, passa (o texto do ADA é fino, peso 300). Trocada pelo **cálculo exato do WCAG**, par de cores por par de cores. Isso achou 2 problemas reais (ícones claros e azul das caixas).
- A auditoria achou **7 problemas reais**, todos corrigidos (nomes na barra inferior, símbolo da Home, setas sem nome, toques pequenos, texto grande, ícones claros e azul informativo). Um oitavo, a **chave do Modo de demonstração sem nome**, só apareceu depois das primeiras correções.
- **Testes e fonte:** os testes de widget desenham o texto com uma fonte de quadrados (Ahem), o que cria estouros inexistentes. Os testes de medida agora carregam a Nunito (`test/support/app_font.dart`).
- F11-03 (erros e estados vazios): conferido, sem trabalho novo. Já existem: rede vazia, sem contatos (Cobertura e Alerta), sem localização, sem permissão, GPS desligado, alerta com falha por contato, faixa sem contato e dados que não carregam.

**Dívidas técnicas e novos itens para o backlog:**
- **Ver no emulador** o "Apagar meus dados", a barra com nomes e o texto em tamanho grande (nos testes passam, mas ainda não foram vistos no aparelho).
- **F11-06:** avisar a usuária quando uma gravação falha (hoje o app segue com os dados em memória, em silêncio).
- **F11-07:** testar com o **leitor de tela de verdade** (TalkBack) e com pessoas; os testes automáticos não substituem isso.
- **F11-08:** a borda dos campos de texto usa o cinza claro (contraste 1,4); o WCAG pede 3 para o contorno de campos. Não foi mexido para não alterar o desenho do Figma.
- **F11-09:** avaliar o peso do texto dos parágrafos (hoje 300, fino) com o design.
- A pessoa cadastrada ainda não é avisada por SMS (F9-07).
