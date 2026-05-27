import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Time Phase Enum & Logic
// ─────────────────────────────────────────────────────────────────────────────

enum TimePhase {
  midnight,   // 00:00 – 04:59
  dawn,       // 05:00 – 05:59
  sunrise,    // 06:00 – 06:59
  morning,    // 07:00 – 11:29
  noon,       // 11:30 – 13:29
  afternoon,  // 13:30 – 16:59
  dusk,       // 17:00 – 18:29
  evening,    // 18:30 – 19:59
  night,      // 20:00 – 23:59
}

TimePhase _getPhase(int hour, int minute) {
  final totalMinutes = hour * 60 + minute;
  if (totalMinutes < 300)  return TimePhase.midnight;
  if (totalMinutes < 360)  return TimePhase.dawn;
  if (totalMinutes < 420)  return TimePhase.sunrise;
  if (totalMinutes < 690)  return TimePhase.morning;
  if (totalMinutes < 810)  return TimePhase.noon;
  if (totalMinutes < 1020) return TimePhase.afternoon;
  if (totalMinutes < 1110) return TimePhase.dusk;
  if (totalMinutes < 1200) return TimePhase.evening;
  return TimePhase.night;
}

// ─────────────────────────────────────────────────────────────────────────────
// Sky Gradient Palettes
// ─────────────────────────────────────────────────────────────────────────────

const _skyColors = {
  TimePhase.midnight: [Color(0xFF020309), Color(0xFF03071A), Color(0xFF0D1B3E)],
  TimePhase.dawn:     [Color(0xFF0D1547), Color(0xFF2A265F), Color(0xFF8B3A62), Color(0xFFD4614D)],
  TimePhase.sunrise:  [Color(0xFF1A1060), Color(0xFFB03A5B), Color(0xFFE87A4E), Color(0xFFFAB86E)],
  TimePhase.morning:  [Color(0xFF3A8EE6), Color(0xFF6EB6F7), Color(0xFFB8D9F8)],
  TimePhase.noon:     [Color(0xFF1A75D2), Color(0xFF3A9EF5), Color(0xFF8ACAFF)],
  TimePhase.afternoon:[Color(0xFF1B6EC9), Color(0xFF59ADE8), Color(0xFFADD8F7)],
  TimePhase.dusk:     [Color(0xFF1A1A5E), Color(0xFF7C3462), Color(0xFFD4614D), Color(0xFFF5A05A), Color(0xFFFDD08A)],
  TimePhase.evening:  [Color(0xFF0A0A40), Color(0xFF1E1E6E), Color(0xFF5C2D5E), Color(0xFF8C3A47)],
  TimePhase.night:    [Color(0xFF02040E), Color(0xFF060B20), Color(0xFF0E1535)],
};

// How opaque the dark scrim overlay is per phase — keeps text readable
// 0.0 = no overlay, 1.0 = full black
const _scrimOpacity = {
  TimePhase.midnight:  0.35,
  TimePhase.dawn:      0.25,
  TimePhase.sunrise:   0.20,
  TimePhase.morning:   0.18,
  TimePhase.noon:      0.15,
  TimePhase.afternoon: 0.18,
  TimePhase.dusk:      0.22,
  TimePhase.evening:   0.30,
  TimePhase.night:     0.38,
};

// ─────────────────────────────────────────────────────────────────────────────
// Orb Config
// ─────────────────────────────────────────────────────────────────────────────

class _OrbConfig {
  final bool showSun;
  final double yFrac;       // vertical position 0.0 (top) → 1.0 (bottom)
  final Color innerColor;
  final Color outerGlow;
  final double glowRadius;  // large atmospheric halo
  final double midGlowRadius; // medium glow ring
  final double orbRadius;   // solid disc

  const _OrbConfig({
    required this.showSun,
    required this.yFrac,
    required this.innerColor,
    required this.outerGlow,
    required this.glowRadius,
    required this.midGlowRadius,
    required this.orbRadius,
  });
}

