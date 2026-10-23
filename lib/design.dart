import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'haptics.dart';
import 'models.dart';
import 'motion.dart';
import 'symbols.dart';

// HeroUI light palette. Neutrals follow its zinc "default" scale.
const fg = Color(0xFF11181C);
const muted = Color(0xFF71717A);
const faint = Color(0xFFA1A1AA);
const zinc50 = Color(0xFFFAFAFA);
const zinc100 = Color(0xFFF4F4F5);
const zinc200 = Color(0xFFE4E4E7);
const zinc300 = Color(0xFFD4D4D8);
const zinc600 = Color(0xFF52525B);
const zinc700 = Color(0xFF3F3F46);
const primary = Color(0xFF006FEE);
const primarySoft = Color(0xFFE6F1FE);
const primaryInk = Color(0xFF005BC4);
const success = Color(0xFF17C964);
const successStrong = Color(0xFF12A150);
const successSoft = Color(0xFFE8FAF0);
const successInk = Color(0xFF0E793C);
const warning = Color(0xFFF5A524);
const warningSoft = Color(0xFFFEFCE8);
const warningInk = Color(0xFF936316);
const danger = Color(0xFFF31260);
const dangerSoft = Color(0xFFFEE7EF);
const dangerInk = Color(0xFFC20E4D);
const secondary = Color(0xFF7828C8);
const secondarySoft = Color(0xFFF2EAFA);
const secondaryInk = Color(0xFF6020A0);

// HeroUI shadows. CSS blur b has sigma b/2, while Flutter's blurRadius r has
// sigma 0.57735r + 0.5, so r = (b/2 - 0.5) / 0.57735. The 1px hairline ring
// becomes a half-pixel spread.
const _hairline = BoxShadow(color: Color(0x1A000000), spreadRadius: .5);
const shadowSmall = [
  BoxShadow(color: Color(0x05000000), blurRadius: 3.46),
  BoxShadow(color: Color(0x0F000000), offset: Offset(0, 2), blurRadius: 7.79),
  _hairline,
];
const shadowMedium = [
  BoxShadow(color: Color(0x08000000), blurRadius: 12.12),
  BoxShadow(color: Color(0x14000000), offset: Offset(0, 2), blurRadius: 25.11),
  _hairline,
];
const shadowLarge = [
  BoxShadow(color: Color(0x0A000000), blurRadius: 25.11),
  BoxShadow(color: Color(0x1F000000), offset: Offset(0, 30), blurRadius: 51.1),
  _hairline,
];
const shadowPrimary = [
  BoxShadow(
    color: Color(0x66006FEE),
    offset: Offset(0, 10),
    blurRadius: 12.12,
    spreadRadius: -3,
  ),
];

const interFeatures = [FontFeature('cv11'), FontFeature('ss01')];

TextTheme _inter(TextTheme t) {
  TextStyle? f(TextStyle? s) =>
      s?.copyWith(fontFamily: 'Inter', fontFeatures: interFeatures);
  return t.copyWith(
    displayLarge: f(t.displayLarge),
    displayMedium: f(t.displayMedium),
    displaySmall: f(t.displaySmall),
    headlineLarge: f(t.headlineLarge),
    headlineMedium: f(t.headlineMedium),
    headlineSmall: f(t.headlineSmall),
    titleLarge: f(t.titleLarge),
    titleMedium: f(t.titleMedium),
    titleSmall: f(t.titleSmall),
    bodyLarge: f(t.bodyLarge),
    bodyMedium: f(t.bodyMedium),
    bodySmall: f(t.bodySmall),
    labelLarge: f(t.labelLarge),
    labelMedium: f(t.labelMedium),
    labelSmall: f(t.labelSmall),
  );
}

