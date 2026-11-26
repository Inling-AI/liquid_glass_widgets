import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import '../../theme/glass_theme.dart';
import '../../types/glass_style.dart';
import '../shared/glass_focus_region.dart';
import '../shared/glass_interaction_state_mixin.dart';

/// A menu item for use within a [GlassMenu].
///
/// [GlassMenuItem] provides a standard layout for menu options, including
/// support for icons, labels, and "destructive" styling. It handles its own
/// hover and tap interactions with liquid glass effects.
class GlassMenuItem extends StatefulWidget {
  static const _contentPadding =
      EdgeInsets.symmetric(horizontal: 16, vertical: 8);
  static const double _iconGap = 12;
  static const double _submenuChevronSize = 16;
  static const double _trailingWidth = 24;
  static const _defaultTitleStyle =
      TextStyle(fontSize: 17, fontWeight: FontWeight.w400);
  static const _defaultSubtitleStyle =
      TextStyle(fontSize: 13, fontWeight: FontWeight.w400);

  /// Creates a glass menu item.
  const GlassMenuItem({
    required this.title,
    required this.onTap,
    this.onLongPress,
    super.key,
    this.icon,
    this.isDestructive = false,
    this.trailing,
    this.hasInteractiveTrailing = false,
    this.height = 44.0,
    this.subtitle,
    this.isPressed,
    this.isSelected = false,
    this.semanticsSelected,
    this.enabled = true,
    this.disabledOpacity,
    this.titleStyle,
    this.subtitleStyle,
    this.iconColor,
    this.iconSize = 20.0,
    this.semanticsChecked,
    this.maxLines = 1,
    this.enablePressScale = true,
    this.closeDelay,
    this.closeOnTap = true,
    this.submenu,
    this.semanticLabel,
  });

  /// The primary text of the item.
  final String title;

  /// What screen readers announce for the row, in place of [title].
  ///
  /// The row is a single semantics node named by [title], and its children,
  /// [trailing] included, are not read. Set this when the row shows more than
  /// its title, for example a keyboard shortcut in [trailing]:
  /// `semanticLabel: 'Save, Command S'`. [subtitle] is still announced as the
  /// value. Null (the default) uses [title].
  final String? semanticLabel;

  /// The icon widget displayed before the title.
  final Widget? icon;

  /// Optional subtitle text displayed below the title.
  final String? subtitle;

  /// Callback when the item is tapped.
  final VoidCallback onTap;

  /// Callback when the item is long-pressed.
  final VoidCallback? onLongPress;

  /// Whether this is a destructive action (e.g., Delete).
  ///
  /// Renders with red text and distinct hover effect.
  final bool isDestructive;

  /// A widget to display after the title (e.g., shortcut key).
  final Widget? trailing;

  /// Routes row and trailing taps through the gesture arena.
  final bool hasInteractiveTrailing;

  /// Height of the item.
  ///
  /// Defaults to 44.0 (standard iOS touch target).
  final double height;

  /// External override for the pressed state.
  final bool? isPressed;

  /// Whether the item is currently selected (e.g. by a sliding pill).
  final bool isSelected;

  /// Whether this row is the menu's current choice, for assistive
  /// technologies only; it does not change how the row is drawn.
  ///
  /// `true` or `false` report a selectable row in that state (give every row
  /// of a single-selection menu a value); `null` (the default) reports no
  /// selected state, as before.
  final bool? semanticsSelected;

  /// Whether the item should handle its own interactions.
  final bool enabled;

  /// The opacity applied to the content of a disabled row.
  final double? disabledOpacity;

  /// Custom text style for the title.
  final TextStyle? titleStyle;

  /// Custom text style for the subtitle.
  final TextStyle? subtitleStyle;

  /// Custom color for the icon.
  final Color? iconColor;

  /// Custom size for the icon.
  final double iconSize;

  /// Maximum number of lines for the title text.
  ///
  /// Defaults to 1. Set to 2 for longer labels like "Set Up Name & Photo".
  final int maxLines;