_OrbConfig _getOrbConfig(TimePhase phase, double hourFrac) {
  switch (phase) {
    case TimePhase.midnight:
      return _OrbConfig(showSun: false, yFrac: 0.30 + hourFrac * 0.15,
        innerColor: const Color(0xFFEEEEDD), outerGlow: const Color(0xFFB8C8FF),
        glowRadius: 160, midGlowRadius: 90, orbRadius: 14);
    case TimePhase.dawn:
      return _OrbConfig(showSun: true, yFrac: 0.82 - hourFrac * 0.10,
        innerColor: const Color(0xFFFFDDAA), outerGlow: const Color(0xFFFF8844),
        glowRadius: 320, midGlowRadius: 160, orbRadius: 18);
    case TimePhase.sunrise:
      return _OrbConfig(showSun: true, yFrac: 0.72 - hourFrac * 0.18,
        innerColor: const Color(0xFFFFEE88), outerGlow: const Color(0xFFFFAA33),
        glowRadius: 370, midGlowRadius: 190, orbRadius: 20);
    case TimePhase.morning:
      return _OrbConfig(showSun: true, yFrac: 0.54 - hourFrac * 0.44,
        innerColor: const Color(0xFFFFF8CC), outerGlow: const Color(0xFFFFDD55),
        glowRadius: 400, midGlowRadius: 210, orbRadius: 22);
    case TimePhase.noon:
      return _OrbConfig(showSun: true, yFrac: 0.10 + hourFrac * 0.06,
        innerColor: const Color(0xFFFFFFFF), outerGlow: const Color(0xFFFFEE88),
        glowRadius: 440, midGlowRadius: 230, orbRadius: 24);
    case TimePhase.afternoon:
      return _OrbConfig(showSun: true, yFrac: 0.16 + hourFrac * 0.38,
        innerColor: const Color(0xFFFFFBCC), outerGlow: const Color(0xFFFFCC44),
        glowRadius: 400, midGlowRadius: 210, orbRadius: 22);
    case TimePhase.dusk:
      return _OrbConfig(showSun: true, yFrac: 0.54 + hourFrac * 0.30,
        innerColor: const Color(0xFFFFBB66), outerGlow: const Color(0xFFFF6633),
        glowRadius: 360, midGlowRadius: 180, orbRadius: 20);
    case TimePhase.evening:
      return _OrbConfig(showSun: false, yFrac: 0.72 - hourFrac * 0.20,
        innerColor: const Color(0xFFDDDDCC), outerGlow: const Color(0xFF8899CC),
        glowRadius: 140, midGlowRadius: 80, orbRadius: 13);
    case TimePhase.night:
      return _OrbConfig(showSun: false, yFrac: 0.52 - hourFrac * 0.45,
        innerColor: const Color(0xFFEEEEDD), outerGlow: const Color(0xFFAABBDD),
        glowRadius: 160, midGlowRadius: 90, orbRadius: 14);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stars
// ─────────────────────────────────────────────────────────────────────────────

class _Star {
  final double x, y, r, opacity;
  const _Star(this.x, this.y, this.r, this.opacity);
}

List<_Star> _buildStars() {
  final rng = math.Random(42);
  return List.generate(60, (_) => _Star(
    rng.nextDouble(),
    rng.nextDouble() * 0.65,
    rng.nextDouble() * 1.4 + 0.4,
    rng.nextDouble() * 0.7 + 0.3,
  ));
}

final _stars = _buildStars();

// ─────────────────────────────────────────────────────────────────────────────
// SkyBackground Widget
// ─────────────────────────────────────────────────────────────────────────────

class SkyBackground extends StatefulWidget {
  final Widget child;
  const SkyBackground({super.key, required this.child});

  @override
  State<SkyBackground> createState() => _SkyBackgroundState();
}

class _SkyBackgroundState extends State<SkyBackground>
    with SingleTickerProviderStateMixin {
  late Timer _minuteTimer;
  late AnimationController _twinkleController;
  late DateTime _now;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();

    _minuteTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });

    _twinkleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _minuteTimer.cancel();
    _twinkleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final phase = _getPhase(_now.hour, _now.minute);

    final totalMinutes = _now.hour * 60 + _now.minute;
    final double hourFrac = switch (phase) {
      TimePhase.midnight  => totalMinutes / 300.0,
      TimePhase.dawn      => (totalMinutes - 300) / 60.0,
      TimePhase.sunrise   => (totalMinutes - 360) / 60.0,
      TimePhase.morning   => (totalMinutes - 420) / 270.0,
      TimePhase.noon      => (totalMinutes - 690) / 120.0,
      TimePhase.afternoon => (totalMinutes - 810) / 210.0,
      TimePhase.dusk      => (totalMinutes - 1020) / 90.0,
      TimePhase.evening   => (totalMinutes - 1110) / 90.0,
      TimePhase.night     => (totalMinutes - 1200) / 240.0,
    };
    final frac = hourFrac.clamp(0.0, 1.0);

    final colors = _skyColors[phase]!;
    final orbCfg = _getOrbConfig(phase, frac);
    final scrimAlpha = _scrimOpacity[phase]!;
    final showStars = phase == TimePhase.midnight ||
        phase == TimePhase.dawn ||
        phase == TimePhase.night ||
        phase == TimePhase.evening;

    return Stack(
      children: [
        // ── Sky gradient + orb ────────────────────────────────────────────
        Positioned.fill(
          child: AnimatedSwitcher(
            duration: const Duration(seconds: 4),
            child: CustomPaint(
              key: ValueKey(phase),
              painter: _SkyPainter(
                colors: colors,
                orbConfig: orbCfg,
                showStars: showStars,
                twinkleValue: _twinkleController,
              ),
              child: const SizedBox.expand(),
            ),
          ),
        ),

        // ── Readability scrim: top-heavy dark gradient overlay ────────────
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: scrimAlpha),
                    Colors.black.withValues(alpha: scrimAlpha * 0.6),
                    Colors.black.withValues(alpha: scrimAlpha * 0.3),
                    Colors.black.withValues(alpha: scrimAlpha * 0.15),
                  ],
                  stops: const [0.0, 0.25, 0.55, 1.0],
                ),
              ),
            ),
          ),
        ),

        // ── Foreground content ────────────────────────────────────────────
        widget.child,
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CustomPainter
// ─────────────────────────────────────────────────────────────────────────────

