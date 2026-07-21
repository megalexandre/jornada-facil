import 'package:flutter/material.dart';
import 'package:jornadafacil/core/theme/app_theme.dart';

/// Larguras de corte (Material 3 window size classes, reduzidas às duas que
/// o app realmente usa pra decidir layout).
/// https://m3.material.io/foundations/layout/applying-layout/window-size-classes
class Breakpoints {
  Breakpoints._();

  /// Abaixo disso: celular em retrato. Acima: tablet, foldable, desktop.
  static const double compact = 600;

  /// A partir disso: espaço pra navegação lateral fixa em vez de barra
  /// inferior (desktop, tablet paisagem, janela larga no web).
  static const double expanded = 840;
}

/// Decisões de layout baseadas na largura da *tela inteira* (ex.: trocar
/// `BottomNavigationBar` por `NavigationRail`). Usa [MediaQuery] — não serve
/// pra decidir o layout de um widget que ocupa só parte da tela (um card
/// dentro de uma `Row`, por exemplo); pra isso use `LayoutBuilder` com as
/// constraints locais, comparadas contra [Breakpoints] diretamente.
extension ResponsiveContext on BuildContext {
  double get _screenWidth => MediaQuery.sizeOf(this).width;

  bool get isCompact => _screenWidth < Breakpoints.compact;
  bool get isExpanded => _screenWidth >= Breakpoints.expanded;

  /// Margem lateral recomendada pelo Material 3 pra faixa de largura atual.
  double get horizontalMargin =>
      isCompact ? AppSpacing.marginMobile : AppSpacing.marginDesktop;
}

/// Escolhe um valor pela faixa de largura, ex.:
/// `responsiveValue(context, compact: 1, expanded: 3)` pra colunas de um grid.
/// [medium] cai pra [compact] quando omitido.
T responsiveValue<T>(
  BuildContext context, {
  required T compact,
  T? medium,
  T? expanded,
}) {
  if (context.isExpanded) return expanded ?? medium ?? compact;
  if (!context.isCompact) return medium ?? compact;
  return compact;
}