  /// Whether this row is the menu's checked choice, reported as a radio
  /// button that is checked or not, in place of the button role; for
  /// assistive technologies only.
  ///
  /// macOS reports no selected state for any role (the bridge never answers
  /// `isAccessibilitySelected`), so a selected flag on the row does not reach
  /// VoiceOver there; a radio's checked state does, as `AXValue` 1 or 0.
  /// iOS reads a checked node as a switch, so set this where the platform
  /// reads it as a radio. `null` (the default) keeps the button.
  ///
  /// A radio's value is its checked state, so the [subtitle] is not
  /// announced as the value; fold it into the [title] if it matters.
  final bool? semanticsChecked;

  /// Whether to apply the subtle scale-down animation on press.
  ///
  /// When `true` (default), the item shrinks to 0.98× on touch-down, matching
  /// the standard iOS press feedback. Set to `false` on fill-rate-limited
  /// devices to eliminate the per-frame GPU cost of animating a
  /// [Transform.scale] over the glass layer.
  ///
  /// Defaults to `true`.
  final bool enablePressScale;

  /// How long to wait after [onTap] fires before the menu begins closing.
  ///
  /// Defaults to `null` (close immediately). Set to a short duration such as
  /// `Duration(milliseconds: 320)` when the item hosts an animated [trailing]
  /// widget (e.g. a [GlassSwitch]) whose state transition should be visible
  /// before the menu morphs away.
  final Duration? closeDelay;

  /// Whether activating this leaf closes the menu.
  final bool closeOnTap;

  /// Child items shown when this item is activated inside a [GlassMenu].
  ///
  /// When non-null, activating the item (tap, slide-and-release, or
  /// [GlassMenuController.endGlide]) does not call [onTap] or close the menu.
  /// Instead a card opens over the parent, which remains visible but recedes
  /// and dims. The card's header repeats this item's icon and title, in bold,
  /// with a downward chevron. Activating the header collapses the card.
  /// Submenus may nest; only the frontmost card's actions are interactive.
  ///
  /// When [trailing] is null a submenu item shows a chevron.
  final List<Widget>? submenu;

  double get _minimumContentWidth =>
      (icon == null ? 0.0 : iconSize + _iconGap) +
      (trailing == null && submenu == null ? 0.0 : _trailingWidth);

  /// Estimates this row's height before layout. [width] includes row padding.
  double estimateHeight(BuildContext context, {double? width}) {
    final scaler = MediaQuery.textScalerOf(context);
    final leadingSize = _estimateAccessorySize(
      context,
      icon,
      Size.square(iconSize),
    );
    final trailingSize = trailing != null
        ? _estimateAccessorySize(
            context,
            trailing,
            const Size(_trailingWidth, 0),
          )
        : submenu != null
            ? const Size.square(_submenuChevronSize)
            : Size.zero;
    final textWidth = width == null
        ? null
        : math.max(
            0.0,
            math.max(width - _contentPadding.horizontal, _minimumContentWidth) -
                leadingSize.width -
                (icon == null ? 0 : _iconGap) -
                trailingSize.width,
          );
    final defaults = DefaultTextStyle.of(context);

    double textHeight(String text, TextStyle style, int lines) {
      if (textWidth == null) {
        return scaler.scale(style.fontSize ?? defaults.style.fontSize ?? 14) *
            1.2 *
            lines;
      }
      var effectiveStyle = style.inherit ? defaults.style.merge(style) : style;
      if (MediaQuery.boldTextOf(context)) {
        effectiveStyle = effectiveStyle.merge(
          const TextStyle(fontWeight: FontWeight.bold),
        );
      }
      final painter = TextPainter(
        text: TextSpan(text: text, style: effectiveStyle),
        textDirection: Directionality.maybeOf(context) ?? TextDirection.ltr,
        locale: Localizations.maybeLocaleOf(context),
        textScaler: scaler,
        textHeightBehavior: defaults.textHeightBehavior ??
            DefaultTextHeightBehavior.maybeOf(context),
        textWidthBasis: defaults.textWidthBasis,
        maxLines: lines,
        ellipsis: '\u2026',
      )..layout(maxWidth: textWidth);
      final height = painter.height;
      painter.dispose();
      return height;
    }

    final labelHeight = textHeight(
            title, titleStyle ?? _defaultTitleStyle, maxLines) +
        (subtitle == null
            ? 0.0
            : textHeight(subtitle!, subtitleStyle ?? _defaultSubtitleStyle, 1));
    final contentHeight = math.max(
        labelHeight, math.max(leadingSize.height, trailingSize.height));
    return math.max(height, contentHeight + _contentPadding.vertical);
  }

