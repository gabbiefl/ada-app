# Fase 3 — Telas estáticas

> **Status:** ✅ concluída (com telas pendentes, ver backlog F3-09 a F3-13)
> **Itens do backlog:** F3-01 a F3-06

## 1. Objetivo
Construir as telas do ADA a partir do Figma, ainda sem lógica: dados fixos e botões que não fazem nada. A Home vem primeiro, porque seus tokens já foram lidos.

## 2. Resultado esperado
O app mostra a Home com o visual do design (saudação, símbolo central, cards dos modos e barra de navegação) e as demais telas do MVP, cada uma com widgets reutilizáveis e usando só o tema.

## 3. Conceitos que vamos aprender
- Layout: `Column`, `Row`, `Expanded`, `Stack`, `Padding`, `Container`/`DecoratedBox`
- Composição: dividir uma tela em widgets pequenos e reutilizáveis (`ModeCard`, `StatusChip`)
- Ícones (Lucide) e imagens como assets
- Estilos de botão e campo de texto no tema (`FilledButton`, `InputDecorationTheme`)

## 4. Escopo
**Dentro:**
- Home (Normal e Perigo ativo, com a variação de estado passada por parâmetro, sem lógica)
- Widgets compartilhados: card de modo, chip de estado, barra de navegação
- Telas: rede de contatos, cadastro/edição de contato, mensagens pré-definidas, configurações
- Ajustar o tema com botões e campos (confirmar a cor primária `#F3586B`)

**Fora (vai para o backlog):**
- Navegação real entre telas e estado (Fase 4)
- Salvar contatos e mensagens (Fases 5 e 6)
- Modos funcionando, localização e envio (Fases 7 a 9)

## 5. Pré-requisitos
- Fases 0, 1 e 2 concluídas (tema, fonte e cores dos modos)
- Tokens da Home no plano da Fase 2 (seção 12)
- Figma: poucas chamadas por mês no plano gratuito; ler uma tela por vez e só o necessário

## 6. Passos
| # | Passo | Tamanho | O que a usuária aprende |
|---|---|---|---|
| 1 ✅ | Ícones decididos e instalados; logo e símbolos exportados para `assets/` | P | Assets de imagem e ícones |
| 2 ✅ | Home, parte 1: cabeçalho, saudação e símbolo central (Normal); anéis animados em widget próprio | M | `Column`, `Row`, `Stack`, `Padding` |
| 3 ✅ | Home, parte 2: `ModeCard` reutilizável (Atenção e Perigo) | M | Composição, parâmetros de widget |
| 4 ✅ | Home, parte 3: barra de navegação e variação "Perigo ativo" (chip) | M | Widgets com parâmetros, `NavigationBar` |
| 5 ✅ | Ler "Rede - cadastro" no Figma; ajustar tema com botões e campos | M | `FilledButton`, `InputDecorationTheme` |
| 6 ✅ | Telas de rede e de cadastro de contato | M | `ListView`, `TextField`, `Form` (só visual) |
| 7 ✅ | Telas de configurações, mensagens e edição de mensagem | M | Reuso dos widgets já criados |
| 8 ✅ | Testes de widget das telas, retrospectiva, resumos e commit | P | Testar o que a tela mostra |

## 7. Decisões técnicas
| Decisão | Alternativas consideradas | Motivo |
|---|---|---|
| Ícones: pacote `lucide_icons_flutter` 4.0.1 (licença MIT) | SVGs como assets (`flutter_svg`) | Mais rápido de usar e fiel ao design (que usa Lucide); SVGs também exigiriam um pacote |
| Variação de estado por parâmetro (`ModeCard(isActive: ...)`) | Lógica de estado já na tela | O estado real vem na Fase 4; aqui só o visual |
| Uma tela por vez, na ordem do uso | Todas de uma vez | Poupa chamadas do Figma e dá algo para mostrar logo |

## 8. Riscos e plano B
| Risco | Impacto | Plano B |
|---|---|---|
| Limite de chamadas do Figma | Não dá para ler todas as telas | Ler Home e uma tela de formulário; as outras seguem os mesmos padrões ou são definidas com você |
| Prazo da mostra (12/11/2026) | Telas fora do MVP não ficam prontas | Prioridade: Home, rede, cadastro; mensagens e configurações podem ser mais simples |
| Mudar de web para Android só na Fase 7 | Problema de layout só aparece tarde | Testar no Chrome com largura de celular (393 × 852) |

## 9. Critérios de pronto
- [x] Telas do escopo montadas, sem cores ou fontes fixas nos widgets
- [x] Widgets reutilizáveis em `features/<nome>/widgets/`
- [x] `flutter analyze` sem avisos e `flutter test` passando
- [x] Testado no Chrome
- [x] Backlog atualizado e commit feito

## 10. Como testar
`flutter run -d chrome`, com a janela estreita (perto de 393 × 852). `flutter analyze` e `flutter test`.

## 11. Perguntas em aberto
- ✅ Cor primária: o design usa botões azul-marinho (`#172033`), então ele virou `primary`; o rosa `#F3586B` ficou como `tertiary` (destaque).
- ✅ Ícones: pacote `lucide_icons_flutter` (decidido e instalado)
- Quais telas entram no MVP da mostra? Se faltar tempo, quais cortamos?

## 12. Tokens lidos do Figma na Fase 3

