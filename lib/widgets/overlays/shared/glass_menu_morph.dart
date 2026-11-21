import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/physics.dart';
import 'package:flutter/widgets.dart';

import '../../../src/renderer/glass_materialize_scope.dart';
import '../../../src/renderer/liquid_glass_renderer.dart'
    show LiquidGlassSettings;
import '../../../utils/liquid_morph_physics.dart';

/// Carries the current shape profile across a change in animation direction.
class GlassMenuMotion {
  double _startValue = 0;
  double _startDismissal = 0;
  bool _closing = false;

  /// Retargets the morph at its current spring sample.
  void retarget(double value, {required bool closing}) {
    if (_closing == closing) return;
    _startDismissal =
        value <= 0 || value >= 1 ? (closing ? 1 : 0) : dismissalAt(value);
    _startValue = value;
    _closing = closing;
  }

  /// Interpolates the opening and closing profiles during a reversal.
  double dismissalAt(double value) {
    final travel = _closing ? _startValue - value : value - _startValue;
    final blend = Curves.easeOut.transform((travel / 0.24).clamp(0.0, 1.0));
    return ui.lerpDouble(_startDismissal, _closing ? 1 : 0, blend)!;
  }
}

/// Geometry and optics of the morph between a trigger and a menu.
class GlassMenuMorph {
  /// Samples the morph at the current spring [value].
  GlassMenuMorph({
    required double value,
    required Rect trigger,
    required Rect menu,
    required double triggerRadius,
    required double menuRadius,
    double dismissal = 0,
  }) : this._(
          value.clamp(0.0, 1.06),
          trigger,
          menu,
          triggerRadius,
          menuRadius,
          dismissal,
        );

  GlassMenuMorph._(
    double value,
    this.trigger,
    Rect menu,
    double triggerRadius,
    double menuRadius,
    this.dismissal,
  )   : progress = value.clamp(0.0, 1.0),
        bounds = _bounds(value, trigger, menu, dismissal),
        menuSize = menu.size,
        _triggerRadius = triggerRadius,
        _menuRadius = menuRadius;

  /// The opening spring for a menu at its default speed.
  static const spring = SpringDescription(
    mass: 1,
    stiffness: 310,
    damping: 24,
  );

  /// Creates a spring that carries momentum across interruptions.
  static SpringSimulation openSimulation(double value, double velocity) =>
      SpringSimulation(
        spring,
        value,
        1,
        value == 0 ? 3.0 : velocity,
        snapToEnd: true,
        tolerance: _settleTolerance,
      );

  /// The return spring leaves a small undershoot for the trigger rebound.
  static SpringSimulation closeSimulation(double value, double velocity) =>
      SpringSimulation(
        LiquidMorphPhysics.closeSpring,
        value,
        0,
        math.min(velocity, LiquidMorphPhysics.closeVelocityHint),
        snapToEnd: true,
        tolerance: _settleTolerance,
      );

  static const _settleTolerance = Tolerance(distance: 0.001, velocity: 0.05);

  /// Spring progress in the unit interval.
  final double progress;

  /// Surface bounds in the coordinate space of the trigger and final menu.
  final Rect bounds;

  /// Trigger bounds in the same coordinate space as [bounds].
  final Rect trigger;

  /// Weight of the closing profile during a direction change.
  final double dismissal;

  /// Layout size of the menu content throughout the morph.
  final Size menuSize;
  final double _triggerRadius;
  final double _menuRadius;

  /// The lens stays round through its flight before resolving the menu corners.
  double get radius {
    final lensRadius = bounds.shortestSide / 2;
    final launchRadius =
        ui.lerpDouble(_triggerRadius, lensRadius, _stage(0, 0.20))!;
    final openRadius =
        ui.lerpDouble(launchRadius, _menuRadius, _stage(0.64, 1))!;
    final closeRadius =
        ui.lerpDouble(lensRadius, _menuRadius, _stage(0.65, 1))!;
    return ui
        .lerpDouble(openRadius, closeRadius, dismissal)!
        .clamp(0.0, lensRadius);
  }

  /// Visibility of the morphing surface during the trigger handoff.
  double get visibility => ui.lerpDouble(
        handoffVisibility(progress),
        _stage(0, 0.09),
        dismissal,
      )!;

  /// The portion of the trigger handoff assigned to the moving glass.
  static double handoffVisibility(double progress) =>
      Curves.easeInOut.transform((progress / 0.08).clamp(0.0, 1.0));