  static Size _estimateAccessorySize(
    BuildContext context,
    Widget? accessory,
    Size nominalSize,
  ) {
    return switch (accessory) {
      null => Size.zero,
      Icon(:final size, :final applyTextScaling) => Size.square(
          (applyTextScaling ?? IconTheme.of(context).applyTextScaling ?? false)
              ? MediaQuery.textScalerOf(context)
                  .scale(size ?? nominalSize.width)
              : size ?? nominalSize.width,
        ),
      SizedBox(:final width, :final height) => Size(
          width != null && width.isFinite ? width : nominalSize.width,
          height != null && height.isFinite ? height : nominalSize.height,
        ),
      PreferredSizeWidget(:final preferredSize) => preferredSize,
      _ => nominalSize,
    };
  }

  @override
  State<GlassMenuItem> createState() => _GlassMenuItemState();
}

/// A separator line for use within a [GlassMenu].
class GlassMenuDivider extends StatelessWidget {
  /// The height of the divider area (line + spacing).
  final double height;

  /// Custom color for the divider line.
  final Color? color;

  /// Horizontal padding for the divider line.
  final double indent;

  /// Creates a glass menu divider.
  const GlassMenuDivider({
    super.key,
    this.height = 12.0,
    this.color,
    this.indent = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);
    final isDark = GlassTheme.brightnessOf(context) == Brightness.dark;
    final style = GlassTheme.maybeOf(context)?.data.style ?? GlassStyle.ios27;
    final Color defaultLineColor;
    if (style == GlassStyle.classic) {
      final resolvedBase = CupertinoDynamicColor.resolve(
        theme.textTheme.tabLabelTextStyle.color ??
            (isDark ? CupertinoColors.white : CupertinoColors.black),
        context,
      );
      defaultLineColor = resolvedBase.withValues(alpha: 0.45);
    } else {
      defaultLineColor =
          (isDark ? CupertinoColors.white : CupertinoColors.black)
              .withValues(alpha: isDark ? 0.18 : 0.14);
    }
    return SizedBox(
      height: height,
      child: Center(
        child: Container(
          height: 0.5,
          margin: EdgeInsets.symmetric(horizontal: indent),
          color: color ?? defaultLineColor,
        ),
      ),
    );
  }
}

/// A non-interactive label or content item for use within a [GlassMenu].
///
/// Use this for headers, section labels, or purely decorative content.
/// It does not respond to hover/press and is ignored by the selection pill.
class GlassMenuLabel extends StatelessWidget {
  /// The label text. If provided, renders stylized uppercase text.
  final String? title;

  /// The custom widget to display. Use this if [title] is null.
  final Widget? child;

  /// The height of the item.
  ///
  /// Defaults to 30.0 (aligned with author's fix to prevent pill-position drift).
  final double height;

  /// Override for the default caption text style. Only used if [title] is provided.
  final TextStyle? style;

  /// Horizontal padding for the content. Only used if [child] is provided.
  final double horizontalPadding;

  /// Optional alignment for the content. Defaults to [Alignment.centerLeft] if
  /// [title] is provided, or null (filling parent constraints) if [child] is provided.
  final AlignmentGeometry? alignment;

