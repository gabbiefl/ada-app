# Privacidade e dados no ADA

> Revisão técnica feita em 08/11/2026 (Fase 11). 

O ADA lida com dados de pessoas em situação de vulnerabilidade: **quem são seus contatos de confiança** e **onde ela está** quando pede ajuda. Por isso o app foi desenhado para **guardar o mínimo, não ter servidor próprio e deixar a usuária apagar tudo**.

## Em uma frase
Tudo fica **só no celular**, cifrado; a **localização nunca é gravada**; o ADA **não tem conta, servidor nem análise de uso**; e **"Apagar meus dados"** remove tudo.

## O que o ADA guarda no celular
| Dado | Onde fica | Observação |
|---|---|---|
| **Contatos** da rede de confiança (nome e telefone, até 5) | Armazenamento seguro do aparelho | O telefone é guardado só com os dígitos |
| **Mensagens** de alerta que a usuária editou | Armazenamento seguro | Só o que foi editado; o texto padrão está no código |
| **Faixas do horário de cobertura** (qual contato e em que horas) | Armazenamento seguro | Guardam só o identificador do contato e as horas, **nunca o telefone** |

O armazenamento seguro cifra os dados antes de gravar (segundo a documentação do pacote usado, `flutter_secure_storage`: RSA-OAEP e AES-GCM na configuração padrão no Android).

## O que o ADA **não** guarda
- **A localização.** Ela é buscada quando a usuária toca no botão da aba Mapa ou quando um alerta é disparado, fica **só na memória** enquanto é usada, e é esquecida. Não há histórico de lugares.
- **O histórico de alertas** nem o texto que foi enviado.
- Conta, senha, e-mail, foto ou qualquer identificação da usuária.
- Nada de **análise de uso, anúncios ou rastreadores**.

## Permissões que o app pede, e por quê
Todas são pedidas **na hora de uso**, com uma explicação antes do aviso do Android.

| Permissão | Para quê |
|---|---|
| **Localização** (aproximada e precisa, só com o app aberto) | Mostrar onde a usuária está e incluir o link do mapa na mensagem de alerta |
| **Enviar SMS** | Avisar a rede de contatos quando o Modo Perigo ou o Modo Atenção é ativado |
| **Ligar** | Ligar para o contato de plantão no Modo Perigo |

O ADA **não declara permissão de internet** no manifesto de produção (ela só existe nos manifestos de desenvolvimento). A conferência final é feita no APK de release (Fase 12).

## Para onde os dados vão
O ADA **não envia nada a um servidor próprio**. O que sai do celular é só o que a usuária aciona:
- **SMS** para os contatos: o texto da mensagem e o **link do mapa com a localização** daquele momento. Segue pela operadora, como qualquer SMS.
- **Ligação** para o contato de plantão.
- **WhatsApp**, só se a usuária tocar no botão: o app abre a conversa com o texto pronto, e o envio é feito por ela, dentro do WhatsApp, que tem as regras próprias dele.

## Como apagar os dados
**Configurações → Apagar meus dados.** Apaga os contatos, as faixas de horário e as mensagens editadas (elas voltam ao texto padrão), desfaz qualquer alerta em andamento e esquece a localização que estivesse na memória. Há uma confirmação antes, e não dá para desfazer. Desinstalar o app também remove tudo.

## Backup do Android
Decisão: **não foi alterado** o padrão do Android. Os dados do ADA são gravados cifrados, e o que iria para um backup na nuvem seria esse texto cifrado, sem a chave, que fica no aparelho. Em outro celular (ou depois de reinstalar) os dados não ficariam legíveis e o app abriria vazio, sem quebrar. Se a banca ou a usuária preferirem impedir até isso, basta declarar `android:allowBackup="false"` no manifesto.

## Limites e cuidados que a usuária precisa conhecer
- A mensagem enviada **fica no histórico** do SMS e do WhatsApp do celular. Quem tiver o celular desbloqueado pode vê-la, e também ver o app e a rede de contatos. O ADA não controla isso.
- No navegador (Chrome), usado só para testes de desenvolvimento, o armazenamento **não é cifrado**. O app de verdade é para Android.
- O envio automático de SMS depende da permissão de SMS, que a **Play Store restringe**. O APK da mostra é instalado direto, sem a loja.
- A pessoa cadastrada **ainda não é avisada** de que está na rede de confiança. A tela de cadastro pede que a usuária combine com ela antes. Mandar um SMS de aviso é uma ideia futura (F9-07).
- O **Modo de demonstração** (Configurações) ensaia o alerta **sem enviar nada**. Nos testes reais, use números próprios.

## Princípios da LGPD, em resumo
| Princípio | Como o ADA atende |
|---|---|
| **Finalidade** | Os dados servem só para pedir ajuda: avisar e ligar para a rede da usuária |
| **Necessidade** (minimização) | Só nome, telefone, mensagens editadas e faixas de horário. Nada de e-mail, foto ou endereço |
| **Segurança** | Dados cifrados no aparelho, sem servidor, sem dados pessoais nos registros (logs) |
| **Transparência** | Este documento e a explicação antes de cada permissão |
| **Eliminação** | "Apagar meus dados", a qualquer momento |
| **Consentimento** | A usuária cadastra os próprios contatos e dispara o alerta; a permissão é pedida em cada uso. O consentimento **da pessoa cadastrada** é uma melhoria prevista (aviso no cadastro) |

## Checklist da revisão (08/11/2026)
- [x] Nenhum `print`/`debugPrint` com telefone, texto ou coordenada
- [x] O código nativo (Kotlin) registra só o **tipo** do erro, nunca dados
- [x] Os modelos (contato, faixa, entrega, ponto de localização) não mostram dados pessoais ao serem impressos
- [x] A localização não é gravada em lugar nenhum
- [x] Apenas as três chaves do armazenamento seguro existem, e todas são apagadas por "Apagar meus dados"
- [x] Apagar durante um alerta em andamento interrompe os envios que faltam
- [x] Uma leitura que falha ao abrir o app **não** apaga as faixas de horário
- [x] O texto do cadastro de contato não promete mais um aviso que não existe
- [ ] Conferir as permissões do **APK de release** (Fase 12)
- [ ] Testar o envio de SMS e a ligação num **celular real**
