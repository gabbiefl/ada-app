// Tema do ADA: junta a paleta (app_colors.dart) e os textos (app_text_theme.dart)
// em um único ThemeData, que o MaterialApp distribui para o app inteiro.
//
// Só existe o tema claro: o design não tem modo escuro (ver IDEIA-07 no backlog).

import 'package:flutter/material.dart';

import 'package:ada_app/core/theme/app_colors.dart';
import 'package:ada_app/core/theme/app_text_theme.dart';
import 'package:ada_app/core/theme/mode_colors.dart';

class AppTheme {
  AppTheme._();

  // `static` + `get`: um valor calculado, acessado como AppTheme.light.
  static ThemeData get light {
    // ColorScheme: o conjunto de cores "por função" do Material 3. Cada cor tem
    // um par `on...` (a cor do conteúdo desenhado SOBRE ela, ex.: texto no botão).
    // Aqui usamos as cores explícitas do Figma, e não ColorScheme.fromSeed, que
    // inventaria tons que o design não tem.
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      // Os botões do design são azul-marinho, então ele é a cor primária. O rosa
      // da marca fica como destaque (tertiary): item ativo da barra, coração.
      primary: AppColors.modeNormal,
      onPrimary: Colors.white,
      tertiary: AppColors.brand,
      onTertiary: Colors.white,
      secondary: AppColors.modeNormal,
      onSecondary: Colors.white,
      error: AppColors.modeDanger,
      onError: Colors.white,
      surface: AppColors.background,
      onSurface: AppColors.textPrimary,
      onSurfaceVariant: AppColors.textSecondary,
      outline: AppColors.border,
      outlineVariant: AppColors.border,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      // Cor de fundo das telas (Scaffold).
      scaffoldBackgroundColor: AppColors.background,
      // Fonte padrão do app e estilos de texto.
      fontFamily: AppTextTheme.fontFamily,
      textTheme: AppTextTheme.textTheme,
      // Extensões: valores próprios do ADA dentro do tema (cores dos modos).
      // Nos widgets: ModeColors.of(context).danger
      extensions: const [ModeColors.light],
      // Campos de texto: fundo branco, borda cinza-azulada e cantos de 20.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        hintStyle: AppTextTheme.textTheme.labelLarge?.copyWith(
          color: AppColors.textSecondary,
        ),
        prefixIconColor: AppColors.textSecondary,
        border: _fieldBorder(AppColors.textSecondary),
        enabledBorder: _fieldBorder(AppColors.textSecondary),
        // Ao digitar, a borda fica azul-marinho e mais grossa.
        focusedBorder: _fieldBorder(AppColors.modeNormal, width: 1.5),
        // Campo com erro de validação: borda vermelha (a mensagem usa colorScheme.error).
        errorBorder: _fieldBorder(AppColors.modeDanger),
        focusedErrorBorder: _fieldBorder(AppColors.modeDanger, width: 1.5),
      ),
      // Botão principal (preenchido, azul-marinho).
      filledButtonTheme: FilledButtonThemeData(style: _buttonStyle()),
      // Botão secundário (branco com borda cinza), como o "Cancelar".
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: _buttonStyle().copyWith(
          backgroundColor: const WidgetStatePropertyAll(Colors.white),
          foregroundColor: const WidgetStatePropertyAll(
            AppColors.textSecondary,
          ),
          side: const WidgetStatePropertyAll(
            BorderSide(color: AppColors.placeholder),
          ),
        ),
      ),
    );
  }

  static OutlineInputBorder _fieldBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(20),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  // Base dos botões: altura 49, cantos de 14, texto Bold 16.
  static ButtonStyle _buttonStyle() {
    return ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size(double.infinity, 49)),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      textStyle: WidgetStatePropertyAll(AppTextTheme.textTheme.titleMedium),
    );
  }
}
