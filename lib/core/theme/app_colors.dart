// Paleta de cores do ADA, extraída do Figma (ver docs/planejamento/fase-02-tema-design.md, seção 12).
//
// Estas constantes são a "matéria-prima" do tema. Os WIDGETS não devem usá-las
// diretamente: eles pegam as cores de Theme.of(context), que é montado em
// app_theme.dart a partir daqui. Assim, trocar uma cor é mudar um lugar só.

import 'package:flutter/material.dart';

// Classe só com constantes: o construtor privado (`AppColors._()`) impede que
// alguém crie objetos dela por engano. Usamos assim: AppColors.background.
class AppColors {
  AppColors._();

  // Color(0xFFF8FAFC): o 0x indica número hexadecimal; os dois primeiros dígitos
  // (FF) são a opacidade (FF = 100% opaco) e os outros seis são o RGB do Figma.

  // Base
  static const Color background = Color(0xFFF8FAFC); // fundo das telas
  static const Color border = Color(0xFFE2E2E2); // bordas e divisórias
  static const Color textPrimary = Color(0xFF000000); // texto principal
  static const Color textSecondary = Color(0xFF64748B); // subtítulos e apoio

  // Marca e destaque (coração da logo, item ativo da navegação)
  static const Color brand = Color(0xFFF3586B);

  // Contatos (tela Rede): verde de um dos avatares e cinza dos espaços vazios
  static const Color avatarGreen = Color(0xFF2FA36B);
  static const Color placeholder = Color(0xFFD9D9D9);

  // Ícones que carregam informação (setas de voltar, "x", setinhas de menu). O
  // placeholder acima é claro demais para isso (contraste 1,4); este dá cerca de 3,7
  // sobre o fundo e sobre o branco (mínimo do WCAG para ícones: 3). O placeholder
  // fica só para bordas e decoração.
  static const Color iconMuted = Color(0xFF7C8389);

  // Aviso informativo (caixas azuis). Um pouco mais escuro que o do Figma
  // (#2F6BB8) para o texto passar o contraste 4,5 sobre o próprio tom azul (4,25
  // antes; 4,8 agora).
  static const Color info = Color(0xFF2A62AB);

  // Modos de segurança (usados no passo 6, em um ThemeExtension)
  static const Color modeNormal = Color(0xFF172033); // azul-marinho
  static const Color modeAttention = Color(0xFFF2B632);
  static const Color modeAttentionText = Color(0xFF8A5A00);
  static const Color modeDanger = Color(0xFFC93A3A);
  static const Color modeDangerText = Color(0xFFA82B2B);
}