  /// Opacity of the real trigger during the material handoff.
  static double triggerOpacity(double value, double dismissal) {
    final returning = 1 - _ease(value, 0.045, 0.34);
    return ui.lerpDouble(1 - handoffVisibility(value), returning, dismissal)!;
  }

  /// Glass settings for the current backdrop blur and frost ramp.
  LiquidGlassSettings material(LiquidGlassSettings settings) {
    final openBlur = ui.lerpDouble(0.08, 1, _stage(0.06, 0.84))!;
    final closeBlur = ui.lerpDouble(0.08, 1, _stage(0.68, 1))!;
    final blur = ui.lerpDouble(openBlur, closeBlur, dismissal)!;
    if (blur == 1) return settings;
    return settings.copyWith(
      blur: settings.blur * blur,
      frost: settings.frost * blur,
    );
  }

  double get _contentOpacity =>
      ui.lerpDouble(_stage(0.32, 0.70), _stage(0.70, 1), dismissal)!;
  double get _contentSigma => ui.lerpDouble(
        4.5 * (1 - _stage(0.55, 0.94)),
        2.5 * (1 - _stage(0.84, 1)),
        dismissal,
      )!;
  double get _refraction =>
      _stage(0.32, 0.63) * (1 - _stage(0.79, 0.99)) * (1 - dismissal);

  double _stage(double start, double end) => _ease(progress, start, end);
  static double _ease(double value, double start, double end) =>
      Curves.easeInOut
          .transform(((value - start) / (end - start)).clamp(0.0, 1.0));

  static Rect _bounds(double value, Rect trigger, Rect menu, double dismissal) {
    final progress = value.clamp(0.0, 1.0);
    final travel = menu.center - trigger.center;
    final arc = progress * (1 - progress);
    // The return stroke dips before the lens is pulled back to the trigger.
    final verticalLead =
        arc * ui.lerpDouble(2.3, 1.2 + 1.7 * progress, dismissal)!;
    final overshoot = value - progress;
    final center = Offset.lerp(trigger.center, menu.center, value)! +
        Offset(0, travel.dy * verticalLead);
    // The menu lens is absorbed by the returning trigger at the end of close.
    final absorption = 1 - dismissal * (1 - _ease(progress, 0, 0.15));
    return Rect.fromCenter(
      center: center,
      width: ui.lerpDouble(trigger.width, menu.width, value)! * absorption,
      height: ui.lerpDouble(
            trigger.height,
            menu.height,
            progress + overshoot * 0.65,
          )! *
          absorption,
    );
  }
}

/// Draws the narrow glass connection during the trigger's return handoff.
///
/// Place in the same stack as the menu surface. [origin] locates that stack
/// in the coordinate space used by [morph].
class GlassMenuMorphBridge extends StatelessWidget {
  /// Joins the returning menu lens to its trigger.
  const GlassMenuMorphBridge({
    required this.morph,
    required this.settings,
    this.origin = Offset.zero,
    super.key,
  });

  /// The current menu and trigger geometry.
  final GlassMenuMorph morph;

  /// The menu material, including the current blur ramp.
  final LiquidGlassSettings settings;

  /// The stack's origin in menu coordinates.
  final Offset origin;

  @override
  Widget build(BuildContext context) {
    final factor = morph.dismissal *
        morph._stage(0.05, 0.13) *
        (1 - morph._stage(0.21, 0.34));
    if (factor == 0 || morph.trigger.isEmpty || morph.bounds.isEmpty) {
      return const SizedBox.shrink();
    }

    final delta = morph.bounds.center - morph.trigger.center;
    final distance = delta.distance;
    if (distance == 0) return const SizedBox.shrink();

    final axis = delta / distance;
    final normal = Offset(-axis.dy, axis.dx);
    final triggerRadius = morph.trigger.shortestSide / 2;
    final bodyRadius = morph.bounds.shortestSide / 2;
    final start = morph.trigger.center + axis * (triggerRadius * 0.45);
    final end = morph.bounds.center - axis * (bodyRadius * 0.65);
    final length = (end - start).distance;
    final tip = normal * (triggerRadius * 0.48 * factor);
    final base = normal * (bodyRadius * 0.65 * factor);
    final first = axis * (length * 0.7);
    final last = axis * (length * 0.3);

    // The curved sides flare into the rounded lens. The lens owns the overlap
    // so the bridge and the body sample each pixel of the backdrop once.
    final path = Path()
      ..moveTo((start + tip).dx, (start + tip).dy)
      ..cubicTo(
        (start + tip + first).dx,
        (start + tip + first).dy,
        (end + base - last).dx,
        (end + base - last).dy,
        (end + base).dx,
        (end + base).dy,
      )
      ..lineTo((end - base).dx, (end - base).dy)
      ..cubicTo(
        (end - base - last).dx,
        (end - base - last).dy,
        (start - tip + first).dx,
        (start - tip + first).dy,
        (start - tip).dx,
        (start - tip).dy,
      )
      ..close();
    final exposed = Path.combine(
      PathOperation.difference,
      path,
      Path()
        ..addRRect(
          RRect.fromRectAndRadius(morph.bounds, Radius.circular(morph.radius)),
        ),
    );
    final region = exposed.getBounds();
    if (region.isEmpty) return const SizedBox.shrink();

    final tint = settings.effectiveGlassColor;
    return Positioned.fromRect(
      rect: region.shift(-origin),
      child: IgnorePointer(
        child: ClipPath(
          clipper: _GlassMenuBridgeClipper(exposed.shift(-region.topLeft)),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(
              sigmaX: settings.effectiveBlur,
              sigmaY: settings.effectiveBlur,
            ),
            child: ColoredBox(color: tint),
          ),
        ),
      ),
    );
  }
}

