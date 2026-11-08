# Fase 12A — Abertura e onboarding (antes do APK final)

> **Status:** ✅ concluída no código (pendente: conferir as 3 telas do onboarding no emulador contra o Figma)
> **Itens do backlog:** F3-09 (splash e onboarding). A tela de permissões (F3-10) e o login/cadastro (F3-13) ficam para depois, conforme decisão da usuária.

## 1. Objetivo
Quem abre o ADA pela **primeira vez** vê a splash e **3 telas de apresentação** que explicam, em segundos, o que o app faz. Nas aberturas seguintes, o app vai direto da splash para a Home.

## 2. Resultado esperado
- Splash ✅ (azul-marinho, logo branca, barra de progresso; abertura nativa do Android sem o recorte).
- **3 telas de onboarding**, lidas do Figma:
  1. "Sua segurança em um toque." (logo no centro, com anéis)
  2. "Sua rede sempre por perto." (o símbolo do ADA ao centro e as pessoas da rede em volta)
  3. "Você no controle." (ilustração de uma pessoa com o celular e o pino de localização)
- Botão **Continuar** (telas 1 e 2) e **Começar** (tela 3); **Pular** para ir direto à Home.
- O onboarding aparece **só na primeira vez**. A informação "já viu" é guardada no aparelho (um valor simples, sem dado pessoal).
- "Apagar meus dados" faz o onboarding voltar a aparecer (o app volta ao estado de recém-instalado).

## 3. Conceitos que vamos aprender
- `PageView` e `PageController` (telas que deslizam) e indicador de página
- Guardar uma preferência simples no aparelho (`shared_preferences` **ou** o armazenamento seguro que já existe)
- Decidir a rota inicial conforme o estado (primeira vez x já viu)
- Desenhar ilustrações em código (anéis, avatares ligados por linhas) x usar imagem

## 4. Escopo
**Dentro:** as 3 telas, navegação (Continuar, Pular, deslizar), lembrar que já viu, ligar ao fluxo splash → onboarding → Home, testes, acessibilidade (nomes, alvos de 48, texto grande).

**Fora:** tela de permissões, login/cadastro, animações elaboradas entre telas, traduzir para outros idiomas.

## 5. O que li no Figma (e o que precisa de decisão)
| Tela | Conteúdo | Observação |
|---|---|---|
| 1 | Título "Sua segurança em um toque." e texto "Ative o alerta em segundos e avise quem você confia," | O texto termina com **vírgula**: parece cortado. Proponho terminar com ponto |
| 2 | "Sua rede sempre por perto." e "Cadastre até 5 pessoas de confiança. Elas recebem seu alerta e sua localização ao mesmo tempo." | Condiz com o app (limite de 5; o SMS leva o link da localização). Tem o botão "Pular" em cinza bem claro |
| 3 | "Você no controle." e "Você decide quando compartilhar sua localização, podendo parar a qualquer momento." | **Não condiz com o app:** o ADA envia a localização **uma vez**, no alerta, e não acompanha em tempo real. "Parar a qualquer momento" sugere compartilhamento contínuo. Proponho ajustar o texto (ver perguntas) |

Outras observações:
- O **"Pular" só aparece na tela 2** e está muito claro (contraste baixo). Proponho "Pular" nas telas 1 e 2 (na 3 já há "Começar"), com cor que passe o contraste (a mesma `iconMuted` ou um cinza mais escuro).
- A **ilustração da tela 3** (pessoa com o celular) é uma imagem: precisa ser exportada do Figma como arquivo. As telas 1 e 2 podem ser desenhadas em código.
- As cores dos avatares da tela 2 (rosa, verde, azul, amarelo, com iniciais) já existem no app (`AppColors.avatar*`).

## 6. Passos
| # | Passo | Tamanho | Aprendizado |
|---|---|---|---|
| 1 ✅ | Splash (azul-marinho, logo branca, barra) e abertura nativa do Android | P | `AnimationController`, recursos do Android |
| 2 ✅ | **Estrutura do onboarding**: `PageView` com as 3 páginas, indicador, Continuar/Pular/Começar, rota `/onboarding` | M | `PageView`, `PageController` |
| 3 ✅ | **Conteúdo e visual das 3 telas** (anéis, rede com avatares, ilustração exportada) | M | Composição, `CustomPaint`/`Stack` |
| 4 ✅ | **Lembrar que já viu** e ligar splash → onboarding → Home; "Apagar meus dados" reinicia | P | Preferência local, rota inicial condicional |
| 5 ✅ | Testes (fluxo, Pular, só na primeira vez), acessibilidade, fechamento e backlog | P | Testar fluxo de primeira vez |