### 12.1 Tela "Rede" (lida: 1 chamada do MCP; a tela "Rede - cadastro" ainda não)
- Cabeçalho: título "Rede de contatos" (SemiBold 24), subtítulo (Regular 16, `#64748B`) e contador "3/5" (SemiBold 16) à direita.
- Cartão de contato: 314 × 88, raio 20, fundo branco, borda `#D9D9D9` a 30%. Avatar 46 × 44 com iniciais (Bold 16, branco), nome (Bold 16), telefone (Regular 13, `#64748B`) e "x" de 12 em cinza claro.
- Cores dos avatares: rosa `#F3586B`, verde `#2FA36B` (**cor nova**), amarelo `#F2B632`.
- Cartão vazio "Adicionar contato": fundo `#F8FAFC`, borda **tracejada** `#D9D9D9`, círculo `#D9D9D9` com ícone plus, texto Bold 16 `#64748B`.
- Espaço entre cartões: 9. Barra de navegação igual à da Home, com o item "Rede" ativo.
- Esta tela **não tem botões nem campos de texto**: o estilo deles virá da tela "Rede - cadastro".

### 12.2 Tela "Rede - cadastro" (lida: 1 chamada do MCP)
- Cabeçalho "Novo contato" (SemiBold 24) e contador "4/5".
- **Botão principal** ("Salvar contato"): fundo `#172033`, texto branco Bold 16, altura 49, raio 14. **A cor primária é o azul-marinho, e não o rosa.**
- **Botão secundário** ("Cancelar"): fundo branco, borda `#D9D9D9`, texto `#64748B` Bold 16, altura 49, raio 14, ícone x de 24.
- **Botão "Escolher da agenda"**: branco, borda `#172033`, raio 20, altura 71, texto preto Bold 16, ícone book-user.
- **Campo de texto**: fundo branco, borda `#64748B` de 1, raio 20, altura 51, ícone de 18 à esquerda, texto Medium 15 `#64748B`. Rótulo acima: Bold 15 `#172033`.
- Divisor "ou preencha" (SemiBold 11, `#64748B`) entre duas linhas.
- Caixa de aviso: fundo `#2F6BB8` a 14%, raio 20, texto `#2F6BB8` Regular 13 com trecho em negrito, ícone badge-info de 22 (**cor nova**).
- Esta tela **não tem barra de navegação**.

### 12.3 Configurações, Mensagens e Mensagens - Editar (3 chamadas do MCP)
- **Configurações:** itens de menu 314 × 99, raio 20, fundo branco, borda `#D9D9D9` a 30%. Círculo do ícone em rosa a 15% com ícone rosa, título Bold 16, descrição Regular 13 `#64748B` (2 linhas) e seta de 21 à direita. Ícones: moon-star (horário), clock (histórico) e message-circle (mensagens). O subtítulo no Figma repete o da tela Rede ("Cadastre a sua rede de confiança."): provável cópia, a confirmar.
- **Mensagens:** cartão 314 × 139 com ponto de 7 na cor do modo (perigo, atenção e verde `#2FA36B`), título Bold 16, texto Regular 13 e "Editar" (SemiBold 14, `#64748B`). Seta de voltar à direita no cabeçalho. Subtítulo Regular 13.
- **Mensagens - Editar:** rótulo "Texto da mensagem" (SemiBold 15); caixa de texto 314 × 172, borda `#64748B`, texto Regular 15; contador (SemiBold 11) dentro da caixa; "Resetar para padrão" (ícone rotate-ccw 16, SemiBold 14) à direita; botões Cancelar e Salvar mensagem iguais aos do cadastro. No Figma o contador mostra 94/200 para um texto de 90 caracteres: é só exemplo, o app conta de verdade.
- **Ainda não lidas:** Horário de cobertura e Histórico de alertas (telas ligadas ao menu).

### 12.4 Decisão de escopo
- **Horário de cobertura entra no MVP** (decisão da usuária): é lógica simples em Dart. Itens F10-01 a F10-03 promovidos a prioridade M e F3-07 criado para a tela. O histórico de alertas fica como S (F3-08).

---

## Retrospectiva

**O que aprendi:**
- <a autora escreve com as próprias palavras>
- <...>

**O que mudou em relação ao plano:**
- Ícones: pacote `lucide_icons_flutter` (aprovado) em vez de SVGs. Os anéis do símbolo viraram widget próprio com animação de pulso, fora do plano original.
- A cor primária do tema virou azul-marinho (os botões do design são dessa cor); o rosa ficou como destaque (`tertiary`).
- Telas feitas: Home (Normal e Perigo ativo), Rede, Novo contato, Configurações, Mensagens e Mensagens - Editar. O contador e o reset da edição já funcionam.
- Foram lidas 5 telas do Figma, mais 2 leituras da Home e uma que falhou (plano gratuito).
- Bibliotecas de aprendizado: pasta `03-interface` com 4 resumos.

**Dívidas técnicas e novos itens para o backlog:**
- Telas que faltam: splash, 3 de onboarding, permissões, mapa/localização, rede cheia (5/5) e login/cadastro, que não foi desenhado no Figma (F3-09 a F3-13).
- Horário de cobertura (F3-07, F10-01 a F10-03) entrou no MVP; o histórico de alertas (F3-08) tem prioridade menor.
- O subtítulo de Configurações no Figma repete o da Rede ("Cadastre a sua rede de confiança."): confirmar o texto.
- A barra de navegação e os botões ainda não navegam (Fase 4). Tocar no símbolo para desativar o Modo Perigo também depende do estado global (Fase 4).
- Trocar o cabeçalho escrito à mão por `PageHeader` nas telas Rede, Novo contato e Configurações.
- Resumos 03 e 04 da Fase 1 citam a `HomePage` antiga: decidir se são atualizados.