  /// Creates a glass menu label.
  const GlassMenuLabel({
    this.title,
    this.child,
    this.style,
    this.height = 30.0,
    this.horizontalPadding = 16.0,
    this.alignment,
    super.key,
  }) : assert(title != null || child != null,
            'Either title or child must be provided');

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);
    final isDark = GlassTheme.brightnessOf(context) == Brightness.dark;
    final glassStyle =
        GlassTheme.maybeOf(context)?.data.style ?? GlassStyle.ios27;
    final Color defaultLabelColor;
    if (glassStyle == GlassStyle.classic) {
      final resolvedBase = CupertinoDynamicColor.resolve(
        theme.textTheme.tabLabelTextStyle.color ??
            (isDark ? CupertinoColors.white : CupertinoColors.black),
        context,
      );
      defaultLabelColor = resolvedBase.withValues(alpha: 0.45);
    } else {
      defaultLabelColor = CupertinoDynamicColor.resolve(
        CupertinoColors.secondaryLabel,
        context,
      );
    }
    return Container(
      height: height,
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      alignment: alignment ?? (title != null ? Alignment.centerLeft : null),
      child: child ??
          Text(
            title!.toUpperCase(),
            style: style ??
                TextStyle(
                  color: defaultLabelColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                ),
          ),
    );
  }
}