ThemeData pantryTheme() {
  final scheme = ColorScheme.fromSeed(seedColor: primary).copyWith(
    primary: primary,
    onPrimary: Colors.white,
    primaryContainer: primarySoft,
    onPrimaryContainer: primaryInk,
    secondaryContainer: primarySoft,
    onSecondaryContainer: primaryInk,
    surface: Colors.white,
    onSurface: fg,
    onSurfaceVariant: muted,
    surfaceTint: Colors.transparent,
    surfaceContainerLowest: Colors.white,
    surfaceContainerLow: zinc50,
    surfaceContainer: zinc100,
    surfaceContainerHigh: Colors.white,
    surfaceContainerHighest: zinc100,
    outline: zinc300,
    outlineVariant: zinc200,
    error: danger,
    onError: Colors.white,
    errorContainer: dangerSoft,
    onErrorContainer: dangerInk,
  );
  final base = ThemeData(useMaterial3: true, colorScheme: scheme);
  const label = TextStyle(
    fontFamily: 'Inter',
    fontSize: 14,
    fontWeight: FontWeight.w500,
    fontFeatures: interFeatures,
  );
  final rounded12 = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
  );
  OutlineInputBorder input([Color? color]) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: color == null
        ? BorderSide.none
        : BorderSide(color: color, width: 1.5),
  );
  return base.copyWith(
    scaffoldBackgroundColor: Colors.white,
    splashColor: zinc200.withValues(alpha: .5),
    highlightColor: Colors.transparent,
    dividerColor: zinc200,
    dividerTheme: const DividerThemeData(color: zinc100, thickness: 1),
    textTheme: _inter(
      base.textTheme
          .apply(bodyColor: fg, displayColor: fg)
          .copyWith(
            bodyLarge: const TextStyle(fontSize: 14, height: 1.45, color: fg),
            bodyMedium: const TextStyle(fontSize: 14, height: 1.45, color: fg),
            titleMedium: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
    ),
    iconTheme: const IconThemeData(color: fg, size: 20),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: zinc100,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: input(),
      enabledBorder: input(),
      disabledBorder: input(),
      focusedBorder: input(zinc300),
      errorBorder: input(dangerInk),
      focusedErrorBorder: input(dangerInk),
      labelStyle: const TextStyle(color: muted, fontSize: 14),
      floatingLabelStyle: const TextStyle(color: muted, fontSize: 13),
      hintStyle: const TextStyle(color: faint, fontSize: 14),
      prefixIconColor: faint,
      errorStyle: const TextStyle(color: dangerInk, fontSize: 12),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        disabledBackgroundColor: zinc100,
        disabledForegroundColor: faint,
        minimumSize: const Size(48, 48),
        textStyle: label,
        shape: rounded12,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        backgroundColor: zinc100,
        foregroundColor: zinc700,
        disabledForegroundColor: faint,
        minimumSize: const Size(48, 48),
        side: BorderSide.none,
        textStyle: label,
        shape: rounded12,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primary,
        minimumSize: const Size(44, 44),
        textStyle: label,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(foregroundColor: zinc600),
    ),
    checkboxTheme: CheckboxThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      side: const BorderSide(color: zinc300, width: 2),
    ),
    switchTheme: SwitchThemeData(
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      thumbColor: WidgetStateProperty.all(Colors.white),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? primary : zinc200,
      ),
    ),
    chipTheme: const ChipThemeData(
      backgroundColor: zinc100,
      selectedColor: primary,
      side: BorderSide.none,
      shape: StadiumBorder(),
      showCheckmark: false,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: zinc700,
      ),
      secondaryLabelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: Colors.white,
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      titleTextStyle: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: fg,
      ),
      contentTextStyle: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 14,
        height: 1.45,
        color: zinc600,
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    listTileTheme: const ListTileThemeData(
      iconColor: muted,
      titleTextStyle: TextStyle(
        fontFamily: 'Inter',
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: fg,
      ),
      subtitleTextStyle: TextStyle(
        fontFamily: 'Inter',
        fontSize: 12,
        color: muted,
      ),
    ),
    textSelectionTheme: const TextSelectionThemeData(cursorColor: primary),
  );
}

/// Distance from the bottom edge to the floating navigation.
double floatingNavBottom(BuildContext context) {
  final inset = MediaQuery.paddingOf(context).bottom;
  return inset > 0 ? math.max(inset - 6, 16) : 16;
}

/// Scroll padding that clears the status bar and the floating navigation.
EdgeInsets tabPadding(BuildContext context, {double extra = 0}) =>
    EdgeInsets.only(
      top: MediaQuery.paddingOf(context).top,
      bottom: floatingNavBottom(context) + 122 + extra,
    );

/// Bold Inter title, tight like HeroUI's page headings.
class Headline extends StatelessWidget {
  const Headline(this.text, {super.key, this.size = 30, this.color = fg});
  final String text;
  final double size;
  final Color color;
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(
      fontSize: size,
      fontWeight: FontWeight.w700,
      height: 1.15,
      letterSpacing: -size * .027,
      color: color,
    ),
  );
}

/// Small grey heading above a group ("Seus dados", "No olhômetro").
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.color = muted});
  final String text;
  final Color color;
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
  );
}