## 7. Decisões técnicas
| Decisão | Alternativas | Motivo |
|---|---|---|
| Guardar "já viu o onboarding" no **armazenamento seguro que já existe** (`flutter_secure_storage`) | Pacote novo `shared_preferences` | Evita pacote novo (regra do projeto: pacote só com a sua confirmação). Não é dado sensível, mas já temos o padrão de repositório pronto e testado |
| Onboarding só na **primeira abertura** | Sempre | Quem usa o app em perigo não pode ser atrasada por uma apresentação |
| **Pular** sempre disponível | Obrigar a ver | Mesmo motivo |
| Telas 1 e 2 **desenhadas em código** | Exportar como imagem | Ficam nítidas em qualquer tela e usam as cores do tema |
| Ilustração da tela 3 **exportada do Figma** | Redesenhar em código | É uma ilustração complexa; desenhar à mão custaria horas |
| Ajustar o texto da tela 3 para **o que o app faz de verdade** | Manter o texto do Figma | Não prometer um compartilhamento contínuo que não existe (mesmo critério da Fase 11 com o aviso por WhatsApp) |

## 8. Riscos e plano B
| Risco | Impacto | Plano B |
|---|---|---|
| Prazo (mostra em 12/11) | Onboarding consome o tempo do APK e do ensaio | Meta: onboarding pronto até 09/11. Se apertar, entregar só estrutura + textos, com a ilustração simplificada |
| Exportar a ilustração do Figma falhar (plano gratuito, poucas chamadas) | Tela 3 sem imagem | Você exporta o PNG/SVG pelo Figma e me envia; ou uso o símbolo do ADA no lugar |
| O onboarding atrasar quem precisa de ajuda | Segurança | Só na primeira vez e com "Pular" |
| Testes existentes assumirem que o app abre na Home | Testes quebrados | Já tratados na splash (testes vão à Home com `appRouter.go`) |

## 9. Critérios de pronto
- [x] Splash com logo, barra e abertura nativa do Android sem recorte (conferidas pela usuária no emulador)
- [x] As 3 telas feitas a partir do Figma, com os textos combinados (falta conferir o visual no emulador)
- [x] Continuar, Pular e deslizar funcionam; o indicador mostra a página atual
- [x] Só aparece na primeira abertura; "Apagar meus dados" o faz voltar
- [x] Nome para o leitor de tela, alvos de 48 e texto grande sem estourar (auditoria automática estendida às novas telas)
- [x] `flutter analyze` limpo e testes passando; **compilado para Android** antes de avisar que está pronto
- [ ] Testado no emulador
- [ ] Backlog atualizado; commits feitos por você

## 10. Como testar
`flutter run -d emulator-5554` com o app **desinstalado ou com os dados limpos** (para ser a "primeira vez"): splash → 3 telas → Home. Fechar e abrir de novo: splash → Home.

## 11. Perguntas em aberto
1. **Texto da tela 1:** terminar com ponto ("…e avise quem você confia.")? Ou o Figma tem a frase completa em outro lugar?
2. **Texto da tela 3:** "Você decide quando compartilhar sua localização, podendo parar a qualquer momento" sugere rastreamento contínuo, que o app não tem. Proponho: **"Sua localização só é enviada quando você ativa um alerta. Seus dados ficam só no seu celular."** Pode ser?
3. **"Pular"** nas telas 1 e 2, com cor mais escura para ler bem (assumido). Pode ser?
4. **Primeira vez apenas** (assumido). Pode ser?
5. **Armazenamento:** usar o que já existe, sem pacote novo (assumido). Pode ser?
6. A **ilustração da tela 3**: posso baixá-la do Figma pela ferramenta (uma chamada a mais), ou você prefere exportar e me mandar?

---

## Retrospectiva

**O que aprendi:**
- (preencha com as suas palavras)

**O que mudou em relação ao plano:**
- Texto da tela 3 trocado (o do Figma prometia compartilhar "e parar a qualquer momento", o que o app não faz) e ponto final na tela 1.
- "Pular" nas telas 1 e 2, com cor que passa o contraste. Acrescentei as bolinhas de página (não estão no Figma).
- A abertura **nativa** do Android 12 apareceu recortada (o sistema recorta o ícone em círculo): foi trocada por uma imagem com margem e fundo azul-marinho.
- Erro de compilação só no Android (cor escrita direto no arquivo da abertura) que os testes não pegam: **compilar para Android antes de avisar que está pronto**.
- "Apagar meus dados" também reinicia o onboarding, sem falhar se esse reinício der erro.
