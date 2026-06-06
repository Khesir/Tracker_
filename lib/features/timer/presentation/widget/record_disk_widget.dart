import 'dart:math' as math;
import 'package:flutter/material.dart';

const _kAccentGreen = Color(0xFF16C172);

class RecordDiskWidget extends StatefulWidget {
  final bool isSpinning;
  final String? albumArtUrl;
  final double size;

  const RecordDiskWidget({
    super.key,
    required this.isSpinning,
    this.albumArtUrl,
    this.size = 90,
  });

  @override
  State<RecordDiskWidget> createState() => _RecordDiskWidgetState();
}

class _RecordDiskWidgetState extends State<RecordDiskWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin;

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    if (widget.isSpinning) _spin.repeat();
  }

  @override
  void didUpdateWidget(RecordDiskWidget old) {
    super.didUpdateWidget(old);
    if (widget.isSpinning && !old.isSpinning) {
      _spin.repeat();
    } else if (!widget.isSpinning && old.isSpinning) {
      _spin.stop();
    }
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _spin,
      builder: (_, __) => Transform.rotate(
        angle: _spin.value * 2 * math.pi,
        child: _DiskFace(
          albumArtUrl: widget.albumArtUrl,
          size: widget.size,
        ),
      ),
    );
  }
}

class _DiskFace extends StatelessWidget {
  final String? albumArtUrl;
  final double size;

  const _DiskFace({this.albumArtUrl, required this.size});

  @override
  Widget build(BuildContext context) {
    final labelSize = size * 0.30;

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: const _VinylPainter(),
        child: Center(
          child: Container(
            width: labelSize,
            height: labelSize,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                center: Alignment(-0.3, -0.4),
                radius: 1.0,
                colors: [Color(0xFFAAF0D3), _kAccentGreen, Color(0xFF0E7A47)],
                stops: [0.0, 0.52, 1.0],
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: albumArtUrl != null
                ? Image.network(
                    albumArtUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const _DefaultLabel(),
                  )
                : const _DefaultLabel(),
          ),
        ),
      ),
    );
  }
}

class _DefaultLabel extends StatelessWidget {
  const _DefaultLabel();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 5,
        height: 5,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const RadialGradient(
            colors: [Colors.white, Color(0xFFCFD2D8)],
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 0, spreadRadius: 1),
          ],
        ),
      ),
    );
  }
}

class _VinylPainter extends CustomPainter {
  const _VinylPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxR = size.width / 2;

    // Base disc: dark radial gradient
    final basePaint = Paint()
      ..shader = RadialGradient(
        colors: [const Color(0xFF1A1D26), const Color(0xFF0B0B0F), const Color(0xFF050507)],
        stops: const [0.0, 0.46, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: maxR));
    canvas.drawCircle(center, maxR, basePaint);

    // Groove rings
    final groovePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    final step = size.width * 0.027;
    for (double r = size.width * 0.22; r < maxR - 2; r += step) {
      canvas.drawCircle(center, r, groovePaint);
    }

    // Gloss highlight
    final glossPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment(-0.7, -0.7),
        end: Alignment(0.7, 0.7),
        colors: [Color(0x38FFFFFF), Colors.transparent, Colors.transparent, Color(0x1FFFFFFF)],
        stops: [0.0, 0.4, 0.6, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: maxR))
      ..blendMode = BlendMode.screen;
    canvas.drawCircle(center, maxR, glossPaint);
  }

  @override
  bool shouldRepaint(_VinylPainter old) => false;
}