class Surface extends StatelessWidget {
  const Surface({
    super.key,
    required this.child,
    this.color = Colors.white,
    this.padding = const EdgeInsets.all(16),
    this.shadow = shadowMedium,
  });
  final Widget child;
  final Color color;
  final EdgeInsets padding;
  final List<BoxShadow> shadow;
  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(14),
      boxShadow: color == Colors.white ? shadow : null,
    ),
    child: child,
  );
}

/// White rounded group whose rows are separated by hairlines.
class GroupedList extends StatelessWidget {
  const GroupedList({
    super.key,
    required this.children,
    this.shadow = shadowMedium,
  });
  final List<Widget> children;
  final List<BoxShadow> shadow;
  @override
  Widget build(BuildContext context) => Container(
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      boxShadow: shadow,
    ),
    child: Material(
      type: MaterialType.transparency,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const Divider(height: 1, indent: 16),
            children[i],
          ],
        ],
      ),
    ),
  );
}

class ListRow extends StatelessWidget {
  const ListRow({
    super.key,
    required this.title,
    this.value,
    this.onTap,
    this.chevron = false,
    this.trailing,
  });
  final String title;
  final String? value;
  final VoidCallback? onTap;
  final bool chevron;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 52),
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 10, chevron ? 12 : 16, 10),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: onTap == null && trailing == null ? faint : fg,
                ),
              ),
            ),
            if (value != null) ...[
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: Text(
                  value!,
                  textAlign: TextAlign.end,
                  style: const TextStyle(fontSize: 12, color: muted),
                ),
              ),
            ],
            ?trailing,
            if (chevron) ...[
              const SizedBox(width: 4),
              const Icon(Symbols.chevronRight, size: 20, color: faint),
            ],
          ],
        ),
      ),
    ),
  );
}

/// Pill used for statuses ("Na lista", "Vence amanhã", "Baixo").
class Tag extends StatelessWidget {
  const Tag(
    this.label, {
    super.key,
    this.icon,
    this.background = zinc100,
    this.foreground = zinc700,
    this.size = 11,
  });
  final String label;
  final IconData? icon;
  final Color background, foreground;
  final double size;
  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: motionTime(context, 250),
    constraints: BoxConstraints(minHeight: size + 11),
    padding: EdgeInsets.fromLTRB(icon == null ? 8 : 6, 2, 8, 2),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: size + 3, color: foreground),
          const SizedBox(width: 3),
        ],
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: size,
              fontWeight: FontWeight.w500,
              color: foreground,
            ),
          ),
        ),
      ],
    ),
  );
}

enum ButtonTone { solid, soft, flat, success, danger, ghostDanger }

