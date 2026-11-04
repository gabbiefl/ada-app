# 📚 Aprendizado — Flutter na prática com o ADA

Resumos diretos para consulta, escritos enquanto o ADA é construído. Cada tema nasce de algo que o projeto realmente usou, então os exemplos apontam para o código deste repositório.

**Para quem é:** quem está começando em Flutter e Dart (a autora, colegas de turma) e quem quiser entender as escolhas do projeto.

## Como está organizado

- Uma **pasta numerada por tema** (`01-fundamentos/`, `02-.../`), na ordem em que o assunto aparece no projeto.
- Dentro de cada pasta, **arquivos numerados** para leitura em sequência (`01-...md`, `02-...md`).
- Cada resumo cabe em uma tela ou duas: o que é, como funciona, um exemplo mínimo e onde aparece no ADA.

## Índice

### ✅ 01 — Fundamentos (Fase 1)
| # | Resumo |
|---|---|
| 01 | [Estrutura de um projeto Flutter](01-fundamentos/01-estrutura-do-projeto.md) |
| 02 | [pubspec.yaml e dependências](01-fundamentos/02-pubspec-e-dependencias.md) |
| 03 | [Widgets e a árvore de widgets](01-fundamentos/03-widgets-e-arvore.md) |
| 04 | [StatelessWidget x StatefulWidget e setState](01-fundamentos/04-stateless-stateful-setstate.md) |
| 05 | [Hot reload x hot restart](01-fundamentos/05-hot-reload-e-restart.md) |
| 06 | [Sintaxe Dart que aparece no começo](01-fundamentos/06-sintaxe-dart-basica.md) |

### ✅ 02 — Tema e design (Fase 2)
| # | Resumo |
|---|---|
| 01 | [ThemeData e ColorScheme](02-tema-e-design/01-themedata-e-colorscheme.md) |
| 02 | [TextTheme e fonte variável](02-tema-e-design/02-textTheme-e-fonte-variavel.md) |
| 03 | [ThemeExtension e testes do tema](02-tema-e-design/03-themeextension-e-testes-do-tema.md) |

### ✅ 03 — Interface (Fase 3)
| # | Resumo |
|---|---|
| 01 | [Layout: Column, Row, Expanded e Stack](03-interface/01-layout-column-row-stack.md) |
| 02 | [Composição: widgets reutilizáveis](03-interface/02-composicao-de-widgets.md) |
| 03 | [Animação e desenho customizado](03-interface/03-animacao-e-desenho-customizado.md) |
| 04 | [Campos de texto e botões no tema](03-interface/04-campos-de-texto-e-botoes-no-tema.md) |

### ✅ 04 — Navegação e estado (Fases 4 e 6)
| # | Resumo |
|---|---|
| 01 | [Rotas e go_router](04-navegacao-e-estado/01-rotas-e-go-router.md) |
| 02 | [enum e ChangeNotifier](04-navegacao-e-estado/02-enum-e-changenotifier.md) |
| 03 | [Provider](04-navegacao-e-estado/03-provider.md) |
| 04 | [Testando navegação e estado](04-navegacao-e-estado/04-testando-navegacao-e-estado.md) |
| 05 | [Parâmetros de rota e enum com propriedades](04-navegacao-e-estado/05-parametros-de-rota-e-enum.md) |

### ✅ 05 — Dados locais (Fases 5 e 6)
| # | Resumo |
|---|---|
| 01 | [Models em Dart](05-dados-locais/01-models-em-dart.md) |
| 02 | [Formulários e validação](05-dados-locais/02-formularios-e-validacao.md) |
| 03 | [Persistência local](05-dados-locais/03-persistencia-local.md) |
| 04 | [Regras de negócio testáveis](05-dados-locais/04-regras-de-negocio-testaveis.md) |
| 05 | [Reusar o padrão e não confiar no dado guardado](05-dados-locais/05-reuso-do-padrao-e-dado-guardado.md) |

### 🔜 Próximos temas (entram quando a fase correspondente for feita)
| Pasta | Tema | Fase |
|---|---|---|
| 06-recursos-do-celular | Permissões, localização, url_launcher | 8 e 9 |
| 07-qualidade | Testes, acessibilidade, privacidade | 11 |

## Convenções dos resumos

1. Título com o nome do conceito, seguido de uma frase de definição.
2. Exemplo mínimo em código.
3. Seção **No ADA**, dizendo onde o conceito aparece no repositório.
4. Termos técnicos em inglês são explicados na primeira vez.