class _GlassMenuItemState extends State<GlassMenuItem>
    with GlassInteractionStateMixin {
  // Interaction state (isPressed, isFocused, isHovered, allInteraction)
  // is provided by GlassInteractionStateMixin.

  void _handleKeyboardActivate() {
    if (!mounted || !widget.enabled) return;
    isPressed.value = true;
    widget.onTap();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) isPressed.value = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Resolve foreground color from the current CupertinoTheme.
    // This automatically supports Light Mode, Dark Mode, and custom themes.
    final theme = CupertinoTheme.of(context);
    final isDark = GlassTheme.brightnessOf(context) == Brightness.dark;
    final style = GlassTheme.maybeOf(context)?.data.style ?? GlassStyle.ios27;
    final defaultForeground = CupertinoDynamicColor.resolve(
      theme.textTheme.textStyle.color ??
          (isDark ? CupertinoColors.white : CupertinoColors.black),
      context,
    );
    final destructiveColor = CupertinoDynamicColor.resolve(
      CupertinoColors.destructiveRed,
      context,
    );

    // Determine the base color of the item (inheritance logic)
    // Priority: iconColor > titleStyle.color > destructiveRed > theme foreground
    final Color baseColor = widget.iconColor ??
        widget.titleStyle?.color ??
        (widget.isDestructive ? destructiveColor : defaultForeground);

    // Apply specific opacities based on original design specs:
    // Icon: 100% (enabled), 50% (disabled)
    // Text: 90% (static for enabled/disabled)
    final Color iconColor = widget.iconColor ??
        (widget.isDestructive
            ? destructiveColor
            : baseColor.withValues(alpha: widget.enabled ? 1.0 : 0.5));

    final Color textColor = widget.titleStyle?.color ??
        (widget.isDestructive
            ? destructiveColor
            : baseColor.withValues(alpha: 0.9));

    final Color pressWash = (style == GlassStyle.classic || isDark)
        ? const Color(0x26FFFFFF)
        : const Color(0x14000000);
    final Color hoverWash = (style == GlassStyle.classic || isDark)
        ? const Color(0x1AFFFFFF)
        : const Color(0x0D000000);

    // Dynamic background for hover/press states
    final content = ListenableBuilder(
      listenable: allInteraction,
      builder: (context, _) {
        final bool isHov = isHovered.value;
        final bool isFoc = isFocused.value;
        final bool localPressed = isPressed.value;
        final bool effectivePressed =
            (widget.isPressed == true) || localPressed;
        final bool effectiveSelected = widget.isSelected;

        final Color backgroundColor = effectiveSelected
            ? const Color(0x00000000) // Parent renders the sliding pill
            : effectivePressed
                ? pressWash // Standalone press
                : (isHov || isFoc)
                    ? hoverWash
                    : const Color(0x00000000);

        // Scale effect on press (subtle squash like iOS buttons)
        final double scale =
            (widget.enablePressScale && effectivePressed) ? 0.98 : 1.0;

        return ConstrainedBox(
          constraints: BoxConstraints(minHeight: widget.height),
          child: AnimatedScale(
            scale: scale,
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOutCubic,
            child: AnimatedContainer(
              duration: (effectiveSelected || effectivePressed)
                  ? Duration.zero // Instant highlight on tap down
                  : const Duration(
                      milliseconds: 150), // Smooth fade out on release
              curve: Curves.easeOutCubic,
              constraints: BoxConstraints(minHeight: widget.height),
              padding: GlassMenuItem._contentPadding,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Opacity(
                opacity: widget.enabled ? 1.0 : (widget.disabledOpacity ?? 0.4),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // A submenu row shows a chevron unless the caller supplied
                    // its own trailing widget.
                    final Widget? trailing = widget.trailing ??
                        (widget.submenu != null
                            ? Icon(
                                CupertinoIcons.chevron_right,
                                size: GlassMenuItem._submenuChevronSize,
                                color: iconColor.withValues(alpha: 0.6),
                              )
                            : null);
                    final row = Row(
                      children: [
                        // Icon
                        if (widget.icon != null) ...[
                          IconTheme(
                            data: IconThemeData(
                              color: iconColor,
                              size: widget.iconSize,
                            ),
                            child: widget.icon!,
                          ),
                          const SizedBox(width: GlassMenuItem._iconGap),
                        ],

                        // Text Content (Title & Subtitle)
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.title,
                                maxLines: widget.maxLines,
                                overflow: TextOverflow.ellipsis,
                                style: widget.titleStyle ??
                                    GlassMenuItem._defaultTitleStyle
                                        .copyWith(color: textColor),
                              ),
                              if (widget.subtitle != null)
                                Text(
                                  widget.subtitle!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: widget.subtitleStyle ??
                                      GlassMenuItem._defaultSubtitleStyle
                                          .copyWith(
                                        color: textColor.withValues(alpha: 0.6),
                                      ),
                                ),
                            ],
                          ),
                        ),

                        // Trailing
                        if (trailing != null) trailing,
                      ],
                    );

                    if (constraints.hasBoundedWidth) {
                      final minRequired = widget._minimumContentWidth;
                      if (constraints.maxWidth < minRequired) {
                        return OverflowBox(
                          alignment: Alignment.centerLeft,
                          minWidth: minRequired,
                          maxWidth: minRequired,
                          child: row,
                        );
                      }
                    }

                    return row;
                  },
                ),
              ),
            ),
          ),
        );
      },
    );

    // Build the item content
    return GlassFocusRegion(
      enabled: widget.enabled,
      isButton: true,
      semanticLabel: widget.semanticLabel ?? widget.title,
      // The title label replaces the row's own text, so carry the subtitle
      // as the value: announced after the title, on the same node.
      semanticValue: widget.subtitle,
      // Only the semantic choice is reported. The visual [isSelected] follows
      // the glide pill, and announcing it would mark whichever row is hovered.
      tracksSelection: widget.semanticsSelected != null,
      isSelected: widget.semanticsSelected ?? false,
      isFocusedNotifier: isFocused,
      isHoveredNotifier: isHovered,
      onKeyboardActivate: _handleKeyboardActivate,
      semanticOnTap: widget.enabled ? widget.onTap : null,
      // A non-null checked state reads as a radio in place of the button.
      checked: widget.semanticsChecked,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: GestureDetector(
        onTapDown: widget.enabled ? (_) => isPressed.value = true : null,
        onTapUp: widget.enabled ? (_) => isPressed.value = false : null,
        onTapCancel: widget.enabled ? () => isPressed.value = false : null,
        onTap: widget.enabled ? widget.onTap : null,
        onLongPress: widget.enabled ? widget.onLongPress : null,
        behavior: HitTestBehavior.opaque,
        // The tap lives on the GlassFocusRegion node with the label (via
        // semanticOnTap); a second one here landed on a separate, unnamed
        // node, as GlassButton documents.
        excludeFromSemantics: true,
        child: content,
      ),
    );
  }
}