/// HeroUI-style button: solid, flat or ghost, in three sizes.
/// Presses sink a little and spring back; a changed label pops in.
class AppButton extends StatefulWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.tone = ButtonTone.solid,
    this.height = 44,
    this.expand = false,
    this.glow = false,
  });
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final ButtonTone tone;
  final double height;
  final bool expand, glow;
  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool pressed = false;
  void press(bool value) {
    if (pressed != value) setState(() => pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final tone = widget.tone, height = widget.height;
    final enabled = widget.onPressed != null;
    final (background, foreground) = !enabled
        ? (zinc100, faint)
        : switch (tone) {
            ButtonTone.solid => (primary, Colors.white),
            ButtonTone.soft => (primarySoft, primaryInk),
            ButtonTone.flat => (zinc100, zinc700),
            ButtonTone.success => (successSoft, successInk),
            ButtonTone.danger => (dangerSoft, dangerInk),
            ButtonTone.ghostDanger => (Colors.transparent, dangerInk),
          };
    final small = height <= 36;
    final radius = BorderRadius.circular(small ? 8 : 12);
    final down = pressed && enabled;
    return Semantics(
      button: true,
      enabled: enabled,
      child: AnimatedSlide(
        offset: Offset(0, down ? .04 : 0),
        duration: motionTime(context, down ? 90 : 380),
        curve: down ? Curves.easeOut : springOut,
        child: AnimatedScale(
          scale: down ? .96 : 1,
          duration: motionTime(context, down ? 90 : 380),
          curve: down ? Curves.easeOut : springOut,
          child: AnimatedContainer(
            duration: motionTime(context, 250),
            constraints: BoxConstraints(minHeight: height),
            width: widget.expand ? double.infinity : null,
            decoration: BoxDecoration(
              color: background,
              borderRadius: radius,
              boxShadow:
                  widget.glow && enabled && tone == ButtonTone.solid && !down
                  ? const [
                      BoxShadow(
                        color: Color(0x66006FEE),
                        offset: Offset(0, 8),
                        blurRadius: 11.26,
                        spreadRadius: -4,
                      ),
                    ]
                  : null,
            ),
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                borderRadius: radius,
                onTap: enabled
                    ? () {
                        tone == ButtonTone.solid || tone == ButtonTone.danger
                            ? Haptics.press()
                            : Haptics.tap();
                        widget.onPressed!();
                      }
                    : null,
                onHighlightChanged: press,
                splashColor: tone == ButtonTone.ghostDanger
                    ? dangerSoft
                    : Colors.white24,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: small ? 12 : 14,
                    vertical: 4,
                  ),
                  child: AnimatedSwitcher(
                    duration: motionTime(context, 320),
                    switchInCurve: springOut,
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(
                        scale: Tween(begin: .7, end: 1.0).animate(animation),
                        child: child,
                      ),
                    ),
                    layoutBuilder: (current, previous) => Stack(
                      alignment: Alignment.center,
                      children: [...previous, ?current],
                    ),
                    child: Row(
                      key: ValueKey(
                        '${widget.label}-${widget.icon?.codePoint}',
                      ),
                      mainAxisSize: widget.expand
                          ? MainAxisSize.max
                          : MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (widget.icon != null) ...[
                          Icon(
                            widget.icon,
                            size: small ? 16 : 19,
                            color: foreground,
                          ),
                          SizedBox(width: small ? 4 : 6),
                        ],
                        Flexible(
                          child: Text(
                            widget.label,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: small ? 12 : (height < 40 ? 13 : 14),
                              fontWeight: FontWeight.w500,
                              color: foreground,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Small rounded square holding an icon.
class IconTile extends StatelessWidget {
  const IconTile(
    this.icon, {
    super.key,
    this.background = primarySoft,
    this.foreground = primary,
    this.size = 36,
    this.iconSize = 20,
  });
  final IconData icon;
  final Color background, foreground;
  final double size, iconSize;
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(size * .28),
    ),
    child: Icon(icon, size: iconSize, color: foreground),
  );
}

/// Grey track with a white selection that slides over with a spring.
class SegmentedPicker<T> extends StatelessWidget {
  const SegmentedPicker({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
    this.keyPrefix,
  });
  final List<(T, String, IconData?)> options;
  final T? selected;
  final ValueChanged<T>? onSelected;
  final String? keyPrefix;
  @override
  Widget build(BuildContext context) {
    final index = options.indexWhere((o) => o.$1 == selected);
    final n = options.length;
    return Container(
      constraints: const BoxConstraints(minHeight: 40),
      padding: const EdgeInsets.all(4),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: zinc100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          if (index >= 0)
            Positioned.fill(
              child: AnimatedAlign(
                alignment: Alignment(n == 1 ? 0 : -1 + 2 * index / (n - 1), 0),
                duration: motionTime(context, 420),
                curve: springOut,
                child: FractionallySizedBox(
                  widthFactor: 1 / n,
                  heightFactor: 1,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: shadowSmall,
                    ),
                  ),
                ),
              ),
            ),
          IntrinsicHeight(
            child: Row(
              children: [
                for (final (value, label, icon) in options)
                  Expanded(
                    child: Semantics(
                      button: true,
                      selected: value == selected,
                      child: GestureDetector(
                        key: keyPrefix == null
                            ? null
                            : ValueKey('$keyPrefix-$value'),
                        behavior: HitTestBehavior.opaque,
                        onTap: onSelected == null
                            ? null
                            : () {
                                if (value != selected) Haptics.tap();
                                onSelected!(value);
                              },
                        child: Container(
                          constraints: const BoxConstraints(minHeight: 32),
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: BumpOnChange(
                            value: selected ?? '',
                            enabled: value == selected,
                            amount: .08,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (icon != null) ...[
                                  Icon(
                                    icon,
                                    size: 18,
                                    color: value == selected ? fg : muted,
                                  ),
                                  const SizedBox(width: 6),
                                ],
                                Flexible(
                                  child: Text(
                                    label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: value == selected ? fg : muted,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Horizontally scrolling filter pills.
class FilterPills extends StatelessWidget {
  const FilterPills({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
    this.padding = const EdgeInsets.symmetric(horizontal: 20),
  });
  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelected;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    padding: padding,
    child: Row(
      children: [
        for (final option in options)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Semantics(
              button: true,
              selected: option == selected,
              child: GestureDetector(
                onTap: () {
                  if (option != selected) Haptics.tap();
                  onSelected(option);
                },
                child: BumpOnChange(
                  value: selected,
                  enabled: option == selected,
                  amount: .1,
                  child: AnimatedContainer(
                    duration: motionTime(context, 200),
                    constraints: const BoxConstraints(minHeight: 30),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: option == selected ? primary : zinc100,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      option,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: option == selected ? Colors.white : zinc700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

class DashedBox extends StatelessWidget {
  const DashedBox({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _DashedBorderPainter(),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      child: child,
    ),
  );
}

class _DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final outline = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          (Offset.zero & size).deflate(1),
          const Radius.circular(14),
        ),
      );
    final paint = Paint()
      ..color = zinc200
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (final metric in outline.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 10) {
        canvas.drawPath(
          metric.extractPath(d, math.min(d + 6, metric.length)),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter old) => false;
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.message,
    this.action,
  });
  final String title, message;
  final Widget? action;
  @override
  Widget build(BuildContext context) => DashedBox(
    child: Column(
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: muted, fontSize: 13, height: 1.5),
        ),
        if (action != null) ...[const SizedBox(height: 16), action!],
      ],
    ),
  );
}

/// Category tint, ink and symbol used by tiles and package drawings.
({Color tint, Color ink, IconData icon}) artFor(Product p) =>
    switch (p.category) {
      'Bebidas' => (tint: primarySoft, ink: primary, icon: Symbols.waterBottle),
      'Higiene' => (tint: secondarySoft, ink: secondary, icon: Symbols.soap),
      'Limpeza' => (
        tint: secondarySoft,
        ink: secondary,
        icon: Symbols.cleaningServices,
      ),
      'Remédios' => (
        tint: dangerSoft,
        ink: dangerInk,
        icon: Symbols.medication,
      ),
      _ => (tint: successSoft, ink: successStrong, icon: Symbols.grocery),
    };

class ProductArt extends StatelessWidget {
  const ProductArt({super.key, required this.product, this.size = 48});
  final Product product;
  final double size;
  @override
  Widget build(BuildContext context) {
    final art = artFor(product);
    final fallback = Icon(art.icon, size: size * .5, color: art.ink);
    Widget? image;
    if (product.photo.isNotEmpty) {
      image = Image.file(
        File(product.photo),
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback,
      );
    } else if (product.remotePhoto.startsWith('https://')) {
      image = Image.network(
        product.remotePhoto,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => fallback,
      );
    }
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: image == null ? art.tint : zinc100,
        borderRadius: BorderRadius.circular(size * .25),
      ),
      child: image ?? fallback,
    );
  }
}

/// Full-screen page that slides in from the right, with a "Voltar" action.
class PanelScaffold extends StatelessWidget {
  const PanelScaffold({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.footer,
  });
  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? footer;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      bottom: footer != null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: TextButton.icon(
              style: TextButton.styleFrom(
                minimumSize: const Size(44, 40),
                padding: const EdgeInsets.fromLTRB(6, 0, 12, 0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                overlayColor: primarySoft,
              ),
              onPressed: () => Navigator.maybePop(context),
              icon: const Icon(Symbols.chevronLeft, size: 22),
              label: const Text('Voltar'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
            child: Headline(title),
          ),
          if (subtitle != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
              child: Text(
                subtitle!,
                style: const TextStyle(color: muted, fontSize: 14),
              ),
            ),
          Expanded(child: child),
          if (footer != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: SizedBox(width: double.infinity, child: footer),
            ),
        ],
      ),
    ),
  );
}

/// Content of a bottom sheet: header with an optional leading tile and a close button.
class SheetScaffold extends StatelessWidget {
  const SheetScaffold({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.leading,
    this.footer,
  });
  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget child;
  final Widget? footer;
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 16, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (leading != null) ...[leading!, const SizedBox(width: 12)],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Headline(title, size: 20),
                    if (subtitle != null && subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: const TextStyle(fontSize: 13, color: muted),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const SheetCloseButton(),
            ],
          ),
        ),
        Expanded(child: child),
        if (footer != null)
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: SizedBox(width: double.infinity, child: footer),
            ),
          ),
      ],
    ),
  );
}

class SheetCloseButton extends StatelessWidget {
  const SheetCloseButton({super.key});
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 44,
    height: 44,
    child: Center(
      child: IconButton(
        tooltip: 'Fechar',
        onPressed: () => Navigator.maybePop(context),
        style: IconButton.styleFrom(
          backgroundColor: zinc100,
          foregroundColor: zinc600,
          fixedSize: const Size(32, 32),
          minimumSize: const Size(32, 32),
          padding: EdgeInsets.zero,
          tapTargetSize: MaterialTapTargetSize.padded,
        ),
        icon: const Icon(Symbols.close, size: 18),
      ),
    ),
  );
}