class _GlassMenuBridgeClipper extends CustomClipper<Path> {
  const _GlassMenuBridgeClipper(this.path);

  final Path path;

  @override
  Path getClip(Size size) => path;

  @override
  bool shouldReclip(_GlassMenuBridgeClipper oldClipper) =>
      path != oldClipper.path;
}

/// Lays the menu content out at its final size inside the moving glass lens.
///
/// Content sharpens as the lens settles. Impeller also refracts the content
/// near the moving perimeter.
class GlassMenuMorphContent extends StatefulWidget {
  /// Applies the foreground optics associated with [morph].
  const GlassMenuMorphContent({
    required this.morph,
    required this.child,
    super.key,
  });

  /// The geometry and optical state for this frame.
  final GlassMenuMorph morph;

  /// The content laid out in menu coordinates.
  final Widget child;

  static ui.FragmentProgram? _program;
  static Future<void>? _preload;
  static final ui.ImageFilter _identity = ui.ImageFilter.blur();

  /// Loads the foreground refraction program on shader-filter renderers.
  static Future<void> preload() {
    if (!ui.ImageFilter.isShaderFilterSupported) return Future.value();
    return _preload ??= _loadProgram();
  }

  static Future<void> _loadProgram() async {
    const asset = 'shaders/glass_menu_content.frag';
    try {
      _program = await ui.FragmentProgram.fromAsset(
        'packages/liquid_glass_widgets/$asset',
      );
    } on Exception {
      try {
        _program = await ui.FragmentProgram.fromAsset(asset);
      } on Exception {
        // Gaussian blur remains available while shader assets are unavailable.
      }
    }
  }

  @override
  State<GlassMenuMorphContent> createState() => _GlassMenuMorphContentState();
}

class _GlassMenuMorphContentState extends State<GlassMenuMorphContent> {
  ui.FragmentShader? _shader;

  @override
  void initState() {
    super.initState();
    if (ui.ImageFilter.isShaderFilterSupported &&
        GlassMenuMorphContent._program == null) {
      GlassMenuMorphContent.preload().then((_) {
        if (mounted && GlassMenuMorphContent._program != null) {
          setState(() {});
        }
      });
    }
  }

  @override
  void dispose() {
    _shader?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final morph = widget.morph;
    final shader = morph._refraction > 0 && morph.bounds.shortestSide >= 1
        ? _shader ??= GlassMenuMorphContent._program?.fragmentShader()
        : null;
    if (shader != null) {
      shader
        ..setFloat(2, morph.radius / morph.bounds.shortestSide)
        ..setFloat(3, morph._refraction);
    }
    return ClipRect(
      child: ImageFiltered(
        enabled: shader != null,
        imageFilter: shader == null
            ? GlassMenuMorphContent._identity
            : ui.ImageFilter.shader(shader),
        child: ClipRect(
          child: GlassMaterializeScope(
            glassProgress: 1,
            contentOpacity: morph._contentOpacity,
            contentSigma: morph._contentSigma,
            child: Builder(
              builder: (context) => GlassMaterializeScope.wrapContent(
                context,
                OverflowBox(
                  minWidth: morph.menuSize.width,
                  maxWidth: morph.menuSize.width,
                  minHeight: morph.menuSize.height,
                  maxHeight: morph.menuSize.height,
                  child: widget.child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