class _SkyPainter extends CustomPainter {
  final List<Color> colors;
  final _OrbConfig orbConfig;
  final bool showStars;
  final Animation<double> twinkleValue;

  _SkyPainter({
    required this.colors,
    required this.orbConfig,
    required this.showStars,
    required this.twinkleValue,
  }) : super(repaint: twinkleValue);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // ── Sky gradient ─────────────────────────────────────────────────────
    final stops = List.generate(
      colors.length,
      (i) => i / (colors.length - 1).toDouble(),
    );
    final skyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: colors,
        stops: stops,
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), skyPaint);

    // ── Stars ─────────────────────────────────────────────────────────────
    if (showStars) {
      final twinkle = twinkleValue.value;
      for (final star in _stars) {
        final opacity = (star.opacity * (0.6 + 0.4 * twinkle)).clamp(0.0, 1.0);
        canvas.drawCircle(
          Offset(star.x * w, star.y * h),
          star.r,
          Paint()..color = Colors.white.withValues(alpha: opacity),
        );
      }
    }

    // ── Orb position ─────────────────────────────────────────────────────
    final double xFrac = orbConfig.showSun
        ? 0.15 + (1.0 - orbConfig.yFrac) * 0.70
        : 0.80 - (1.0 - orbConfig.yFrac) * 0.60;

    final orbCenter = Offset(xFrac * w, orbConfig.yFrac * h);
    final orbR = orbConfig.orbRadius;
    final midR = orbConfig.midGlowRadius;
    final glowR = orbConfig.glowRadius;

    // ── Layer 1: Outermost atmospheric halo ──────────────────────────────
    canvas.drawCircle(
      orbCenter,
      glowR,
      Paint()
        ..shader = RadialGradient(
          colors: [
            orbConfig.outerGlow.withValues(alpha: 0.55),
            orbConfig.outerGlow.withValues(alpha: 0.20),
            orbConfig.outerGlow.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(Rect.fromCircle(center: orbCenter, radius: glowR)),
    );

    // ── Layer 2: Mid glow ring ─────────────────────────────────────────────
    canvas.drawCircle(
      orbCenter,
      midR,
      Paint()
        ..shader = RadialGradient(
          colors: [
            orbConfig.outerGlow.withValues(alpha: 0.80),
            orbConfig.outerGlow.withValues(alpha: 0.35),
            orbConfig.outerGlow.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(Rect.fromCircle(center: orbCenter, radius: midR)),
    );

    // ── Layer 3: Inner corona ─────────────────────────────────────────────
    canvas.drawCircle(
      orbCenter,
      orbR * 1.8,
      Paint()
        ..shader = RadialGradient(
          colors: [
            orbConfig.innerColor.withValues(alpha: 0.75),
            orbConfig.outerGlow.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromCircle(center: orbCenter, radius: orbR * 1.8)),
    );

    // ── Layer 4: Sun / Moon disc ──────────────────────────────────────────
    if (!orbConfig.showSun) {
      canvas.saveLayer(Rect.fromCircle(center: orbCenter, radius: orbR), Paint());
    }

    canvas.drawCircle(
      orbCenter,
      orbR,
      Paint()
        ..shader = RadialGradient(
          colors: [
            orbConfig.innerColor,
            orbConfig.outerGlow.withValues(alpha: 0.90),
          ],
          stops: const [0.55, 1.0],
        ).createShader(Rect.fromCircle(center: orbCenter, radius: orbR)),
    );

    // ── Moon crescent shadow ──────────────────────────────────────────────
    if (!orbConfig.showSun) {
      canvas.drawCircle(
        orbCenter.translate(orbR * 0.40, 0),
        orbR * 0.85,
        Paint()
          ..blendMode = BlendMode.dstOut
          ..color = Colors.black,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_SkyPainter old) =>
      old.colors != colors ||
      old.orbConfig.yFrac != orbConfig.yFrac ||
      old.showStars != showStars;
}
